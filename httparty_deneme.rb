require "httparty"
require "json"
require_relative './partition_controller'
require_relative './redis_connector'

class HttpartyDeneme
  include HTTParty

  def initialize
    @redis_dic = {:host => 'localhost', :port => 7379}
    @redis_connector = RedisModul::RedisConnector.new(@redis_dic)
  end

  def execute_script(script, server, port)
    options = { :body => {:script => script}.to_json , :headers => {'Content-Type' => 'application/json'} }
    #configuration = "http://107.22.214.211:7474/db/data/ext/GremlinPlugin/graphdb/execute_script"
    configuration = "http://#{server}:#{port}/db/data/ext/GremlinPlugin/graphdb/execute_script"

    #h = []
    response = HTTParty.post(configuration, options)
    #response.each { |node_hash|
    #  id = node_hash["self"].split('/').last
    #  #h[id] = node_hash
    #  h << id
    #}

    #h
    #puts "#{index} => #{response.size}"
  end

  def analyze(out_count)
    @volkan =[]

    #script = 'x=0;g.v(145).sideEffect{x=x+1}.out.loop(2){it.loops<3}{true}.transform{[it.global_id,it.shadow,x]}'
    script = "x=0;g.v(145).out.loop(1){ it.loops < #{out_count} }{ true }.paths({h=[];h[0]=it.global_id; h[1]= it.shadow;h})"
    result = execute_script(script, "localhost", "6474").parsed_response
    p "size=#{result.size}"
    #result.each { |arraycik| p arraycik if arraycik.size == out_count}

    #result.each { |arraycik|
    #  @volkan << arraycik if arraycik.size == out_count
    #}

    volkan_ayiklanmis = []
    @volkan = run_again_for_shadows(out_count, result)
    i = 0
    @volkan.each { |arraycik|
      if arraycik.size == out_count
        #puts "#{arraycik}\n"
        volkan_ayiklanmis << arraycik
        i = i + 1
      end
    }
    puts "#{i}"

    script3 = "x=0;g.v(272).out.loop(1){ it.loops < #{out_count} }.paths({h=[];h[0]=it.global_id; h[1]= it
.shadow;h})"
    result3 = execute_script(script3, "localhost", "8474").parsed_response
    #fark = volkan_ayiklanmis - result3
    volkan_ayiklanmis.each { |array|
      unless result3.include?(array)
        puts "hede #{array.flatten}"
      end

    }
    #puts fark
  end

  def run_again_for_shadows(out_count, result)
    sayko_array =[]
    result.each { |array|
      if array.size < out_count && array.last.last.eql?("true")
        #puts "\n#{array}"
        gid = array.last.first

        partition_port = @redis_connector.real_partition_of_node(gid).to_i
        partition_real = Tez::PartitionController.connect_to_neo4j_instance("localhost", partition_port, @redis_dic)

        lid = partition_real.get_indexed_node(gid)["self"].split('/').last #local_id

        new_out_count = out_count-array.size + 1
        script2 = "g.v(#{lid}).out.loop(1){it.loops<#{new_out_count}}{true}.paths({h=[];h[0]=it.global_id; h[1]= it.shadow;h})"
        new_result = execute_script(script2, "localhost", partition_port).parsed_response

        #puts "size=#{new_result.size} new_out_count:#{new_out_count} "
        #new_result.each { |arraycik| p arraycik if arraycik.size == new_out_count}
        #new_result.each { |arraycik|
        #
        #  if arraycik.size == new_out_count
        #    array.pop
        #    array << arraycik
        #    @volkan << array
        #  end
        #}

        array.pop
        new_sayko_array = run_again_for_shadows(new_out_count, new_result)
        new_sayko_array.each { |arraycik|
          copy_array = array.compact
          copy_array = copy_array + arraycik
          sayko_array << copy_array
        }
      else
        sayko_array << array
      end
    }

    sayko_array
  end
end

start = Time.now
ht = HttpartyDeneme.new
ht.analyze(8)
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