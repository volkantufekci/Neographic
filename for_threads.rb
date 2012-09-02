require_relative './partition_controller'
require_relative './redis_connector'
require_relative './gpart_controller'

start = Time.now
puts "Started at: #{start}"
2.times do |i|
  Thread.new do
    max_node_idx        = 49999
    rc                  = RedisModul::RedisConnector.new("_#{i}")
    gid_relidnei_h      = rc.fetch_relations max_node_idx
    puts gid_relidnei_h.keys.size
  end
end

Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
puts "Duration: #{Time.now-start}"


start = Time.now
puts "Started at: #{start}"
max_node_idx        = 99999
rc                  = RedisModul::RedisConnector.new
gid_relidnei_h      = rc.fetch_relations max_node_idx
puts gid_relidnei_h.keys.size

Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
puts "Duration: #{Time.now-start}"

#total_neo4j_count   = 2
#@gpc                = GpartController.new(total_neo4j_count)
#gid_partition_h     = @gpc.partition_and_return_mapping(gid_relidnei_h)
##1.upto(100) {|i| puts "#{i} => #{gpart_mapping_hash[i]}"}
#
#
##gpc             = GpartController.new
##gpart_mapping   = gpc.read_gpart_result
##gid_partition_h = gpc.inject_partition_ports(gpart_mapping)
#
#pc              = Tez::PartitionController.new
#pc.generate_csvs(gid_partition_h, gid_relidnei_h)



#jruby -J-Xmx3000m -w for_debug.rb
