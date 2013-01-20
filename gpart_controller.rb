require_relative "./configuration"

class GpartController

  def initialize(neo4j_count={})
    @total_neo4j_count = neo4j_count

    @log      = Logger.new(STDOUT)
    @log.level= Configuration::LOG_LEVEL
  end

  def partition_and_return_mapping(gid_relidnei_h)
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    self.build_grf_file(gid_relidnei_h)
    self.perform_gparting
  end

  def perform_gparting
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    neo4j_count = @total_neo4j_count
    #`gpart #{neo4j_count} #{Configuration::GPART_GRF_PATH} #{Configuration::GPART_RESULT_PATH} -b0.9`
    `gpart #{neo4j_count} #{Configuration::GPART_GRF_PATH} #{Configuration::GPART_RESULT_PATH}`
    gpart_mapping = read_gpart_result
    gpart_mapping = inject_partition_ports(gpart_mapping)
    #should return sth like {1=>7474, 2=>6474, 3=>7474, ...}
  end

  def read_gpart_result
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    gpart_result_h = Hash.new
    lines = IO.readlines(Configuration::GPART_RESULT_PATH)
    lines.each{ |line|
      if line.split(/\t/).length == 2     ####To skip the first line
        gpart_result_h[line.split(/\t/).first.to_i]=line.split(/\t/).last.split(/\n/).first.to_i
      end
    }

    gpart_result_h
  end

  # values of a hash like {1=>[2, 3], 2=>[1, 3, 4, 5]} must be passed
  def build_grf_file(gid_relidnei_h)
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    relid_nei_h_array = gid_relidnei_h.values

    lines = ""
    relation_count = not_empty_node_count = 0

    relid_nei_h_array.each do |relid_nei_h|
      #unless neighbours.nil? || neighbours.empty?
      #  neighbours = relid_nei_h.values.uniq
        neighbours = Hash.new
        relid_nei_h.values.each do |neiid_visited|
          splitted  = neiid_visited.split(":")
          neiid     = splitted.first
          visited   = splitted.last
          if neighbours[neiid]
            neighbours[neiid] += visited.to_i
          else
            neighbours[neiid] = visited.to_i
          end
        end
        not_empty_node_count += 1
        relation_count += neighbours.size
        line = "\n#{neighbours.size}"
        neighbours.each { |nei_id, visited|
          line << "\t#{visited}\t#{nei_id}"
        }
        #neighbours.each { |node_id| line << "\t#{@gpart_index_array.index(node_id.to_i)}" }
        lines << line
      #end
    end

    grf_file_content = "0\n" << "#{not_empty_node_count}\t" << "#{relation_count}\n" << "0\t010" << lines
    write_to_grf_file(grf_file_content)

    grf_file_content
  end

  def inject_partition_ports(gpart_mapping)
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    #0, 1'leri 7474 8474 gibi portlarla degistir
    gpart_mapping.each_pair do |key,value|
      case value
        when 0
          gpart_mapping[key] = 6474
        when 1
          gpart_mapping[key] = 6475
        when 2
          gpart_mapping[key] = 6476
        when 3
          gpart_mapping[key] = 6477
        when 4
          gpart_mapping[key] = 6478
        when 5
          gpart_mapping[key] = 6479
        when 6
          gpart_mapping[key] = 6480
        when 7
          gpart_mapping[key] = 6481
        when 8
          gpart_mapping[key] = 6482
        when 9
          gpart_mapping[key] = 6483

        #when 1
        #  gpart_mapping[key] = 7474
        #when 2
        #  gpart_mapping[key] = 8474
        #else
        #  gpart_mapping[key] = 9474
      end
    end
    gpart_mapping
  end

  private

  def write_to_grf_file(to_the_file)
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    gpart_input_file = File.new Configuration::GPART_GRF_PATH, "w"
    gpart_input_file.write to_the_file
    gpart_input_file.close

    @log.debug("\n#{to_the_file}\nis written to the grf file")
  end


  #def map_gids_to_gpart_indexes(gid_nei_hash)
  #  @gpart_index_array = gid_nei_hash.keys
  #end

end