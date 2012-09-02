require_relative './partition_controller'
require_relative './redis_connector'
require_relative './gpart_controller'

max_node_idx        = 99999
total_neo4j_count   = 2


rc                  = RedisModul::RedisConnector.new
rc.fill
gid_relidnei_h      = rc.fetch_relations max_node_idx
gpc                 = GpartController.new(total_neo4j_count)
gid_partition_h     = gpc.partition_and_return_mapping(gid_relidnei_h)

#gpart_mapping   = gpc.read_gpart_result
#gid_partition_h = gpc.inject_partition_ports(gpart_mapping)

pc                  = Tez::PartitionController.new
pc.generate_csvs(gid_partition_h, gid_relidnei_h)

puts "Finished at: #{Time.now}"

#jruby -J-Xmx3000m -w for_debug.rb
