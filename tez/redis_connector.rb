require "redis"

module Tez

  class RedisConnector

    @redis = Redis.new

    def self.new_global_id
      @redis.incr :global_neo4j_id
    end

    def self.reset_global_id
      @redis.set :global_neo4j_id, "0"
    end

  end

end