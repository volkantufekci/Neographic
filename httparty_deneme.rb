require "httparty"
require "json"
require_relative './partition_controller'
require_relative './redis_connector'

class HttpartyDeneme
  include HTTParty

  def initialize
    @redis_dic = {:host => 'localhost', :port => 7379}  #test_port: 7379
    @redis_connector = RedisModul::RedisConnector.new(@redis_dic)
    @domain = "localhost"
    @domain_map = {"6474" => "ec2-50-16-182-152.compute-1.amazonaws.com",
                   "7474" => "ec2-107-20-70-72.compute-1.amazonaws.com",
                   "8474" => "107.22.214.211"}

    #@domain_map = {"6474" => "localhost",
    #               "7474" => "localhost",
    #               "8474" => "localhost"}
  end

  def execute_script(script, server, port)
    options = { :body => {:script => script}.to_json , :headers => {'Content-Type' => 'application/json'} }
    configuration = "http://#{server}:#{port}/db/data/ext/GremlinPlugin/graphdb/execute_script"

    response = HTTParty.post(configuration, options)
  end

  def analyze(gid, out_count)
    real_partition = find_real_partition_of_node(gid)
    lid = find_lid_from_partition(gid, real_partition)
    script = "x=0;g.v(#{lid}).out.loop(1){it.loops<#{out_count}}{true}.paths({h=[];h[0]=it.global_id;h[1]= it.shadow;h})"
    result = execute_script(script, @domain_map["6474"], "6474").parsed_response

    recursive_result = run_again_for_shadows(out_count, result)
  end

  def differentiate_from_valid_partition(gid, filtered_results, out_count)
    result_from_valid_partition = execute_on_valid_partition(gid, out_count)
    filtered_results.each { |array|
      unless result_from_valid_partition.include?(array)
        puts "hede #{array.flatten}"
      end
    }
  end

  def execute_on_valid_partition(gid, out_count)
    valid_partition = Tez::PartitionController.connect_to_neo4j_instance(@domain_map["8474"], 8474, @redis_dic)
    lid = valid_partition.get_indexed_node(gid)["self"].split('/').last #local_id
    script3 = "x=0;g.v(#{lid}).out.loop(1){it.loops<#{out_count}}{true}.paths({h=[];h[0]=it.global_id;h[1]= it.shadow;h})"
    result_from_valid_partition = execute_script(script3, @domain_map["8474"], "8474").parsed_response
  end

  def filter_intermediate_paths(out_count, recursive_result)
    filtered_results = []
    i = 0
    recursive_result.each { |arraycik|
      if arraycik.size == out_count
        #puts "#{arraycik}\n"
        filtered_results << arraycik
        i = i + 1
      end
    }
    puts "#{i} paths"
    filtered_results
  end

  private
  def run_again_for_shadows(out_count, result)
    sayko_array =[]
    result.each { |array|
      if array.size < out_count && array.last.last.eql?("true")
        gid = array.last.first

        partition_real = find_real_partition_of_node(gid)
        lid = partition_real.get_indexed_node(gid)["self"].split('/').last #local_id

        new_out_count = out_count - array.size + 1
        script_for_real = "g.v(#{lid}).out.loop(1){it.loops<#{new_out_count}}{true}.paths({h=[];h[0]=it.global_id; h[1]= it.shadow;h})"
        new_result = execute_script(script_for_real, @domain_map[partition_real.port.to_s],
                                    partition_real.port).parsed_response

        array.pop
        new_sayko_array = run_again_for_shadows(new_out_count, new_result)
        new_sayko_array.each { |arraycik|
          copy_array = array.compact  #compact is used just to create a copy of array
          copy_array = copy_array + arraycik
          sayko_array << copy_array
        }
      else
        sayko_array << array
      end
    }

    sayko_array
  end

  def find_real_partition_of_node(gid)
    partition_port = @redis_connector.real_partition_of_node(gid).to_i
    partition_real = Tez::PartitionController.connect_to_neo4j_instance(@domain, partition_port, @redis_dic)
  end

  def find_lid_from_partition(gid, real_partition)
    lid = real_partition.get_indexed_node(gid)["self"].split('/').last
  end

end

ht = HttpartyDeneme.new
out_count = 5
#gid = 272
gid = rand(1..1000)
puts "random gid: #{gid}"

start = Time.now
results_from_nonpartitioned = ht.filter_intermediate_paths(out_count, ht.execute_on_valid_partition(gid, out_count))
puts "results_from_nonpartitioned.size = #{results_from_nonpartitioned.size}"
p Time.now - start

start = Time.now
results_from_partitioned = ht.filter_intermediate_paths(out_count, ht.analyze(gid, out_count))
puts "results_from_partitioned.size = #{results_from_partitioned.size}"
#ht.differentiate_from_valid_partition(gid, filtered_results, out_count)
p Time.now - start

#random_node = rand(1000)
#response = ht.execute_script("g.v(#{random_node}).out")
#result_h = {}
#puts Thread.current.inspect
#result_h[Thread.current.inspect] = response
#puts "hede"

#15/7/2012
#ht.execute_script('g.v(145).out.loop(1){it.loops<3}.transform{[it.global_id,it.shadow]}').parsed_response
#ht.execute_script('x=0;g.v(145).sideEffect{x=x+1}.out.loop(2){it.loops<3}{true}.transform{[it.id,it.shadow,x]}').parsed_response

#23/7/2012 oncesi
#script2 = "x=0;g.v(#{lid}).sideEffect{x=x+1}.out.loop(2){it.loops<2}{true}.transform{[it.global_id,it.shadow,x]}"


#response.each { |node_hash|
#  id = node_hash["self"].split('/').last
#  #h[id] = node_hash
#  h << id
#}