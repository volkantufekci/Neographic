require "redis"

module RedisModul

  class RedisConnector

    def initialize(dic={:host => 'localhost', :port => 6379})
      @redis = Redis.new(dic)
      @log = Logger.new(STDOUT)
    end

    def add_to_partition_list_for_node(node_global_id, port)
      result = self.create_partition_list_for_node(node_global_id, port)
      log.info("add_to_partition_list_for_node( #{node_global_id}, #{port}) => #{result}")
    end

    def create_partition_list_for_node(node_global_id, port)
      @redis.lpush node_global_id, port
    end

    def new_global_id
      @redis.incr :global_neo4j_id
    end

    def partitions_have_the_node(node_global_id)
      @redis.lrange node_global_id, "0", "-1"
    end

    def reset_global_id
      @redis.set :global_neo4j_id, "0"
    end

    def remove_all
      @redis.flushall
      @log.info("Redis is reset with FLUSHALL. VT")
    end

  end

end