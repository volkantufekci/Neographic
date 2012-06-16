require_relative "./configuration"

class GpartController

  def initialize(gid_nei_hash, neo4j_count)
    @gid_nei_hash = gid_nei_hash
    @gpart_index_array = map_gids_to_gpart_indexes(gid_nei_hash)
    @total_neo4j_count = neo4j_count

    @log = Logger.new(STDOUT)
    @log.level=Configuration::LOG_LEVEL
  end

  def partition_and_return_mapping
    self.build_grf_file
    self.perform_mapping
  end

  def perform_mapping
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    neo4j_count = @total_neo4j_count
    `gpart #{neo4j_count} #{Configuration::GPART_GRF_PATH} #{Configuration::GPART_RESULT_PATH}`
    gpart_mapping = read_gpart_result
    gpart_mapping = inject_partition_ports(gpart_mapping)
    #should return sth like {1=>1, 2=>0, 3=>1, 4=>0, 5=>0, 6=>0, 7=>1, 8=>1}
  end

  def read_gpart_result
    lines = ""
    File.open(Configuration::GPART_RESULT_PATH, 'r') do |input|
      while (line = input.gets)
        lines << line
      end
    end
    @log.info("\n#{lines}is read from the mapping file")

    gpart_result_h = Hash.new
    lines = IO.readlines(Configuration::GPART_RESULT_PATH)
    lines.each{ |line|
      if line.split(/\t/).length == 2     ####To skip the first line
        gpart_result_h[line.split(/\t/).first.to_i]=line.split(/\t/).last.split(/\n/).first.to_i
      end
    }

    hash_with_keys_plus1 = Hash.new
    gpart_result_h.each { |key, value| hash_with_keys_plus1[@gpart_index_array[key]]=value }  #Plus 1 as gpart starts with 0
    hash_with_keys_plus1
  end

  # values of a hash like {1=>[2, 3], 2=>[1, 3, 4, 5]} must be passed
  def build_grf_file
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    nei_arrays_array = @gid_nei_hash.values

    lines = ""
    relation_count = not_empty_node_count = 0

    nei_arrays_array.each do |neighbours|
      unless neighbours.nil? || neighbours.empty?
        not_empty_node_count += 1
        relation_count += neighbours.length
        line = "\n#{neighbours.length}"
        neighbours.each { |node_id| line << "\t#{@gpart_index_array.index(node_id)}" }
        lines << line
      end
    end

    grf_file_content = "0\n" << "#{not_empty_node_count}\t" << "#{relation_count}\n" << "0\t000" << lines
    write_to_grf_file(grf_file_content)

    grf_file_content
  end

  private

  def write_to_grf_file(to_the_file)
    gpart_input_file = File.new Configuration::GPART_GRF_PATH, "w"
    gpart_input_file.write to_the_file
    gpart_input_file.close

    @log.info("\n#{to_the_file}\nis written to the grf file")
  end

  def inject_partition_ports(gpart_mapping)
    #0, 1'leri 7474 8474 gibi portlarla degistir
    gpart_mapping.each_pair do |key,value|
      case value
        when 0
          gpart_mapping[key] = 6474
        when 1
          gpart_mapping[key] = 7474
        when 2
          gpart_mapping[key] = 8474
        else
          gpart_mapping[key] = 9474
      end
    end
    gpart_mapping
  end

  def map_gids_to_gpart_indexes(gid_nei_hash)
    @gpart_index_array = gid_nei_hash.keys
  end

end