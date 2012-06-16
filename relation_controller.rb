require 'neography'
require_relative 'partition'
require_relative 'configuration'

class RelationController

  def initialize
    @log = Logger.new(STDOUT)
    @log.level=Configuration::LOG_LEVEL
  end

  def migrate_relations_of_node(gid, from_partition, to_partition, direction)
    @log.debug "Migrating Relations Of Node gid:#{gid} from:#{from_partition.port} to:#{to_partition.port}"
    source_node_hash = from_partition.get_indexed_node(gid)
    target_node_hash = to_partition.get_indexed_node(gid)

    #rels_in_from_partition = from_partition.get_node_relationships(end_node_from_partition, "in")
    source_end_node = Neography::Node.load(from_partition, source_node_hash["self"].split('/').last)

    case direction
      when :incoming
        migrate_incoming_relations(from_partition, source_end_node, target_node_hash, to_partition)
      when :outgoing
        migrate_outgoing_relations(from_partition, source_end_node, target_node_hash, to_partition)
      else
        migrate_incoming_relations(from_partition, source_end_node, target_node_hash, to_partition)
        migrate_outgoing_relations(from_partition, source_end_node, target_node_hash, to_partition)
    end

  end

  def migrate_outgoing_relations(from_partition, source_end_node, target_node_hash, to_partition)
    rels_in_from_partition = source_end_node.rels.outgoing
    rels_in_from_partition.each { |rel|
      migrate_relation(rel, from_partition, to_partition, target_node_hash, :outgoing)
    }
  end

  def migrate_incoming_relations(from_partition, source_end_node, target_node_hash, to_partition)
    rels_in_from_partition = source_end_node.rels.incoming
    rels_in_from_partition.each { |rel|
      migrate_relation(rel, from_partition, to_partition, target_node_hash, :incoming)
    }
  end

  def migrate_relation(rel, from_partition, to_partition, node_hash, direction)
    source_other_node   = other_node_of_rel(rel, direction)
    target_other_node_h = to_partition.get_indexed_node(source_other_node.global_id)

    rel_exists = false
    if target_other_node_h.nil?
      target_other_node_h = to_partition.create_shadow_node_hash(source_other_node)
    else
      rel_exists = to_partition.rel_exists?(rel, node_hash, target_other_node_h, direction)
    end

    unless rel_exists
      new_rel = to_partition.create_relation(rel, node_hash, target_other_node_h, direction)

      unless new_rel
        properties = from_partition.get_relationship_properties(rel)
        to_partition.set_relationship_properties(new_rel, properties) unless properties.nil?
      end

    end
  end

  def other_node_of_rel(rel, direction)
    case direction
      when :incoming
        source_other_node = rel.start_node
      else
        source_other_node = rel.end_node
    end
    source_other_node
  end
end