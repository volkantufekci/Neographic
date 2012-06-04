require "redis"

module RedisModul

  class RedisConnector

    def initialize(dic={:host => 'localhost', :port => 6379})
      @redis = Redis.new(dic)
      @log = Logger.new(STDOUT)
    end

    def add_to_partition_list_for_node(gid, port)
      create_partition_list_for_node(gid, port)
    end

    def create_partition_list_for_node(gid, port)
      result = @redis.lpush gid, port
      @log.info("Redis add_to_partition_list_for_node(#{gid}, #{port}) returns: #{result}. VT")
      result
    end

    def update_partition_list_for_node(gid, new_partition_port)
      remove_partition_holding_real(gid)
      add_to_partition_list_for_node(gid, new_partition_port)
    end

    def remove_partition_holding_real(gid)
      result = @redis.lpop gid
      @log.info("Redis remove_partition_holding_real for gid: #{gid} returns #{result}. VT")
      result
    end

    def new_global_id
      result = @redis.incr :global_neo4j_id
      @log.info("Redis created new gid: #{result}")
      result
    end

    def partitions_have_the_node(gid)
      result = @redis.lrange gid, "0", "-1"
      @log.info("Redis partitions_have_the_node for gid: #{result}. VT")
      result
    end

    def reset_global_id
      result = @redis.set :global_neo4j_id, "0"
      @log.info("Redis reset global_neo4j_id. VT")
      result
    end

    def remove_all
      @redis.flushall
      @log.info("Redis is reset with FLUSHALL. VT")
    end

  end

end