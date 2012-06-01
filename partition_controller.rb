require 'rubygems'
require 'neography'
require '/home/vol/Development/tez/Neographic/redis_connector'


module Tez

    class PartitionController

      include RedisModul

      attr_reader :neo1, :neo2, :neo4j_instances

      def initialize
        initialize_neo4j_instances
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

      def shadow_nodes (nodes)
        nodes.each do |node|
          make_node_shadow(node)
        end
      end

      def unshadow_nodes (nodes)
        nodes.each do |node|
          make_node_unshadow(node)
        end
      end

      # @param [Neography::Node] node
      def make_node_shadow (node)
        #noinspection RubyResolve
        node.shadow = true
      end

      def make_node_unshadow (node)
        #noinspection RubyResolve
        node.shadow = nil
      end

      def initialize_neo4j_instances
        @neo1 = connect_to_neo4j_instance('localhost', 7474)
        @neo2 = connect_to_neo4j_instance('localhost', 8474)
        @neo4j_instances = Hash.new
        @neo4j_instances[@neo1.port] = @neo1
        @neo4j_instances[@neo2.port] = @neo2
      end

      def connect_to_neo4j_instance (domain, port)
        Neography::Rest.new({:protocol => 'http://',
                             :server => domain,
                             :port => port,
                             :directory => '',  # use '/<my directory>' or leave out for default
                             :authentication => '', # 'basic', 'digest' or leave out for default
                             :username => '', #leave out for default
                             :password => '',  #leave out for default
                             :log_file => 'neography.log',
                             :log_enabled => false,
                             :max_threads => 20})
      end

      # @param [Neography::Rest] neo4j
      def preload_neo4j (neo4j)
        a = create_real_node_in_partition({:title => "a"}, neo4j)
        b = create_real_node_in_partition({:title => "b"}, neo4j)
        c = create_real_node_in_partition({:title => "c"}, neo4j)
        d = create_real_node_in_partition({:title => "d"}, neo4j)
        e = create_real_node_in_partition({:title => "e"}, neo4j)
        f = create_real_node_in_partition({:title => "f"}, neo4j)
        g = create_real_node_in_partition({:title => "g"}, neo4j)
        h = create_real_node_in_partition({:title => "h"}, neo4j)
        #Relationships
        neo4j.create_node_index(:knows)
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

      def migrate_node_to_partition(old_real_node, port)
        target_partition = neo4j_instances[port]

        # redis'ten target partitionda global_id'li node var miya bak
        #noinspection RubyResolve
        partitions_have_the_node = RedisConnector.partitions_have_the_node(old_real_node.global_id)

        if partitions_have_the_node.empty?
          @log.error("every node should at least have a partition")
        elsif partitions_have_the_node.index(port.to_s)
          # There is shadow node, copy properties of real node to this shadow node
          migrate_properties_of_node(old_real_node, target_partition, false)
          RedisConnector.add_to_partition_list_for_node(old_real_node.global_id, port)
        else
          # There is no shadow node in target_part, so create new real node
          create_real_node_in_partition(old_real_node.marshal_dump, target_partition)
        end

      end

      def migrate_properties_of_node(old_real_node, target_partition, will_be_shadow)
        # Should be moved to a class extends Neography::Node
        shadow_node_hash = get_indexed_node_from_partition(old_real_node.global_id, target_partition)
        shadow_node_id = shadow_node_hash["self"].split('/').last

        @log.info("There is shadow_node with id=#{shadow_node_id}")
        @log.info("set node's properties to shadow node in the target partition")

        properties_from_old = old_real_node.marshal_dump
        properties_from_old[:shadow] = will_be_shadow
        target_partition.set_node_properties(shadow_node_hash, properties_from_old)
      end

      def create_real_node_in_partition(properties, partition)
        #if properties include global_id that means this is a migrate process
        if properties[:global_id]
          @log.info("Node with global_id: #{properties[:global_id]} will be migrated to partition: #{partition.port}")
        else
          global_id = RedisConnector.new_global_id
          properties[:global_id] = global_id
          RedisConnector.create_partition_list_for_node(global_id, partition.port)
          #@log.info("new global id created: #{global_id}")
        end

        new_node = Neography::Node.create(properties, partition)
        properties[:shadow] = false
        @log.info("Node(#{new_node.neo_id}) with global_id: #{properties[:global_id]} created in partition with port: #{partition.port}")
        add_node_to_index_of_partition(new_node, partition)
        return new_node
      end

      def add_node_to_index_of_partition(node, partition)
        #noinspection RubyResolve
        partition.add_node_to_index(:globalidindex, :global_id, node.global_id, node)
      end

      def get_indexed_node_from_partition(global_id_value, partition)
        @log.info("get_indexed_node_from_partition(gid:#{global_id_value}, port:#{partition.port})")
        array = partition.get_node_index(:globalidindex, :global_id, global_id_value)
        if array.nil?
          @log.info("Partition #{partition.port} does not have a node with gid: #{global_id_value}")
          node = nil
        else
          node = array.first
        end

      end

      def migrate_relations_of_node(node_global_id, from_partition, to_partition, direction)

        source_node_hash = get_indexed_node_from_partition( node_global_id, from_partition )
        target_node_hash = get_indexed_node_from_partition( node_global_id, to_partition )

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
        source_other_node      = other_node_of_rel(rel, direction)
        target_other_node_hash = get_indexed_node_from_partition( source_other_node.global_id, to_partition )

        rel_exists = false
        if target_other_node_hash.nil?
          target_other_node_hash = create_shadow_node_hash(source_other_node, to_partition)
        else
          rel_exists = rel_exists?(rel, node_hash, target_other_node_hash, to_partition, direction)
        end

        unless rel_exists
          case direction
            when :incoming
              #new_rel = partition.create_relationship(rel_in_source["type"], start_node_to_partition, end_node)
              #new_rel = to_partition.create_relationship(rel.rel_type, target_other_node_hash, node_hash)
              new_rel =
                  to_partition.create_unique_relationship(rel.rel_type,
                                                          target_other_node_hash["data"]["global_id"],
                                                          node_hash["data"]["global_id"],
                                                          rel.rel_type,
                                                          target_other_node_hash, node_hash)
              log_relation_migration(node_hash, rel, target_other_node_hash)
            when :outgoing
              #new_rel = to_partition.create_relationship(rel.rel_type, node_hash, target_other_node_hash)
              new_rel =
                  to_partition.create_unique_relationship(rel.rel_type,
                                                          node_hash["data"]["global_id"],
                                                          target_other_node_hash["data"]["global_id"],
                                                          rel.rel_type,
                                                          node_hash, target_other_node_hash)
              log_relation_migration(target_other_node_hash, rel, node_hash)
            else
              @log.error("direction:#{direction} other than :incoming or :outgoing!")
              new_rel = nil
          end

          inject_properties(rel, new_rel, from_partition, to_partition) unless new_rel
        end
      end

      def log_relation_migration(node_hash, rel, target_other_node_hash)
        other_node_title = target_other_node_hash["data"]["title"]
        node_title = node_hash["data"]["title"]
        @log.info("#{other_node_title} =>#{rel.rel_type}=> #{node_title} created")
      end

      def inject_properties(rel, new_rel, from_partition, to_partition)
        properties = from_partition.get_relationship_properties(rel)
        to_partition.set_relationship_properties(new_rel, properties) unless properties.nil?
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

      def rel_exists?(rel_in_source, node_hash, target_other_node_hash, to_partition, direction)
        #checks the relation index on the target partition if there exist a relation that we want to migrate

        if direction == :incoming
          to_partition.get_relationship_index(rel_in_source.rel_type,
                                              target_other_node_hash["data"]["global_id"],
                                              node_hash["data"]["global_id"])
        else
          to_partition.get_relationship_index(rel_in_source.rel_type,
                                              node_hash["data"]["global_id"],
                                              target_other_node_hash["data"]["global_id"])
        end

      end

      def create_shadow_node_hash(node, partition)
        new_shadow_node_hash = partition.create_unique_node(:globalidindex,
                                                            :global_id,
                                                             node.global_id,
                                                             node.marshal_dump)
        partition.set_node_properties(new_shadow_node_hash, {:shadow => true})

        @log.info("Shadow node with global_id: #{node.global_id} is created ")
        return new_shadow_node_hash
      end

      def test_migrate_node_to_partition
        migrate_node_to_partition(Neography::Node.load(@neo2, 1), 7474)
        migrate_node_to_partition(Neography::Node.load(@neo2, 3), 7474)
        migrate_node_to_partition(Neography::Node.load(@neo2, 7), 7474)
        migrate_node_to_partition(Neography::Node.load(@neo2, 8), 7474)

        #n1_8474 = Neography::Node.load(@neo2, 1)
        #migrate_node_to_partition(n1_8474, 7474)
      end

      #noinspection RubyInstanceMethodNamingConvention
      def test_migrate_relations_of_node
        migrate_relations_of_node( 1, @neo2, @neo1, :both)
        migrate_relations_of_node( 3, @neo2, @neo1, :both)
        migrate_relations_of_node( 7, @neo2, @neo1, :both)
        migrate_relations_of_node( 8, @neo2, @neo1, :both)
      end

    end
end


pc = Tez::PartitionController.new
#pc.preload_neo4j(pc.neo2)

pc.test_migrate_node_to_partition

pc.test_migrate_relations_of_node


#node_id = array.first["self"].split('/').last