require 'rubygems'
require 'neography'

class IrbdeDenenler

  @neo = Neography::Rest.new({:protocol => 'http://',
                              :server => 'ec2-107-22-214-211.compute-1.amazonaws.com',
                              :port => 7474,
                              :directory => '',  # use '/<my directory>' or leave out for default
                              :authentication => '', # 'basic', 'digest' or leave out for default
                              :username => '', #leave out for default
                              :password => '',  #leave out for default
                              :log_file => 'neography.log',
                              :log_enabled => false,
                              :max_threads => 20})
#@neo.get_root

#print @neo.get_node_properties(1, ["title"])

  node1 = Neography::Node.load(@neo,1)

  puts node1.title

  puts "node1.relationships.count: #{@neo.get_node_relationships(node1).count}"

  puts "node1.relationships.first: ", @neo.get_node_relationships(node1).first

  puts "node1 out: #{@neo.get_node_relationships(node1, "out")}"

  puts "node1.first['end']: ", @neo.get_node_relationships(node1).first["end"]

  puts "g.v(3): ", @neo.execute_script("g.v(3)")



  node3 = Neography::Node.load(@neo, 3)
  outs = node3.outgoing
  puts "node3.outs.size: #{outs.size}"
  outs.each {|n| puts n.title}
  node2=outs.first

end