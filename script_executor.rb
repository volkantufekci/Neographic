require "httparty"
require "json"
require_relative './partition_controller'
require_relative './redis_connector'

class ScriptExecutor
  def execute_script(script, server, port)
    options = { :body => {:script => script}.to_json , :headers => {'Content-Type' => 'application/json'} }
    configuration = "http://#{server}:#{port}/db/data/ext/GremlinPlugin/graphdb/execute_script"

    response = HTTParty.post(configuration, options)
  end
end

out_count = 8
se = ScriptExecutor.new
script3 = "x=0;g.v(272).out.loop(1){ it.loops < #{out_count} }.paths({h=[];h[0]=it.global_id; h[1]= it.shadow;h})"
result3 = se.execute_script(script3, "localhost", "8474").parsed_response

i = 0
result3.each { |arraycik|
  if arraycik.size == out_count
    puts "#{arraycik}\n"
    i = i + 1
  end
}