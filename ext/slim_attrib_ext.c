// Author: Stephen Sykes
// http://pennysmalls.com

#include "ruby.h"
#include "st.h"

#include <mysql.h>
#include <errmsg.h>
#include <mysqld_error.h>

#define GetMysqlRes(obj) (Check_Type(obj, T_DATA), ((struct mysql_res*)DATA_PTR(obj))->res)
#define GetCharPtr(obj) (Check_Type(obj, T_DATA), (char*)DATA_PTR(obj))
#define GetCharStarPtr(obj) (Check_Type(obj, T_DATA), (char**)DATA_PTR(obj))

VALUE cRowHash, cClass;
ID pointers_id, row_info_id, field_indexes_id, real_hash_id, to_hash_id;

#define MAX_CACHED_COLUMN_IDS 40
ID column_ids[MAX_CACHED_COLUMN_IDS];

// from mysql/ruby
struct mysql_res {
  MYSQL_RES* res;
  char freed;
};

// row info
#define SLIM_IS_NULL (char)0x01
#define SLIM_IS_SET (char)0x02

#define GET_COL_IV_ID(str, cnum) (cnum < MAX_CACHED_COLUMN_IDS ? column_ids[cnum] : (sprintf(str, "@col_%d", cnum), rb_intern(str)))

#define REAL_HASH_EXISTS NIL_P(field_indexes = rb_ivar_get(obj, field_indexes_id))

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
  row_info_space = calloc(nf * nr, 1);  // allocate all the row info space we need here
  rb_ivar_set(all_hashes_ary, row_info_id, Data_Wrap_Struct(cClass, 0, free, row_info_space)); // just for GC

  for (i=0; i < nr; i++) {
    row = mysql_fetch_row(res);         // get the row
    lengths = mysql_fetch_lengths(res); // get lengths
    for (s=j=0; j < nf; j++) s += lengths[j];  // s = total of lengths
    pointers_space = malloc((nf + 1) * sizeof(char *) + s);  // data pointers, data
    p = *pointers_space = (char *)(pointers_space + nf + 1);  // pointer to first data item
    for (j=0; j < nf; j++) {
      len = (unsigned int)lengths[j];
      if (len) {
        memcpy(p, row[j], len); // copy row data in
        p += len;
      } else if (!row[j]) row_info_space[j] = SLIM_IS_NULL;
      pointers_space[j + 1] = p;
    }
    frh = rb_class_new_instance(0, NULL, cRowHash);
    rb_ivar_set(frh, pointers_id, Data_Wrap_Struct(cClass, 0, free, pointers_space));
    rb_ivar_set(frh, row_info_id, Data_Wrap_Struct(cClass, 0, 0, row_info_space));
    rb_ivar_set(frh, field_indexes_id, col_names_hsh);
    rb_ary_store(all_hashes_ary, i, frh);
    row_info_space += nf;
  }
  return all_hashes_ary;
}

static VALUE fetch_by_index(VALUE obj, VALUE index) {
  VALUE contents;
  char *row_info, **pointers, *start, col_name[16];
  ID col_id;
  long col_number = FIX2LONG(index);
  unsigned int length;
  
  row_info = GetCharPtr(rb_ivar_get(obj, row_info_id)) + col_number;
  if (*row_info == SLIM_IS_NULL) return Qnil;  // return nil if null from db
  col_id = GET_COL_IV_ID(col_name, col_number);
  if (*row_info == SLIM_IS_SET) return rb_ivar_get(obj, col_id);  // was set already, return it
  
  pointers = GetCharStarPtr(rb_ivar_get(obj, pointers_id));
  start = pointers[col_number];
  length = pointers[col_number + 1] - start;
  contents = rb_tainted_str_new(start, length);
  rb_ivar_set(obj, col_id, contents);
  *row_info = SLIM_IS_SET;
  return contents;
}

static VALUE slim_fetch(VALUE obj, VALUE name) {
  VALUE field_indexes, hash_lookup;
  
  if (REAL_HASH_EXISTS) return rb_hash_aref(rb_ivar_get(obj, real_hash_id), name);

  hash_lookup = rb_hash_aref(field_indexes, name);
  if (NIL_P(hash_lookup)) return Qnil;
  return fetch_by_index(obj, hash_lookup);
}

static VALUE set_element(VALUE obj, VALUE name, VALUE val) {
  VALUE field_indexes, hash_lookup;
  long col_number;
  char col_name[16];
  ID col_id;

  if (REAL_HASH_EXISTS) return rb_hash_aset(rb_ivar_get(obj, real_hash_id), name, val);
  
  hash_lookup = rb_hash_aref(field_indexes, name);  
  if (NIL_P(hash_lookup)) return rb_hash_aset(rb_funcall(obj, to_hash_id, 0), name, val);
  col_number = FIX2LONG(hash_lookup);
  col_id = GET_COL_IV_ID(col_name, col_number);
  rb_ivar_set(obj, col_id, val);
  GetCharPtr(rb_ivar_get(obj, row_info_id))[col_number] = SLIM_IS_SET;
  return val;
}

static VALUE dup(VALUE obj) {
  VALUE frh, field_indexes;
  int nf, i;
  char *row_info_space, col_name[16];
  
  if (REAL_HASH_EXISTS) return rb_obj_dup(rb_ivar_get(obj, real_hash_id));

  nf = RHASH(field_indexes)->tbl->num_entries;
  row_info_space = malloc(nf);
  memcpy(row_info_space, GetCharPtr(rb_ivar_get(obj, row_info_id)), nf);
  for (i=0; i < nf; i++) row_info_space[i] &= ~SLIM_IS_SET;  // remove any set flags
  frh = rb_class_new_instance(0, NULL, cRowHash);
  rb_ivar_set(frh, pointers_id, rb_ivar_get(obj, pointers_id));
  rb_ivar_set(frh, row_info_id, Data_Wrap_Struct(cClass, 0, free, row_info_space));
  rb_ivar_set(frh, field_indexes_id, field_indexes);
  return frh;
}

static VALUE has_key(VALUE obj, VALUE name) {
  VALUE field_indexes;

  if (REAL_HASH_EXISTS) return (st_lookup(RHASH(rb_ivar_get(obj, real_hash_id))->tbl, name, 0) ? Qtrue : Qfalse);
  else return (st_lookup(RHASH(field_indexes)->tbl, name, 0) ? Qtrue : Qfalse);
}

void Init_slim_attrib_ext() {
  int i;
  char col_name[16];
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
  rb_define_method(cRowHash, "has_key?", (VALUE(*)(ANYARGS))has_key, 1);  
  pointers_id = rb_intern("@pointers");
  row_info_id = rb_intern("@row_info");
  field_indexes_id = rb_intern("@field_indexes");
  real_hash_id = rb_intern("@real_hash");
  to_hash_id = rb_intern("to_hash");
  for(i=0; i < MAX_CACHED_COLUMN_IDS; i++) {
    sprintf(col_name, "@col_%d", i);
    column_ids[i] = rb_intern(col_name);
  }
}
