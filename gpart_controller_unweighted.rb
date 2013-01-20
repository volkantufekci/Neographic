require_relative "./gpart_controller"

class GpartControllerUnweighted < GpartController

  # values of a hash like {1=>[2, 3], 2=>[1, 3, 4, 5]} must be passed
  def build_grf_file(gid_relidnei_h)
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    relid_nei_h_array = gid_relidnei_h.values

    lines = ""
    relation_count = not_empty_node_count = 0

    relid_nei_h_array.each do |relid_nei_h|
      neighbours = relid_nei_h.values.uniq
      not_empty_node_count += 1
      relation_count += neighbours.length
      line = "\n#{neighbours.length}"
      neighbours.each { |node_id|
        line << "\t#{node_id}"
      }

      lines << line
      #end
    end

    grf_file_content = "0\n" << "#{not_empty_node_count}\t" << "#{relation_count}\n" << "0\t000" << lines
    write_to_grf_file(grf_file_content)

    grf_file_content
  end

end