require 'redis-rb'

class RedisCache
  def self.connect
    @redis ||= Redis.new
  end

  def self.get(key, &block)
    maybe_value = @redis.get(key)
    maybe_value.nil? ? block.call : maybe_value
  end
end
