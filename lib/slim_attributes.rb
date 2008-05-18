require 'mysql'

class Mysql::Result
  class RowHash
    def marshal_dump
      to_hash
    end
    
    def marshal_load(hash)
      @real_hash = hash
    end

    def has_key?(name)
      @real_hash ? @real_hash.has_key?(name) : @field_indexes[name]
    end

    alias_method :include?, :has_key?

    def keys
      @real_hash ? @real_hash.keys : @field_indexes.keys
    end

    def to_hash
      @real_hash ||= @field_indexes.inject({}) {|memo, fi| memo[fi[0]] = fetch_by_index(fi[1]); memo}
    end

    def to_a
      to_hash.to_a
    end
    
    # Load up all the attributes before a freeze
    alias_method :regular_freeze, :freeze
    
    def freeze
      to_hash.freeze
      regular_freeze
    end
    
    def method_missing(name, *args, &block)
      to_hash.send(name, *args, &block)
    end
  end
end

require 'slim_attrib_ext'

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def select(sql, name = nil)
    fields, rows = select_raw(sql, name)
    result = []
    for row in rows
      row_hash = {}
      fields.each_with_index do |f, i|
        row_hash[f] = row[i]
      end
      result << row_hash
    end
    result
  end
  
  def select_raw(sql, name = nil)
    res = execute(sql, name)
    results = result_as_array(res)
    fields = []
    rows = []
    if res.ntuples > 0
      fields = res.fields
      results.each do |row|
        row.each_index do |cell_index|
          # If this is a money type column and there are any currency symbols,
          # then strip them off. Indeed it would be prettier to do this in
          # PostgreSQLColumn.string_to_decimal but would break form input
          # fields that call value_before_type_cast.
          if res.ftype(cell_index) == MONEY_COLUMN_TYPE_OID
            # Because money output is formatted according to the locale, there are two
            # cases to consider (note the decimal separators):
            #  (1) $12,345,678.12        
            #  (2) $12.345.678,12
            case column = row[cell_index]
            when /^-?\D+[\d,]+\.\d{2}$/  # (1)
              row[cell_index] = column.gsub(/[^-\d\.]/, '')
            when /^-?\D+[\d\.]+,\d{2}$/  # (2)
              row[cell_index] = column.gsub(/[^-\d,]/, '').sub(/,/, '.')
            end
          end
        end
        rows << row
      end
    end
    res.clear
    return fields, rows
  end
end
