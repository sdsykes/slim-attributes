# Author: Stephen Sykes
# http://pennysmalls.com

require 'mysql'

class Mysql::Result; class RowHash; end; end

require 'slim_attrib_ext'

class Mysql::Result
  class RowHash
    attr_accessor :real_hash

    def marshal_dump
      to_hash
    end
    
    def marshal_load(hash)
      @real_hash = hash
    end

    alias_method :include?, :has_key?

    def keys
      @real_hash ? @real_hash.keys : @field_indexes.keys
    end

    # If you want to do anything other than [], []=, dup, keys and has_key? then 
    # we'll handle that by doing the operation on a real ruby hash.
    # This should be the exception though, and the efficiencies of using slim-attributes
    # are lost when this happens.
    def to_hash
      return @real_hash unless @field_indexes
      @real_hash ||= {}
      @field_indexes.each_pair {|name, index| @real_hash[name] = fetch_by_index(index)}
      @field_indexes = nil
      @real_hash
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
