require 'active_support/core_ext/hash'

module ActiveJob
  # Raised when an exception is raised during job arguments deserialization.
  #
  # Wraps the original exception raised as +cause+.
  class DeserializationError < StandardError
    def initialize #:nodoc:
      super("Error while trying to deserialize arguments: #{$ERROR_INFO.message}")
      set_backtrace $ERROR_INFO.backtrace
    end
  end

  # Raised when an unsupported argument type is set as a job argument. We
  # currently support NilClass, Integer, Fixnum, Float, String, TrueClass, FalseClass,
  # Bignum, BigDecimal, and objects that can be represented as GlobalIDs (ex: Active Record).
  # Raised if you set the key for a Hash something else than a string or
  # a symbol. Also raised when trying to serialize an object which can't be
  # identified with a Global ID - such as an unpersisted Active Record model.
  class SerializationError < ArgumentError; end

  module Arguments
    extend self
    # :nodoc:
    TYPE_WHITELIST = [NilClass, String, Integer, Float, BigDecimal, TrueClass, FalseClass].freeze
    TYPE_WHITELIST.push(Integer, Integer) unless 1.class == Integer

    # Serializes a set of arguments. Whitelisted types are returned
    # as-is. Arrays/Hashes are serialized element by element.
    # All other types are serialized using GlobalID.
    def serialize(arguments)
      arguments.map { |argument| serialize_argument(argument) }
    end

    # Deserializes a set of arguments. Whitelisted types are returned
    # as-is. Arrays/Hashes are deserialized element by element.
    # All other types are deserialized using GlobalID.
    def deserialize(arguments)
      arguments.map { |argument| deserialize_argument(argument) }
    rescue StandardError
      raise DeserializationError
    end

    private

    # :nodoc:
    GLOBALID_KEY = '_aj_globalid'.freeze
    # :nodoc:
    SYMBOL_KEYS_KEY = '_aj_symbol_keys'.freeze
    # :nodoc:
    WITH_INDIFFERENT_ACCESS_KEY = '_aj_hash_with_indifferent_access'.freeze
    private_constant :GLOBALID_KEY, :SYMBOL_KEYS_KEY, :WITH_INDIFFERENT_ACCESS_KEY

    def serialize_argument(argument)
      case argument
      when GlobalID::Identification
        convert_to_global_id_hash(argument)
      when Array
        argument.map { |arg| serialize_argument(arg) }
      when ActiveSupport::HashWithIndifferentAccess
        serialize_indifferent_hash(argument)
      when Hash
        symbol_keys = argument.each_key.grep(Symbol).map(&:to_s)
        result = serialize_hash(argument)
        result[SYMBOL_KEYS_KEY] = symbol_keys
        result
      when ->(arg) { arg.respond_to?(:permitted?) }
        serialize_indifferent_hash(argument.to_h)
      when *TYPE_WHITELIST
        argument
      else
        raise SerializationError, "Unsupported argument type: #{argument.class.name}"
      end
    end

    def deserialize_argument(argument)
      case argument
      when String
        argument
      when Array
        argument.map { |arg| deserialize_argument(arg) }
      when Hash
        if serialized_global_id?(argument)
          deserialize_global_id argument
        else
          deserialize_hash(argument)
        end
      when *TYPE_WHITELIST
        argument
      else
        raise ArgumentError, "Can only deserialize primitive arguments: #{argument.inspect}"
      end
    end

    def serialized_global_id?(hash)
      hash.size == 1 && hash.include?(GLOBALID_KEY)
    end

    def deserialize_global_id(hash)
      GlobalID::Locator.locate hash[GLOBALID_KEY]
    end

    def serialize_hash(argument)
      argument.each_with_object({}) do |(key, value), hash|
        hash[serialize_hash_key(key)] = serialize_argument(value)
      end
    end

    def deserialize_hash(serialized_hash)
      result = serialized_hash.transform_values { |v| deserialize_argument(v) }
      if result.delete(WITH_INDIFFERENT_ACCESS_KEY)
        result = result.with_indifferent_access
      elsif symbol_keys = result.delete(SYMBOL_KEYS_KEY)
        result = transform_symbol_keys(result, symbol_keys)
      end
      result
    end

    # :nodoc:
    RESERVED_KEYS = [
      GLOBALID_KEY, GLOBALID_KEY.to_sym,
      SYMBOL_KEYS_KEY, SYMBOL_KEYS_KEY.to_sym,
      WITH_INDIFFERENT_ACCESS_KEY, WITH_INDIFFERENT_ACCESS_KEY.to_sym
    ].freeze
    private_constant :RESERVED_KEYS

    def serialize_hash_key(key)
      case key
      when String, Symbol
        key.to_s
      when *RESERVED_KEYS
        raise SerializationError, "Can't serialize a Hash with reserved key #{key.inspect}"
      else
        raise SerializationError, "Only string and symbol hash keys may be serialized as job arguments, but #{key.inspect} is a #{key.class}"
      end
    end

    def serialize_indifferent_hash(indifferent_hash)
      result = serialize_hash(indifferent_hash)
      result[WITH_INDIFFERENT_ACCESS_KEY] = serialize_argument(true)
      result
    end

    def transform_symbol_keys(hash, symbol_keys)
      # NOTE: HashWithIndifferentAccess#transform_keys always
      # returns stringified keys with indifferent access
      # so we call #to_h here to ensure keys are symbolized.
      hash.to_h.transform_keys do |key|
        if symbol_keys.include?(key)
          key.to_sym
        else
          key
        end
      end
    end

    def convert_to_global_id_hash(argument)
      { GLOBALID_KEY => argument.to_global_id.to_s }
    rescue URI::GID::MissingModelIdError
      raise SerializationError, "Unable to serialize #{argument.class} " \
        'without an id. (Maybe you forgot to call save?)'
    end
  end
end
