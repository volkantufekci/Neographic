require_relative "./configuration"

class GpartController

  def initialize
    @gpart_index_array = []
  end

  def read_gpart_mapping
    words = IO.readlines("../gpartDenemeleri/2/mapping.map")

    hash = Hash.new
    words.each{ |line|
      if line.split(/\t/).length == 2     ####To skip the first line
        hash[line.split(/\t/).first.to_i]=line.split(/\t/).last.split(/\n/).first.to_i
      end
    }

    hash_with_keys_plus1 = Hash.new
    hash.each { |key, value| hash_with_keys_plus1[key+1]=value }  #Plus 1 as gpart starts with 0
    hash_with_keys_plus1
  end

  def before_mapping_hash
    #TODO find a way to keep the mapping before migrations
    hash = {1=>0, 2=>0, 3=>0, 4=>0, 5=>0, 6=>0, 7=>0, 8=>0}
    hash = inject_partition_ports hash
  end

  def perform_gpart_mapping
    gpart_mapping = read_gpart_mapping
    gpart_mapping = inject_partition_ports(gpart_mapping)
    #should return sth like {1=>1, 2=>0, 3=>1, 4=>0, 5=>0, 6=>0, 7=>1, 8=>1}
  end

  def build_grf_file(array)
    #for i in 1..7 do ; a = pc.neo1.execute_script("g.V[#{i}].both.id"); id = pc.neo1.execute_script("g.V[#{i}].id"); h[id.to_s]=a end

    #h=[]
    #for i in 1..7 do ; a = pc.neo1.execute_script("g.V[#{i}].both.id"); h[i]=a end
    # h will be [nil, [2, 5], [5, 1, 4, 3, 6], [2], [2], [1, 2], [2], []]

    #pc.neo1.execute_script("g.V.global_id")
    #for i in 1..7 do ; a = pc.neo1.execute_script("g.V[#{i}].both.global_id"); gid = pc.neo1.execute_script("g.V[#{i}].global_id").first ; h[gid]=a end
    lines = ""
    relation_count = not_empty_node_count = 0

    array.each do |neighbours|
      unless neighbours.nil? || neighbours.empty?
        not_empty_node_count += 1
        relation_count += neighbours.length
        line = "\n#{neighbours.length}"
        neighbours.each { |node_id| line << "\t#{@gpart_index_array.index(node_id)}" }
        lines << line
      end
    end

    to_the_file = "0\n" << "#{not_empty_node_count}\t" << "#{relation_count}\n" << "0\t000" << lines
    puts to_the_file

    gpart_input_file = File.new Configuration::GRF_FILE_PATH, "w"
    gpart_input_file.write to_the_file
    gpart_input_file.close

    to_the_file

  end

  #could be private
  def inject_partition_ports(gpart_mapping)
    #0, 1'leri 7474 8474 gibi portlarla degistir
    gpart_mapping.each_pair do |key,value|
      case value
        when 0
          gpart_mapping[key] = 8474
        when 1
          gpart_mapping[key] = 7474
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