#require "ruby-prof"
require_relative './partition_controller_erdos'
require_relative './redis_connector'
require_relative './redis_connector_erdos'
require_relative './gpart_controller'
require_relative './gpart_controller_unweighted'
require_relative 'cypher_partitioner'
require_relative './redis_for_gids_and_properties'

start = Time.now
puts "Started at: #{start}"

max_node_idx        = 1850065 #553000 #9
total_neo4j_count   = 10


rc                  = RedisModul::RedisConnectorErdos.new

#RubyProf.start
rc.fill


gid_relidnei_h      = rc.fetch_relations max_node_idx
#gid_partition_h     = CypherPartitioner.new.return_partition_mapping
#gpc                 = GpartController.new(total_neo4j_count)
gpc                 = GpartControllerUnweighted.new(total_neo4j_count)
gid_partition_h     = gpc.partition_and_return_mapping(gid_relidnei_h)
RedisModul::RedisForGidsAndProperties.new.put_partition_mapping_to_redis(gid_partition_h)
#
Tez::PartitionControllerErdos.new.generate_csvs(gid_partition_h, gid_relidnei_h)

#result = RubyProf.stop
#printer = RubyProf::CallStackPrinter.new(result)
#file = File.new("ruby-prof-report", "w+")
#printer.print(file, :min_percent => 2)

puts "Toplam sure: #{Time.now - start}"