require 'rubygems'
require 'neography'
require 'neography/node'
require_relative './redis_connector'
require_relative './partition'
require_relative 'node_controller'
require_relative 'relation_controller'
require_relative 'configuration'

module Tez

    class PartitionController

      include RedisModul

      attr_reader :neo1, :neo2, :neo4j_instances, :rel_controller

      def initialize(redis_dic={})
        initialize_neo4j_instances(redis_dic)
        @redis_connector = RedisConnector.new(redis_dic)
        @nc = NodeController.new
        @rel_controller = RelationController.new
        @log = Logger.new(STDOUT)
        @log.level = Configuration::LOG_LEVEL
      end

      def initialize_neo4j_instances(redis_dic)
        @neo4j_instances = Hash.new

        domain_map = Configuration::DOMAIN_MAP
        domain_map.keys.each do |port|
          neo_instance = PartitionController.connect_to_neo4j_instance(domain_map[port], port.to_i, redis_dic)
          @neo4j_instances[neo_instance.port] = neo_instance
        end

      end

      def self.connect_to_neo4j_instance (domain, port, redis_dic)
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

      def migrate_via_gpart_mapping(gpart_mapping, before_mapping_hash)
        @log.info("Migrating Via Gpart Mapping Started")

        migrated_node_shadows = []

        #her bir eleman icin real_node'un partitionini al
        @log.info "Migrating Nodes To Partitions"
        gpart_mapping.each { |key, value|
          gid = key
          source_partition_port = @redis_connector.real_partition_of_node(gid).to_i
          target_partition_port = value
          if target_partition_port != source_partition_port
            #There should be a migration
            source_partition = neo4j_instances[source_partition_port]
            local_id = source_partition.get_indexed_node(gid)
            to_be_migrated_node = Neography::Node.load(source_partition, local_id)
            migrated_node_shadows << to_be_migrated_node
            target_partition = neo4j_instances[target_partition_port]
            @nc.migrate_node_to_partition(to_be_migrated_node, target_partition, @redis_connector)
          end
        }

        @log.info("Migrating Relations Of Nodes")
        gpart_mapping.each { |key, value|
          gid = key
          source_partition_port = before_mapping_hash[key]
          target_partition_port = value
          if target_partition_port != source_partition_port
            #There should be a migration
            source_partition = neo4j_instances[source_partition_port]
            target_partition = neo4j_instances[target_partition_port]

            @rel_controller.migrate_relations_of_node(gid, source_partition, target_partition, :both)
          end
        }

        @log.info("Marking Migrated Nodes As Shadow")
        gpart_mapping.each { |key, value|
          gid = key
          source_partition_port = before_mapping_hash[key]
          target_partition_port = value
          if target_partition_port != source_partition_port
            source_partition = neo4j_instances[source_partition_port]
            source_partition.mark_as_shadow(gid)
          end
        }

        @log.info("Deleting Relations To Shadows")
        @nc.del_rels_to_shadows_for_nodes(migrated_node_shadows)

        @log.info("Deleting Shadows Without Relation")
        @nc.del_shadow_without_relation(migrated_node_shadows)
      end


      def merge_node_neighbour_hashes
        # "Merging node=>[nei1, nei2, ...] hashes coming from partitions"
        @log.info("#{self.class.to_s}##{__method__.to_s} started")

        final_hash = {}
        @neo4j_instances.values.each do |neo_instance|
          final_hash.merge!(neo_instance.collect_vertex_with_neighbour_h) { |key, oldval, newval|
            (oldval + newval).uniq  #arrays merged and duplicates are eliminated
          }
        end
        final_hash
      end

      #return hash whose keys are gids and values are real_partition_port of them
      def before_mapping_hash(gid_array)
        @log.info "BEFORE_MAPPING_HASH"
        ##TODO test test test

        hash = Hash.new
        gid_array.each { |gid| hash[gid] = @redis_connector.real_partition_of_node(gid).to_i }
        hash
      end
    end
end


#node_id = array.first["self"].split('/').last