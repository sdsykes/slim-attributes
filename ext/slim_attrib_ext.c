#include "ruby.h"
#include "st.h"

#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>

#define GetMysqlRes(obj) (Check_Type(obj, T_DATA), ((struct mysql_res*)DATA_PTR(obj))->res)
#define GetCharPtr(obj) (Check_Type(obj, T_DATA), (char*)DATA_PTR(obj))
#define GetCharStarPtr(obj) (Check_Type(obj, T_DATA), (char**)DATA_PTR(obj))

VALUE cRowHash, cClass;

// from mysql/ruby
struct mysql_res {
  MYSQL_RES* res;
  char freed;
};

// row info
#define SLIM_IS_NULL (char)0x01
#define SLIM_IS_SET (char)0x02

#define GET_COL_IV_NAME(str, col_number) sprintf(str, "@col_%d", col_number)

static VALUE all_hashes(VALUE obj) {
  MYSQL_RES *res = GetMysqlRes(obj);
  MYSQL_FIELD *fields = mysql_fetch_fields(res);
  MYSQL_ROW row;
  VALUE all_hashes_ary, col_names_hsh, frh;
  my_ulonglong nr = mysql_num_rows(res);
  unsigned int nf = mysql_num_fields(res);
  unsigned int i, j, s, len;
  unsigned long *lengths;
  char *row_info_space, **pointers_space, *p;

  /* hash of column names */
  col_names_hsh = rb_hash_new();
  for (i=0; i < nf; i++) {
    rb_hash_aset(col_names_hsh, rb_str_new2(fields[i].name), INT2FIX(i));
  }

  /* array of result rows */
  all_hashes_ary = rb_ary_new2(nr);
  for (i=0; i < nr; i++) {
    row = mysql_fetch_row(res);         // get the row
    lengths = mysql_fetch_lengths(res); // get lengths
    for (s=j=0; j < nf; j++) s += lengths[j];  // s = total of lengths
    pointers_space = malloc((nf + 1) * sizeof(char *) + s);  // storage for pointers to data followed by data
    p = *pointers_space = (char *)(pointers_space + nf + 1);  // pointer to first data item
    row_info_space = calloc(nf, 1);
    for (j=0; j < nf; j++) {
      len = (unsigned int)lengths[j];
      if (!row[j]) row_info_space[j] = SLIM_IS_NULL;
      else memcpy(p, row[j], len); // copy row data in
      pointers_space[j + 1] = p += len;
    }
    frh = rb_class_new_instance(0, NULL, cRowHash);
    rb_iv_set(frh, "@pointers", Data_Wrap_Struct(cClass, 0, free, pointers_space));
    rb_iv_set(frh, "@row_info", Data_Wrap_Struct(cClass, 0, free, row_info_space));
    rb_iv_set(frh, "@field_indexes", col_names_hsh);
    rb_ary_store(all_hashes_ary, i, frh);
  }
  return all_hashes_ary;
}

static VALUE fetch_by_index(VALUE obj, VALUE index) {
  VALUE contents;
  char *row_info, **pointers, *start, col_name[16];
  long col_number = FIX2LONG(index);
  unsigned int length;
  
  row_info = GetCharPtr(rb_iv_get(obj, "@row_info")) + col_number;
  if (*row_info == SLIM_IS_NULL) return Qnil;  // return nil if null from db
  GET_COL_IV_NAME(col_name, col_number);
  if (*row_info == SLIM_IS_SET) return rb_iv_get(obj, col_name);  // was set already, return array entry
  
  pointers = GetCharStarPtr(rb_iv_get(obj, "@pointers"));
  start = pointers[col_number];
  length = pointers[col_number + 1] - start;
  contents = rb_tainted_str_new(start, length);
  rb_iv_set(obj, col_name, contents);
  *row_info = SLIM_IS_SET;
  return contents;
}

static VALUE slim_fetch(VALUE obj, VALUE name) {
  VALUE real_hash, hash_lookup;
  real_hash = rb_iv_get(obj, "@real_hash");
  if (!NIL_P(real_hash)) return rb_hash_aref(real_hash, name);
  hash_lookup = rb_hash_aref(rb_iv_get(obj, "@field_indexes"), name);
  if (NIL_P(hash_lookup)) return Qnil;
  return fetch_by_index(obj, hash_lookup);
}

static VALUE set_element(VALUE obj, VALUE name, VALUE val) {
  VALUE real_hash, hash_lookup;
  long col_number;
  char col_name[16];

  real_hash = rb_iv_get(obj, "@real_hash");
  if (!NIL_P(real_hash)) return rb_hash_aset(real_hash, name, val);
  
  hash_lookup = rb_hash_aref(rb_iv_get(obj, "@field_indexes"), name);  
  if (NIL_P(hash_lookup)) return rb_funcall(rb_funcall(obj, rb_intern("to_hash"), 0), rb_intern("[]="), 2, name, val);
  col_number = FIX2LONG(hash_lookup);
  GET_COL_IV_NAME(col_name, col_number);
  rb_iv_set(obj, col_name, val);
  GetCharPtr(rb_iv_get(obj, "@row_info"))[col_number] = SLIM_IS_SET;
  return val;
}

static VALUE dup(VALUE obj) {
  VALUE real_hash, frh, field_indexes;
  int nf, i;
  char *row_info_space, col_name[16];
  
  real_hash = rb_iv_get(obj, "@real_hash");
  if (!NIL_P(real_hash)) return rb_obj_dup(real_hash);

  field_indexes = rb_iv_get(obj, "@field_indexes");
  nf = RHASH(field_indexes)->tbl->num_entries;
  row_info_space = malloc(nf);
  memcpy(row_info_space, GetCharPtr(rb_iv_get(obj, "@row_info")), nf);
  for (i=0; i < nf; i++) row_info_space[i] &= ~SLIM_IS_SET;  // remove any set flags
  frh = rb_class_new_instance(0, NULL, cRowHash);
  rb_iv_set(frh, "@pointers", rb_iv_get(obj, "@pointers"));
  rb_iv_set(frh, "@row_info", Data_Wrap_Struct(cClass, 0, free, row_info_space));
  rb_iv_set(frh, "@field_indexes", field_indexes);
  return frh;
}

void Init_slim_attrib_ext() {
  VALUE c = rb_cObject;
  c = rb_const_get_at(c, rb_intern("Mysql"));
  c = rb_const_get_at(c, rb_intern("Result"));
  rb_define_method(c, "all_hashes", (VALUE(*)(ANYARGS))all_hashes, 0);
  cRowHash = rb_const_get_at(c, rb_intern("RowHash"));
  cClass = rb_define_class("CObjects", cRowHash);
  rb_define_private_method(cRowHash, "fetch_by_index", (VALUE(*)(ANYARGS))fetch_by_index, 1);
  rb_define_method(cRowHash, "[]", (VALUE(*)(ANYARGS))slim_fetch, 1);
  rb_define_method(cRowHash, "[]=", (VALUE(*)(ANYARGS))set_element, 2);
  rb_define_method(cRowHash, "dup", (VALUE(*)(ANYARGS))dup, 0);
}
