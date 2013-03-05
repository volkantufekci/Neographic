require_relative './redis_connector_erdos'
require_relative './partition_controller_erdos'

class ForAccessPatternWOScotch
  def initialize
    @max_node_idx   = 1850022 #1850065 #553000 #9
    @rc             = RedisModul::RedisConnectorErdos.new

    @last_partition =6483
    @partitions=[6474,6475,6476]
  end

  def work
    start = Time.now
    puts "Baslangic: #{start}"

    gid_relidnei_h = @rc.fetch_relations(@max_node_idx)
    @partitions.each { |partition|
      delegate_csv_generation(gid_relidnei_h, @last_partition, partition)
    }

    #Generate also LAST_PARTITIONs graph.db which is the unpartitioned graph
    #sending -1 as last partition in order not to skip any partition
    delegate_csv_generation(gid_relidnei_h, -1, @last_partition)

    puts "Toplam sure: #{Time.now - start}"
  end

  def delegate_csv_generation(gid_relidnei_h, last_partition, partition)
    file_name = "#{Configuration::GID_PARTITION_H}_#{partition}"
    gid_partition_h = read_partition_mapping(file_name)
    Tez::PartitionControllerErdos.new.generate_csvs(gid_partition_h, gid_relidnei_h, last_partition)
  end

  def read_partition_mapping(file_name)
    gid_partition_h = {}

    File.open(file_name, "r").each_line do |line|
      tokens = line.chomp.split(",")
      gid       = tokens[0].to_i
      partition = tokens[1].to_i
      gid_partition_h[gid] = partition
    end

    gid_partition_h
  end
end


ForAccessPatternWOScotch.new.work