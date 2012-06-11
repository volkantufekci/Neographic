class GpartController

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
end