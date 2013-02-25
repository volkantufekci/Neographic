require "redis"
require_relative 'configuration'

module RedisModul
  class RedisForGidsAndProperties

    def initialize()
      #dic={:host => 'localhost', :port => 6379},
      @redis = Redis.new({:host => Configuration::REDIS_URL, :port => 6379})
      #path = "/tmp/redis.sock" << redis_id
      #@redis = Redis.new(:path => path)
      @log = Logger.new(STDOUT)
      @log.level = Configuration::LOG_LEVEL
    end

    def put_partition_mapping_to_redis(gid_partition_h)
      @log.info("#{self.class.to_s}##{__method__.to_s} started")

      @redis.flushall
      @log.info("redis flushed")

      i = 1
      temp_h = {}

      gid_partition_h.each { |gid, partition|
        temp_h[gid] = partition
        if i % 100000 == 0 || i == gid_partition_h.size
          @redis.pipelined do
            temp_h.each { |k, v|
              key = "gid:" << k.to_s
              @redis.set(key, v)
            }
          end

          temp_h.clear
        end
        i += 1
      }
    end

  end
end

