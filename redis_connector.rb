require "benchmark"
require "redis"
require_relative 'configuration'

module RedisModul

  class RedisConnector

    def initialize(redis_id="_0")
      #@redis = Redis.new(dic) #dic={:host => 'localhost', :port => 6379},
      path = "/tmp/redis.sock" << redis_id
      @redis = Redis.new(:path => path)
      @log = Logger.new(STDOUT)
      @log.level = Configuration::LOG_LEVEL
    end

    def create_node(gid_fieldvalue_h)
      @redis.pipelined do
        gid_fieldvalue_h.each { |k, v|
          key = "node:" << k.to_s
          @redis.hmset(key, v)
        }
      end
    end

    def create_relation(key_prefix, relid_fieldvalue_h)
      raise "not suitable key_prefix=#{key_prefix} passed" unless %w[rel: out: in:].include? key_prefix

      @redis.pipelined do
        relid_fieldvalue_h.each do |id, field_value_h|
          key = key_prefix + id.to_s
          @redis.hmset(key, field_value_h)
        end
      end
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
    def fetch_relations(max_node_count = 999999)
      @log.info("#{self.class.to_s}##{__method__.to_s} started")
      gid_relidnei_h = {}

      lower_bound, upper_bound = 1, 10000
      interval = 10000
      while lower_bound <= max_node_count
        futures = {}
        @redis.pipelined do
          lower_bound.upto(upper_bound) do |i|
            break if i > max_node_count
            futures["out:#{i}"] = @redis.hgetall("out:#{i}")
            futures["in:#{i}"]  = @redis.hgetall("in:#{i}")
          end
        end

        lower_bound.upto(upper_bound) do |i|
          break if i > max_node_count
          gid_relidnei_h[i] = futures["out:#{i}"].value.merge(futures["in:#{i}"].value)
        end

        lower_bound += interval
        upper_bound += interval
      end

      gid_relidnei_h
    end

    # @return [Hash<String, Array>] gid_props_h
    # in the format of "gid=>[propert, value, property, value...]"
    def fetch_values_for(key_prefix, gids)
      raise "not suitable key_prefix=#{key_prefix} passed" unless [:node, :rel, :out, :in].include? key_prefix
      gid_values_h = {}
      max_idx     = gids.length - 1
      lower_bound, upper_bound, interval = 0, 9999, 10000

      while lower_bound <= max_idx
        futures = {}
        @redis.pipelined do
          lower_bound.upto(upper_bound) do |i|
            break if i > max_idx
            gid = gids[i]
            futures[gid] = @redis.hgetall("#{key_prefix}:#{gid}")
          end
        end

        #fetch actual values from futures
        lower_bound.upto(upper_bound) do |i|
          break if i > max_idx
          gid = gids[i]
          gid_values_h[gid] = futures[gid].value
        end

        lower_bound += interval
        upper_bound += interval
      end

      gid_values_h
    end

    def read_nodes_csv
      @log.info("#{self.class.to_s}##{__method__.to_s} started")
      i = 0
      is_header_line = true
      gid_fieldvalue_h = {}
      File.open(Configuration::NODES_CSV, "r").each_line do |line|
        if is_header_line
          is_header_line = false
          next
        end
        i += 1
        if i % 10000 == 0
          create_node(gid_fieldvalue_h)
          gid_fieldvalue_h.clear
        end

        tokens = line.chomp.split("\t")

        gid = tokens[1]
        field_value_a = %W[__type__ #{tokens[0]} name #{tokens[2]}]
        gid_fieldvalue_h[gid] = field_value_a
      end

      create_node(gid_fieldvalue_h)
    end

    def read_rels_csv
      @log.info("#{self.class.to_s}##{__method__.to_s} started")

      relid_fieldvalue_h, out_gid_fieldvalue_h, in_gid_fieldvalue_h = {}, {}, {}
      i = 0
      is_header_line = true
      File.open(Configuration::RELS_CSV, "r").each_line do |line|
        if is_header_line
          is_header_line = false
          next
        end
        i += 1
        if i % 10000 == 0
          @log.info "#{i}. relation created" if i % 1000000 == 0
          create_relation("rel:", relid_fieldvalue_h)
          relid_fieldvalue_h.clear

          create_relation("out:", out_gid_fieldvalue_h)
          out_gid_fieldvalue_h.clear

          create_relation("in:", in_gid_fieldvalue_h)
          in_gid_fieldvalue_h.clear
        end

        tokens        = line.chomp.split("\t")
        start_gid     = tokens[0]
        end_gid       = tokens[1]
        type          = tokens[2]
        #visited       = tokens[3]
        visited       = 0
        #counter       = tokens[4]
        #rel_id        = counter
        rel_id        = tokens[3]
        #field_value_a = %W[Start #{start_gid} Ende #{end_gid} Type #{type} Visited:int #{visited} Counter:long #{counter}]
        field_value_a = %W[Start #{start_gid} Ende #{end_gid} Type #{type} RelId ##{rel_id}]

        #create_relation(rel_id, field_value_a)
        relid_fieldvalue_h[rel_id] = field_value_a

        field_value_a = %W[#{rel_id} #{end_gid}:#{visited}]
        #add_to_out_relations_of_node(start_gid, field_value_a)
        if out_gid_fieldvalue_h[start_gid]
          out_gid_fieldvalue_h[start_gid] += field_value_a
        else
          out_gid_fieldvalue_h[start_gid] = field_value_a
        end


        field_value_a = %W[#{rel_id} #{start_gid}:#{visited}]
        #add_to_in_relations_of_node(end_gid, field_value_a)
        if in_gid_fieldvalue_h[end_gid]
          in_gid_fieldvalue_h[end_gid] += field_value_a
        else
          in_gid_fieldvalue_h[end_gid] = field_value_a
        end

      end

      create_relation("rel:", relid_fieldvalue_h)   unless relid_fieldvalue_h.empty?
      create_relation("out:", out_gid_fieldvalue_h) unless out_gid_fieldvalue_h.empty?
      create_relation("in:", in_gid_fieldvalue_h)   unless in_gid_fieldvalue_h.empty?
    end

    def fill
      @log.info "Started at: #{Time.now}"
      remove_all
      read_nodes_csv
      read_rels_csv
      ##rc.fetch_relations
      @log.info "Finished at: #{Time.now}"
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

  end

  #rc=RedisConnector.new
  #rc.bench("without pipelining") {
  #  rc.without_pipelining
  #}
  #rc.bench("with pipelining") {
  #  rc.with_pipelining
  #}

  class RedisConnectorOld

    def add_to_partition_list_for_node(gid, port)
      create_partition_list_for_node(gid, port)
    end

    def create_partition_list_for_node(gid, port)
      result = @redis.lpush gid, port
      @log.debug("Redis add_to_partition_list_for_node(#{gid}, #{port}) returns: #{result}. VT")
      result
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
  end
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

