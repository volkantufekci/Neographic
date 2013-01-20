require_relative './partition_controller'
require_relative './redis_connector'
require_relative './redis_connector_erdos'
require_relative './gpart_controller'
require_relative './gpart_controller_unweighted'
require_relative 'cypher_partitioner'

start = Time.now
puts "Started at: #{start}"

max_node_idx        = 1850065 #553000 #9
total_neo4j_count   = 10


#rc                  = RedisModul::RedisConnector.new
rc                  = RedisModul::RedisConnectorErdos.new
rc.fill
gid_relidnei_h      = rc.fetch_relations max_node_idx
#gid_partition_h     = CypherPartitioner.new.return_partition_mapping
#gpc                 = GpartController.new(total_neo4j_count)
gpc                 = GpartControllerUnweighted.new(total_neo4j_count)
gid_partition_h     = gpc.partition_and_return_mapping(gid_relidnei_h)
#
Tez::PartitionController.new.generate_csvs(gid_partition_h, gid_relidnei_h)

puts "Time elapsed: #{Time.now - start}"

#partition = 7474
#p "~/neo4j/#{partition}/bin/neo4j stop"
#`~/neo4j/#{partition}/bin/neo4j stop`
#
#p "rm -r ~/neo4j/#{partition}/data/graph.db"
#`rm -r ~/neo4j/#{partition}/data/graph.db`
#
#p "java -server -Xmx2G -jar ~/batch-import-jar-with-dependencies.jar ~/neo4j/#{partition}/data/graph.db ~/partitioned_csv_dir/#{partition}/nodes.csv ~/partitioned_csv_dir/#{partition}/rels.csv"
#`java -server -Xmx2G -jar ~/batch-import-jar-with-dependencies.jar ~/neo4j/#{partition}/data/graph.db ~/partitioned_csv_dir/#{partition}/nodes.csv ~/partitioned_csv_dir/#{partition}/rels.csv`
#
#p "~/neo4j/#{partition}/bin/neo4j start"
#`~/neo4j/#{partition}/bin/neo4j start`


#jruby -J-Xmx3000m -w for_debug.rb
