require "benchmark"
require "redis"
require_relative 'configuration'

module RedisModul

  class RedisConnector

    def initialize(dic={:host => 'localhost', :port => 6379})
      #@redis = Redis.new(dic)
      @redis = Redis.new(:path => "/tmp/redis.sock")
      @log = Logger.new(STDOUT)
      @log.level = Configuration::LOG_LEVEL
    end

    def add_to_partition_list_for_node(gid, port)
      create_partition_list_for_node(gid, port)
    end

    def create_partition_list_for_node(gid, port)
      result = @redis.lpush gid, port
      @log.debug("Redis add_to_partition_list_for_node(#{gid}, #{port}) returns: #{result}. VT")
      result
    end

    def create_node(gid_fieldvalue_h)
      @redis.pipelined do
        gid_fieldvalue_h.each { |k, v|
          key = "node:" << k.to_s
          @redis.hmset(key, v)
        }
      end
    end

    def create_relation(rel_id, field_value_a)
      #key = "rel:#{rel_id}"
      key = "rel:" << rel_id.to_s
      result = @redis.hmset(key, field_value_a)
      #@log.debug("Redis create_relation for key=#{key} with params=#{field_value_a}")
      #result
    end

    def add_to_out_relations_of_node(gid, field_value_a)
      key    = "out:" << gid
      result = add_to_nodes_relations(key, field_value_a)
    end

    def add_to_in_relations_of_node(gid, field_value_a)
      key    = "in:" << gid
      result = add_to_nodes_relations(key, field_value_a)
    end

    # @param [String] key (out|in):node_id
    # @param [String] rel_id
    def add_to_nodes_relations(key, field_value_a)
      @redis.hmset(key, field_value_a)
      #result = @redis.rpush key, rel_id
    end

    # Returns node_nei_hash in the format of "gid=>[nei1_gid, nei2_gid, ...]"
    # @see PartitionController#collect_node_nei_hashes
    def fetch_relations
      @log.info("#{self.class.to_s}##{__method__.to_s} started")
      node_nei_h = {}
      max_relation_count = 999999
      lower_bound, upper_bound = 0, 9999
      interval = 10000
      while lower_bound <= max_relation_count
        futures = {}
        @redis.pipelined do
          lower_bound.upto(upper_bound) do |i|
            break if i > max_relation_count
            futures["out:#{i}"] = @redis.hvals("out:#{i}")
            futures["in:#{i}"]  = @redis.hvals("in:#{i}")
          end
        end

        lower_bound.upto(upper_bound) do |i|
          break if i > max_relation_count
          node_nei_h[i] = (futures["out:#{i}"].value + futures["in:#{i}"].value).uniq
        end

        lower_bound += interval
        upper_bound += interval
      end
      #0.upto(999999) do |i|
      #  #duplicates are removed as there can be more than 1 rel to the same target node from the same source node
      #  nei_a         = @redis.hgetall("out:#{i}").values.uniq | @redis.hgetall("in:#{i}").values.uniq
      #  node_nei_h[i] = nei_a unless nei_a.empty?
      #end

      node_nei_h
    end

    def bench(descr)
      start = Time.now
      yield
      puts "#{descr} #{Time.now-start} seconds"
    end

    def without_pipelining
      node_nei_h = {}
      0.upto(9999) do |i|
        nei_a         = @redis.hvals("out:#{i}")
        node_nei_h[i] = nei_a
      end
      0.upto(10) do |i|
        puts node_nei_h[i]
      end
    end

    def with_pipelining
      node_nei_h = {}
      @redis.pipelined do
        0.upto(9999) do |i|
          nei_a         = @redis.hvals("out:#{i}")
          node_nei_h[i] = nei_a
        end
      end
      0.upto(10) do |i|
        puts node_nei_h[i].value
      end
    end

    def read_nodes_csv
      i = 0
      gid_fieldvalue_h = {}
      lines = IO.readlines(Configuration::NODES_CSV)
      lines.delete_at(0) #first row is column headers
      lines.each { |line|
        i += 1
        if i % 10000 == 0
          create_node(gid_fieldvalue_h)
          gid_fieldvalue_h.clear
        end

        tokens = line.chomp.split("\t")

        gid = tokens[0]
        field_value_a = %W[rels #{tokens[1]} property #{tokens[2]} counter #{tokens[3]}]
        gid_fieldvalue_h[gid] = field_value_a
      }

      create_node(gid_fieldvalue_h)
    end

    def read_rels_csv

      lines = IO.readlines(Configuration::RELS_CSV)
      lines.delete_at(0) #first row is column headers

      process_lines_for_rels(lines)

    end

    def process_lines_for_rels(lines)
      i = 0
      lines.each { |line|
        i += 1
        @log.info "#{i}. relation created" if i%100000 == 0

        tokens        = line.chomp.split("\t")
        start_gid     = tokens[0]
        end_gid       = tokens[1]
        counter       = tokens[4]
        field_value_a = %W[ende #{end_gid} type #{tokens[2]} property #{tokens[3]} counter #{counter}]

        # burdaki i yerine redis'ten id ureten mekanizmaya gecilmeli
        rel_id        = counter
        create_relation(rel_id, field_value_a)
        field_value_a = %W[#{rel_id} #{end_gid}]
        add_to_out_relations_of_node(start_gid, field_value_a)

        field_value_a = %W[#{rel_id} #{start_gid}]
        add_to_in_relations_of_node(end_gid, field_value_a)
      }
    end

    def fill
      puts "Started at: #{Time.now}"
      remove_all
      read_nodes_csv
      #rc.read_rels_csv
      ##rc.fetch_relations
      puts "Finished at: #{Time.now}"
    end

    def update_partition_list_for_node(gid, new_partition_port)
      remove_partition_holding_real(gid)
      add_to_partition_list_for_node(gid, new_partition_port)
    end

    def remove_partition_holding_real(gid)
      result = @redis.lpop gid
      @log.debug("Redis remove_partition_holding_real for gid: #{gid} returns #{result}. VT")
      result
    end

    def new_global_id
      result = @redis.incr :global_neo4j_id
      @log.debug("Redis created new gid: #{result}")
      result
    end

    def partitions_have_the_node(gid)
      result = @redis.lrange gid, "0", "-1"
      @log.debug("Redis partitions_have_the_node for gid:#{gid} is #{result}. VT")
      result
    end

    def real_partition_of_node(gid)
      result = @redis.lrange gid, "0", "0"
      @log.debug("Redis real_partition_of_node with gid:#{gid} is #{result.first}")
      result.first
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

  #rc=RedisConnector.new
  #rc.bench("without pipelining") {
  #  rc.without_pipelining
  #}
  #rc.bench("with pipelining") {
  #  rc.with_pipelining
  #}
end


#Benchmark.bm(7) do |x|
#  x.report("log") { @log.info "#{i}. relation created" if i%100000 == 0 }
#
#  x.report("tokenize") {tokens = line.chomp.split("\t")}
#
#  tokens = line.chomp.split("\t")
#  start_gid     = tokens[0]
#  end_gid       = tokens[1]
#  x.report("w") {field_value_a = %W[ende #{end_gid} type #{tokens[2]} property #{tokens[3]} counter #{tokens[4]}]}
#
#  field_value_a = %W[ende #{end_gid} type #{tokens[2]} property #{tokens[3]} counter #{tokens[4]}]
#
#  # burdaki i yerine redis'ten id ureten mekanizmaya gecilmeli
#  rel_id        = i
#  x.report("create_rel") {create_relation(rel_id, field_value_a)}
#  x.report("add_to_out") {add_to_out_relations_of_node(start_gid, rel_id)}
#  x.report("add_to_in") {add_to_in_relations_of_node(end_gid, rel_id)}
#end

#Threading
#lines1 = lines.pop(1000000)
##lines2 = lines.pop(300000)
#all_lines = [] << lines << lines1
#all_lines.each { |sub_lines|
#  Thread.new do
#    process_lines_for_rels sub_lines
#  end
#}
#
#Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }

