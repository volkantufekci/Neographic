require 'rubygems'
require 'neography'

module Tez
  class PartitionController

    class PartitionController

      attr_reader :neo1, :neo2, :neo4j_instances

      def initialize
        initialize_neo4j_instances
      end

      def delete_relation_to_shadow_nodes_of_node (node, rel_type=nil)
        # Find relations to shadow node
        rels_to_shadow_nodes = n4.rels.both.find_all {|rel| rel.start_node.shadow && rel.end_node.shadow }
        rels_to_shadow_nodes.each { |rel| rel.del }
      end

      def delete_node (node)
        node.del
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

      def initialize_neo4j_instances
        @neo1 = connect_to_neo4j_instance('localhost', 7474)
        @neo2 = connect_to_neo4j_instance('localhost', 8474)
        @neo4j_instances = [@neo1, @neo2]
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
        a = Neography::Node.create({"title" => "a"}, neo4j)
        b = Neography::Node.create({"title" => "b"}, neo4j)
        c = Neography::Node.create({"title" => "c"}, neo4j)
        d = Neography::Node.create({"title" => "d"}, neo4j)
        e = Neography::Node.create({"title" => "e"}, neo4j)
        f = Neography::Node.create({"title" => "f"}, neo4j)
        g = Neography::Node.create({"title" => "g"}, neo4j)
        h = Neography::Node.create({"title" => "h"}, neo4j)
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

    end

  end
end

