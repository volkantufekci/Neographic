require_relative 'configuration'

class CypherPartitioner

  def initialize
    @log      = Logger.new(STDOUT)
    @log.level= Configuration::LOG_LEVEL
  end

  def return_partition_mapping
    inject_partition_ports(read_partition_mapping)
  end

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

  #TODO Bu metod cok gereksiz, ya read_partition_mapping'te cagrilmali ki tekrar tum hash'i gezme adimi olmasin
  #ya da kulliyen java tarafinda Cypher ile olusturulurken 0, 1 yerine 6474, 7474 seklinde yazilmali
  def inject_partition_ports(mapping)
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    #0, 1'leri 7474 8474 gibi portlarla degistir
    mapping.each do |gid,partition|
      case partition
        when 0
          mapping[gid] = 6474
        when 1
          mapping[gid] = 7474
        when 2
          mapping[gid] = 8474
        else
          mapping[gid] = 9474
      end
    end
    mapping
  end
end