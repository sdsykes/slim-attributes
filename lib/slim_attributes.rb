# Author: Stephen Sykes
# http://pennysmalls.com

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
