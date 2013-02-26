class EksikGidPartitionTamamlayici

  def self.read_partition_mapping(file_name)
    gid_partition_h = {}

    is_first_line = true
    File.open(file_name, "r").each_line do |line|
      if is_first_line
        is_first_line = false
        next
      end

      tokens = line.chomp.split("\t")
      gid       = tokens[0].to_i
      is_shadow = tokens[2]
      partition = tokens[3].to_i

      gid_partition_h[gid] = partition if is_shadow == "false"
    end

    gid_partition_h
  end

end

file_name = "resources/nodes.csv"
gid_partition_h = EksikGidPartitionTamamlayici.read_partition_mapping(file_name)
RedisModul::RedisForGidsAndProperties.new.put_partition_mapping_to_redis(gid_partition_h)