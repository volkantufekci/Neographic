class NodeController

  def initialize
    @log = Logger.new(STDOUT)
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