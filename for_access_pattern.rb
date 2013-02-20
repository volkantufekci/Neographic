require_relative './partition_controller_erdos'

start = Time.now
puts "Started at: #{start}"

max_node_idx        = 1850065 #553000 #9

rc                  = RedisModul::RedisConnectorErdos.new
rc.fill

gid_relidnei_h      = rc.fetch_relations max_node_idx
gid_partition_h     = read_partition_mapping()
#gpc                 = GpartController.new(total_neo4j_count)

Tez::PartitionControllerErdos.new.generate_csvs(gid_partition_h, gid_relidnei_h)

puts "Toplam sure: #{Time.now - start}"

def read_partition_mapping
  gid_partition_h = {}

  File.open(Configuration::GID_PARTITION_H, "r").each_line do |line|
    tokens = line.chomp.split(",")
    gid       = tokens[0].to_i
    partition = tokens[1].to_i
    gid_partition_h[gid] = partition
  end

  gid_partition_h
end