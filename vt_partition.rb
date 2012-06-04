require 'neography'
require '../redis_connector'

class VTPartition < Neography::Rest

  include RedisModul

  def initialize(options)
    super(options)
    @logger.level=Logger::INFO
  end

  def create_real_node_in_partition(properties)
    #if properties include global_id that means this is a migrate process
    if properties[:global_id]
      @logger.info("Node with global_id: #{properties[:global_id]} will be migrated to partition: #{self.port}")
    else
      global_id = RedisConnector.new_global_id
      properties[:global_id] = global_id
      RedisConnector.create_partition_list_for_node(global_id, self.port)
      #@log.info("new global id created: #{global_id}")
    end

    new_node = Neography::Node.create(properties, self)
    properties[:shadow] = false
    @logger.info("Node(#{new_node.neo_id}) with global_id: #{properties[:global_id]} created in partition with port: #{self.port}")

    self.add_node_to_index(:globalidindex, :global_id, new_node.global_id, new_node)

    new_node
  end

  def create_shadow_node_hash(node)
    new_shadow_node_hash = self.create_unique_node(:globalidindex,
                                                        :global_id,
                                                        node.global_id,
                                                        node.marshal_dump)
    self.set_node_properties(new_shadow_node_hash, {:shadow => true})

    @logger.info("Shadow node with global_id: #{node.global_id} is created ")
    new_shadow_node_hash
  end

  def get_indexed_node(global_id_value)
    @logger.info("get_indexed_node with gid:#{global_id_value} from port:#{self.port}")

    array = self.get_node_index(:globalidindex, :global_id, global_id_value)
    if array.nil?
      @logger.info("Partition #{self.port} does not have a node with gid: #{global_id_value}")
      node = nil
    else
      node = array.first
    end

    node
  end

  def migrate_properties_of_node(old_real_node, will_be_shadow)
    # Should be moved to a class extends Neography::Node
    shadow_node_hash = self.get_indexed_node(old_real_node.global_id)
    shadow_node_id = shadow_node_hash["self"].split('/').last

    @logger.info("There is shadow_node with id=#{shadow_node_id}")

    properties_from_old = old_real_node.marshal_dump
    properties_from_old[:shadow] = will_be_shadow
    self.set_node_properties(shadow_node_hash, properties_from_old)
    @logger.info("node's properties is set to shadow node's")
  end

  def rel_exists?(rel_in_source, node_hash, target_other_node_h, direction)
    #checks the relation index on the target partition if there exist a relation that we want to migrate

    if direction == :incoming
      self.get_relationship_index(rel_in_source.rel_type,
                                  target_other_node_h["data"]["global_id"],
                                  node_hash["data"]["global_id"])
    else
      self.get_relationship_index(rel_in_source.rel_type,
                                  node_hash["data"]["global_id"],
                                  target_other_node_h["data"]["global_id"])
    end

  end


end