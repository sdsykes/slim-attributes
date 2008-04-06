class Mysql::Result

  class FakeResultHash
    include Enumerable
    
    def marshal_dump
      [@field_indexes, values]
    end
    
    def marshal_load(arr)
      @field_indexes, @row = arr
      @totally_fetched = true
    end

    def has_key?(name)
      @field_indexes[name]
    end

    alias_method :include?, :has_key?

    def keys
      @field_indexes.keys
    end

    def values
      fetch_all
      @row
    end

    def delete(name)
      index = @field_indexes[name]
      if index
        fetch_all
        @field_indexes.delete(name)
        @field_indexes.each {|k, v| @field_indexes[k] -= 1 if v > index}
        @row.delete_at(index)
      else
        nil
      end
    end
    
    def to_hash
      fetch_all
      @real_hash ||= @field_indexes.inject({}) {|memo, fi| memo[fi[0]] = @row[fi[1]]; memo}
    end

    def update(ahash)
      fetch_all
      ahash.each do |k, v|
        index = @field_indexes[k]
        if index
          @row[index] = v
        else
          raise "Not a valid attribute name"
        end
      end
      self
    end
    
    alias_method :merge!, :update

    def each
      fetch_all
      @field_indexes.each {|f,i| yield(f, @row[i])}
    end
    
    private
    def fetch_all
      unless @totally_fetched
        @field_indexes.each_value {|v| fetch_by_index(v)}
        @totally_fetched = true
      end
    end
  end

end
