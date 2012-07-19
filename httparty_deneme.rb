require "httparty"
require "json"
require_relative './partition_controller'

class HttpartyDeneme
  include HTTParty

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

  def analyze
    redis_dic = {:host => 'localhost', :port => 7379}
    partition7474 = Tez::PartitionController.connect_to_neo4j_instance("localhost", 7474, redis_dic)

    #script = 'x=0;g.v(145).sideEffect{x=x+1}.out.loop(2){it.loops<3}{true}.transform{[it.global_id,it.shadow,x]}'
    out_count = 5
    script = "x=0;g.v(145).out.loop(1){ it.loops < #{out_count} }{ true }.paths({h=[];h[0]=it.global_id; h[1]= it.shadow;h})"
    result = execute_script(script, "localhost", "6474").parsed_response
    shadows = Array.new
    #result.each { |array|
    #  shadows << array if array[1].eql? "true"
    #}
    
    result.each { |array|
      if array.size < out_count && array.last.last.eql?("true")
        gid = array.last.first
        p "gid: #{gid}"
        lid = partition7474.get_indexed_node(gid)["self"].split('/').last
        script2 = "x=0;g.v(#{lid}).sideEffect{x=x+1}.out.loop(2){it.loops<2}{true}.transform{[it.global_id,it.shadow,x]}"
        p script2
        p execute_script(script2, "localhost", "7474").parsed_response
      end
    }

    #p "shadows.size = #{shadows.size}"
    #shadows.each { |key|
    #  lid = partition7474.get_indexed_node(key[0])["self"].split('/').last
    #  script2 = "x=0;g.v(#{lid}).sideEffect{x=x+1}.out.loop(2){it.loops<2}{true}.transform{[it.global_id,it.shadow,x]}"
    #  p script2
    #  p execute_script(script2, "localhost", "7474").parsed_response
    #}
  end
end

#ht = HttpartyDeneme.new
#random_node = rand(1000)
#response = ht.execute_script("g.v(#{random_node}).out")
#result_h = {}
#puts Thread.current.inspect
#result_h[Thread.current.inspect] = response
#puts "hede"

#15/7/2012
#ht.execute_script('g.v(145).out.loop(1){it.loops<3}.transform{[it.global_id,it.shadow]}').parsed_response
#ht.execute_script('x=0;g.v(145).sideEffect{x=x+1}.out.loop(2){it.loops<3}{true}.transform{[it.id,it.shadow,x]}').parsed_response