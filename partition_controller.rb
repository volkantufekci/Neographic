require 'rubygems'
require 'neography'
require 'neography/node'
require '/home/vol/Development/tez/Neographic/redis_connector'
require '/home/vol/Development/tez/Neographic/partition'

module Tez

    class PartitionController

      include RedisModul

      attr_reader :neo1, :neo2, :neo4j_instances

      def initialize(redis_dic={})
        initialize_neo4j_instances(redis_dic)
        @redis_connector = RedisConnector.new(redis_dic)
        @log = Logger.new(STDOUT)
      end

      def del_rels_to_shadows_for_node (node)
        #noinspection RubyResolve
        # Collect relations to shadow node
        rels_to_shadow_nodes = node.rels.both.find_all {|rel| rel.start_node.shadow && rel.end_node.shadow }
        # And... Remove them
        rels_to_shadow_nodes.each { |rel| rel.del }
      end

      def has_any_relation? (node)
        node.rels.size > 0
      end

      def initialize_neo4j_instances(redis_dic)
        @neo1 = connect_to_neo4j_instance('localhost', 7474, redis_dic)
        @neo2 = connect_to_neo4j_instance('localhost', 8474, redis_dic)
        @neo4j_instances = Hash.new
        @neo4j_instances[@neo1.port] = @neo1
        @neo4j_instances[@neo2.port] = @neo2
      end

      def connect_to_neo4j_instance (domain, port, redis_dic)
        Partition.new({:protocol => 'http://',
                             :server => domain,
                             :port => port,
                             :directory => '',  # use '/<my directory>' or leave out for default
                             :authentication => '', # 'basic', 'digest' or leave out for default
                             :username => '', #leave out for default
                             :password => '',  #leave out for default
                             :log_file => STDOUT,
                             :log_enabled => true,
                             :max_threads => 20}, redis_dic)
      end

      def preload_neo4j (neo4j)
        a = neo4j.create_real_node({:title => "a"})
        b = neo4j.create_real_node({:title => "b"})
        c = neo4j.create_real_node({:title => "c"})
        d = neo4j.create_real_node({:title => "d"})
        e = neo4j.create_real_node({:title => "e"})
        f = neo4j.create_real_node({:title => "f"})
        g = neo4j.create_real_node({:title => "g"})
        h = neo4j.create_real_node({:title => "h"})
        #Relationships
        neo4j.create_node_index(:knows)
        neo4j.create_node_index(:shadows)
        #Neography::Relationship.create(:knows, a, b)
        neo4j.create_unique_relationship(:knows, a.global_id, b.global_id, :knows, a, b)
        neo4j.create_unique_relationship(:knows, a.global_id, c.global_id, :knows, a, c)
        neo4j.create_unique_relationship(:knows, b.global_id, c.global_id, :knows, b, c)
        neo4j.create_unique_relationship(:knows, b.global_id, d.global_id, :knows, b, d)
        neo4j.create_unique_relationship(:knows, b.global_id, e.global_id, :knows, b, e)
        neo4j.create_unique_relationship(:knows, c.global_id, e.global_id, :knows, c, e)
        neo4j.create_unique_relationship(:knows, c.global_id, g.global_id, :knows, c, g)
        neo4j.create_unique_relationship(:knows, c.global_id, h.global_id, :knows, c, h)
        neo4j.create_unique_relationship(:knows, e.global_id, f.global_id, :knows, e, f)

      end

      def migrate_via_gpart_mapping(gpart_mapping, before_mapping_hash)
        @log.debug("Migrating Via Gpart Mapping Started")

        #her bir eleman icin real_node'un partitionini al
        @log.debug "Migrating Nodes To Partitions"
        gpart_mapping.each { |key, value|
          gid = key
          source_partition_port = @redis_connector.real_partition_of_node(gid).to_i
          target_partition_port = value
          if target_partition_port != source_partition_port
            #There should be a migration
            source_partition = neo4j_instances[source_partition_port]
            local_id = source_partition.get_indexed_node(gid)
            migrate_node_to_partition(Neography::Node.load(source_partition, local_id), target_partition_port)
          end
        }

        @log.debug("Migrating Relations Of Nodes")
        gpart_mapping.each { |key, value|
          gid = key
          source_partition_port = before_mapping_hash[key]
          target_partition_port = value
          if target_partition_port != source_partition_port
            #There should be a migration
            source_partition = neo4j_instances[source_partition_port]
            target_partition = neo4j_instances[target_partition_port]

            ####TODO bu metod tam functional programminglik
            migrate_relations_of_node(gid, source_partition, target_partition, :both)
          end
        }

        @log.debug("Marking Migrated Nodes As Shadow")
        gpart_mapping.each { |key, value|
          gid = key
          source_partition_port = before_mapping_hash[key]
          target_partition_port = value
          if target_partition_port != source_partition_port
            source_partition = neo4j_instances[source_partition_port]
            source_partition.mark_as_shadow(gid)
          end
        }

      end

      def migrate_node_to_partition(old_real_node, target_port)
        target_partition = neo4j_instances[target_port]

        # redis'ten target partitionda global_id'li node var miya bak
        #noinspection RubyResolve
        partitions_have_the_node = @redis_connector.partitions_have_the_node(old_real_node.global_id)

        if partitions_have_the_node.empty?
          @log.error "Every node should at least have a partition. VT"
        elsif partitions_have_the_node.index(target_port.to_s)
          # There is shadow node, copy properties of real node to this shadow node
          target_partition.migrate_properties_of_node(old_real_node, false)
          @redis_connector.add_to_partition_list_for_node(old_real_node.global_id, target_port)
        else
          # There is no shadow node in target_part, so create new real node
          target_partition.create_real_node(old_real_node.marshal_dump)
          @redis_connector.update_partition_list_for_node(old_real_node.global_id, target_port)
        end

      end

      def migrate_relations_of_node(node_global_id, from_partition, to_partition, direction)
        @log.debug "Migrating Relations Of Node gid:#{node_global_id} from:#{from_partition.port} to:#{to_partition.port}"
        source_node_hash = from_partition.get_indexed_node(node_global_id)
        target_node_hash = to_partition.get_indexed_node(node_global_id)

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

      def merge_node_neighbour_hashes
        @log.debug "Merging node=>[nei1, nei2, ...] hashes coming from partitions"

        final_hash = {}
        @neo4j_instances.values.each do |neo_instance|
          final_hash.merge!(neo_instance.collect_vertex_with_neighbour_h) { |key, oldval, newval|
            (oldval + newval).uniq
          }
        end
        final_hash
      end
    end
end


#node_id = array.first["self"].split('/').last