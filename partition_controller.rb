require 'rubygems'
require 'neography'
require '/home/vol/Development/tez/Neographic/redis_connector'


module Tez

    class PartitionController

      include RedisModul

      attr_reader :neo1, :neo2, :neo4j_instances

      def initialize
        initialize_neo4j_instances
      end

      def process_nodes_after_shadowing

      end

      def delete_relation_to_shadows_for_node (node, rel_type=nil)
        # Collect relations to shadow node
        rels_to_shadow_nodes = n4.rels.both.find_all {|rel| rel.start_node.shadow && rel.end_node.shadow }
        # And... Remove them
        rels_to_shadow_nodes.each { |rel| rel.del }
      end

      def has_any_relation? (node)
        result = false
        result = true if node.rels.size > 0
      end

      def delete_node (node)
        node.del

        # TODO Redisi Guncelle
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

      def make_node_shadow (node)
        node.shadow = true
      end

      def make_node_unshadow (node)
        node.shadow = nil
      end

      def load_node_in_partition(g)

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
        Neography::Relationship.create(:knows, a, b)
        Neography::Relationship.create(:knows, a, c)
        Neography::Relationship.create(:knows, b, c)
        Neography::Relationship.create(:knows, b, d)
        Neography::Relationship.create(:knows, b, e)
        Neography::Relationship.create(:knows, c, e)
        Neography::Relationship.create(:knows, c, g)
        Neography::Relationship.create(:knows, c, h)
        Neography::Relationship.create(:knows, e, f)
      end

      def create_real_node_in_partition(properties, partition)
        #if properties include global_id that means this is a move process
        unless properties[:global_id]
          properties[:global_id] = RedisConnector.new_global_id
          RedisConnector.create_partition_list_for_node(properties[:global_id], partition.port)
        end
        new_node = Neography::Node.create(properties, partition)
        add_node_to_globalid_index(new_node, partition)
      end

      def move_node_to_partition(node, partition_port)
        target_partition = neo4j_instances[partition_port]

        # redis'ten target partitionda global_id'li node var miya bak
        partitions_have_the_node = RedisConnector.partitions_have_the_node(node.global_id)

        if partitions_have_the_node.empty?
          #TODO ERROR every node should at least have a partition
        elsif partitions_have_the_node.index(partition_port.to_s)
          # There is shadow node, copy properties of real node to this shadow node
          shadow_node = get_node_from_globalid_index(node.global_id, target_partition)
          shadow_node_id = shadow_node["self"].split('/').last
          puts "shadow_node_id=#{shadow_node_id}"

          puts "set node's properties to shadow node in the target partition"
          target_partition.set_node_properties(shadow_node, node.marshal_dump)

        else
          # There is no shadow node in target_part, so create new real node
          create_real_node_in_partition(node.marshal_dump, target_partition)
        end

      end

      def add_node_to_globalid_index(node, partition)
        partition.add_node_to_index(:globalidindex, :global_id, node.global_id, node)
      end

      def get_node_from_globalid_index(global_id_value, partition)
        array = partition.get_node_index(:globalidindex, :global_id, global_id_value)
        if array.empty?
          # node, indexe eklenmemis
        else
          #node_id = array.first["self"].split('/').last
          node = array.first
        end
      end

      def test_move_node_to_partition
        n2_8474 = Neography::Node.load(@neo2, 2)
        move_node_to_partition(n2_8474, 7474)

      end

    end
end


#pc = Tez::PartitionController.new
#pc.test_move_node_to_partition
