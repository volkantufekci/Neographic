require_relative "./redis_connector"

module RedisModul

  class RedisConnectorErdos < RedisConnector
    def read_nodes_csv
      @log.info("#{self.class.to_s}##{__method__.to_s} started")
      i = 0
      is_header_line = true
      gid_fieldvalue_h = {}
      File.open(Configuration::NODES_CSV, "r").each_line do |line|
        if is_header_line
          is_header_line = false
          next
        end
        i += 1
        if i % 10000 == 0
          create_node(gid_fieldvalue_h)
          gid_fieldvalue_h.clear
        end

        tokens = line.chomp.split("\t")

        gid = tokens[1]
        field_value_a = %W[name #{tokens[0]}]
        gid_fieldvalue_h[gid] = field_value_a
      end

      create_node(gid_fieldvalue_h)
    end

    def read_rels_csv
      @log.info("#{self.class.to_s}##{__method__.to_s} started")

      relid_fieldvalue_h, out_gid_fieldvalue_h, in_gid_fieldvalue_h = {}, {}, {}
      i = 0
      is_header_line = true
      File.open(Configuration::RELS_CSV, "r").each_line do |line|
        if is_header_line
          is_header_line = false
          next
        end
        i += 1
        if i % 10000 == 0
          @log.info "#{i}. relation created" if i % 1000000 == 0
          create_relation("rel:", relid_fieldvalue_h)
          relid_fieldvalue_h.clear

          create_relation("out:", out_gid_fieldvalue_h)
          out_gid_fieldvalue_h.clear

          create_relation("in:", in_gid_fieldvalue_h)
          in_gid_fieldvalue_h.clear
        end

        tokens        = line.chomp.split("\t")
        start_gid     = tokens[0]
        end_gid       = tokens[1]
        type          = tokens[2]
        #visited       = tokens[3]
        visited       = 0
        #counter       = tokens[4]
        #rel_id        = counter
        #rel_id        = tokens[3]
        rel_id        = i
        field_value_a = %W[Start #{start_gid} Ende #{end_gid} Type #{type} RelId ##{rel_id}]

        #create_relation(rel_id, field_value_a)
        relid_fieldvalue_h[rel_id] = field_value_a

        #field_value_a = %W[#{rel_id} #{end_gid}:#{visited}]
        field_value_a = %W[#{rel_id} #{end_gid}]
        #add_to_out_relations_of_node(start_gid, field_value_a)
        if out_gid_fieldvalue_h[start_gid]
          out_gid_fieldvalue_h[start_gid] += field_value_a
        else
          out_gid_fieldvalue_h[start_gid] = field_value_a
        end


        #field_value_a = %W[#{rel_id} #{start_gid}:#{visited}]
        field_value_a = %W[#{rel_id} #{start_gid}]
        #add_to_in_relations_of_node(end_gid, field_value_a)
        if in_gid_fieldvalue_h[end_gid]
          in_gid_fieldvalue_h[end_gid] += field_value_a
        else
          in_gid_fieldvalue_h[end_gid] = field_value_a
        end

      end

      create_relation("rel:", relid_fieldvalue_h)   unless relid_fieldvalue_h.empty?
      create_relation("out:", out_gid_fieldvalue_h) unless out_gid_fieldvalue_h.empty?
      create_relation("in:", in_gid_fieldvalue_h)   unless in_gid_fieldvalue_h.empty?
    end
  end

end