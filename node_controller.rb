class NodeController

  def initialize
    @log = Logger.new(STDOUT)
  end


  def migrate_node_to_partition(old_real_node, target_partition, redis_connector)
    #target_partition = neo4j_instances[target_port]
    target_port = target_partition.port

    # redis'ten target partitionda global_id'li node var miya bak
    #noinspection RubyResolve
    partitions_have_the_node = redis_connector.partitions_have_the_node(old_real_node.global_id)

    if partitions_have_the_node.empty?
      @log.error "Every node should at least have a partition. VT"
    elsif partitions_have_the_node.index(target_port.to_s)
      # There is shadow node, copy properties of real node to this shadow node
      target_partition.migrate_properties_of_node(old_real_node, false)
      redis_connector.add_to_partition_list_for_node(old_real_node.global_id, target_port)
    else
      # There is no shadow node in target_part, so create new real node
      target_partition.create_real_node(old_real_node.marshal_dump)
      redis_connector.update_partition_list_for_node(old_real_node.global_id, target_port)
    end

  end

  def del_rels_to_shadows_for_node (nodes)
    nodes.each { |node|
      @log.debug("DELETING RELATIONS TO SHADOWS FOR NODE GID:#{node.global_id}")
      # Collect relations to shadow node
      rels_to_shadow_nodes = node.rels.both.find_all {|rel| rel.start_node.shadow && rel.end_node.shadow }
      # And... Remove them
      rels_to_shadow_nodes.each { |rel| rel.del }
    }
  end

  def del_shadow_without_relation(shadows)
    shadows.each { |node|
      unless self.has_any_relation?(node)
        node.del
        @log.debug("Shadow node with gid: #{node.global_id} deleted")
      end
    }
  end


  def has_any_relation? (node)
    node.rels.size > 0
  end

end