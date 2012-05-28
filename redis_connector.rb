require "redis"

module RedisModul

  class RedisConnector

    @redis = Redis.new

    def self.new_global_id
      @redis.incr :global_neo4j_id
    end

    def self.reset_global_id
      @redis.set :global_neo4j_id, "0"
    end

    def self.partitions_have_the_node(node_global_id)
      @redis.lrange node_global_id, "0", "-1"
    end

    def self.create_partition_list_for_node(node_global_id, port)
      @redis.lpush node_global_id, port
    end

  end

end