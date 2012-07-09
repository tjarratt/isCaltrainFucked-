require 'redis'

class RedisCache
  def self.connect
    @redis ||= Redis.new
  end

  def self.get(key, &block)
    maybe_value = @redis.get(key)

    if maybe_value.nil?
      maybe_value = block.call
      @redis.set(key, maybe_value)
      @redis.expire(key, 60*60)
    end

    if maybe_value.is_a?(String)
      maybe_value = maybe_value == "true"
    end

    maybe_value
  end
end
