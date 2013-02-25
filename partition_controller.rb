require 'rubygems'
require 'set'
require_relative './redis_connector'
#require_relative './partition'
#require_relative 'node_controller'
#require_relative 'relation_controller'
require_relative 'configuration'

module Tez

    class PartitionController

      include RedisModul

      attr_reader :neo1, :neo2, :neo4j_instances, :rel_controller

      def initialize()
        @gid_neoid_h = {}

        #initialize_neo4j_instances(redis_dic)
        @redis_connector = RedisConnector.new
        #@nc = NodeController.new
        #@rel_controller = RelationController.new
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

      def generate_csvs(gid_partition_h, gid_relidnei_h)
        @log.info("#{__method__.to_s} started[#{self.class.to_s}]")
        shadow_partition_gids_h, partition_gids_h = {}, {}

        gid_partition_h.each do |gid, partition|
          if partition_gids_h[partition]
            partition_gids_h[partition] << gid
          else
            partition_gids_h[partition] = [gid]
          end

          #node_neis.each shadow olanlari shadow_gid_partition_h'a ekle
          relid_nei_h = gid_relidnei_h[gid]
          #relid_nei_h.values.each { |nei_visited| collect_shadows(nei_visited, partition, gid_partition_h, shadow_partition_gids_h) }
          relid_nei_h.each_value { |nei_visited| collect_shadows(nei_visited, partition, gid_partition_h, shadow_partition_gids_h) }
        end

        gid_relidnei_h  = nil
        #gid_partition_h = nil
        @log.info("shadows and reals are separated into their partition hashes[#{__method__.to_s} ]")

        partition_gids_h.each { |partition, gids|
          @log.info("Building node lines for #{partition} started")
          lines = "gid\t__type__\tname\tshadow:boolean\tport\n"
          self.write_to_file(partition, lines, "nodes.csv")
          lines = "id\tgid\tname\n"
          self.write_to_file(partition, lines, "nodes_index.csv")
          build_node_csv_lines(gids, partition, gid_partition_h, false)

          @log.info("Building shadow node lines for #{partition} started")
          shadow_gids = shadow_partition_gids_h[partition].uniq
          build_node_csv_lines(gids.length, shadow_gids, partition, gid_partition_h, true)

          @log.info("Building rel lines for #{partition} started")
          lines    = "Start\tEnde\tType\tVisited\n"
          self.write_to_file(partition, lines, "rels.csv")
          all_gids = gids + shadow_gids
          build_rels_csv_lines(all_gids, partition)

        }

      end

      def collect_shadows(nei_visited, partition, gid_partition_h, shadow_partition_gids_h)
        #nei = nei_visited.split(":").first
        #nei = nei.to_i
        nei = nei_visited.to_i
        if gid_partition_h[nei] == partition
          #nei de ayni part'ta, bir sey yapmaya gerek yok
        else
          if shadow_partition_gids_h[partition]
            shadow_partition_gids_h[partition] << nei
          else
            shadow_partition_gids_h[partition] = [nei]
          end
        end
      end

      def build_node_csv_lines(neo_id = 0, gids, partition, gid_partition_h, are_shadows)
        max_idx = gids.length - 1
        lower, upper, interval = 0, 9999, 10000
        while lower <= max_idx
          temp_gids = gids[lower..upper]

          lines, index_lines = "", ""
          #fetch node properties
          gid_props_h = @redis_connector.fetch_values_for(:node, temp_gids)
          gid_props_h.each { |gid, props|
            neo_id += 1                 #increment before, because neo_id=0 is reference node.
            @gid_neoid_h[gid] = neo_id
            line = "#{gid}"
            #props.values.each { |value| line << "\t#{value}" }
            props.each_value { |value| line << "\t#{value}" }
            line << "\t#{are_shadows}\t#{gid_partition_h[gid]}\n"
            lines << line
            index_line = "#{neo_id}\t#{gid}\t#{props["name"]}\n"
            index_lines << index_line
          }
          self.append_to_file(partition, lines, "nodes.csv")
          self.append_to_file(partition, index_lines, "nodes_index.csv")

          lower += interval
          upper += interval
        end

      end

      def build_rels_csv_lines(all_gids, partition)
        rel_ids = self.collect_relids(all_gids)
        max_idx = rel_ids.length - 1
        lower, upper, interval = 0, 9999, 10000

        while lower <= max_idx
          temp_relids = rel_ids[lower..upper]

          lines = ""
          #fetch rel properties
          rel_props_h = @redis_connector.fetch_values_for(:rel, temp_relids)
          #rel_props_h.values.each { |props|
          rel_props_h.each_value { |props|
            ende = @gid_neoid_h[props["Ende"].to_i] # If gid is a shadow its rel may not be in this partition
            if ende
              line = ""
              props.each do |property, value|
                case property
                  when "Start"
                    line << "#{@gid_neoid_h[value.to_i]}"
                  when "Ende"
                    line << "\t#{ende}"
                  else
                    line << "\t#{value}"
                end
              end
              line << "\n"
              lines << line
            end
          }
          self.append_to_file(partition, lines, "rels.csv")

          lower += interval
          upper += interval
        end

      end

      def collect_relids(all_gids)
        gid_relidgid_h = @redis_connector.fetch_values_for(:out, all_gids)
        #relid_gid_h_a = gid_relidgid_h.values
        #gid_relidgid_h = nil
        rel_ids = []
        #relid_gid_h_a.each { |relid_gid_h| rel_ids << relid_gid_h.keys }
        gid_relidgid_h.each_value { |relid_gid_h| rel_ids << relid_gid_h.keys }
        rel_ids.flatten!
        rel_ids
      end

      def write_to_file(dir_name, to_the_file, file_name="nodes.csv")
        csv_dir = Configuration::PARTITIONED_CSV_DIR
        Dir.mkdir(csv_dir) unless Dir.exists?(csv_dir)
        if Dir.exists?("#{csv_dir}/#{dir_name}")
          `rm #{csv_dir}/#{dir_name}/#{file_name}`
        else
          Dir.mkdir("#{csv_dir}/#{dir_name}")
        end
        Dir.chdir("#{csv_dir}/#{dir_name}")
        file = File.new file_name, "w"
        file.write to_the_file
        file.close
      end

      def append_to_file(dir_name, to_the_file, file_name="nodes.csv")
        csv_dir = Configuration::PARTITIONED_CSV_DIR
        Dir.mkdir(csv_dir) unless Dir.exists?(csv_dir)
        Dir.chdir("#{csv_dir}/#{dir_name}")
        file = File.new file_name, "a"
        file.write to_the_file
        file.close
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
            source_partition      = neo4j_instances[source_partition_port]
            local_id              = source_partition.get_indexed_node(gid) #NEO4J
            to_be_migrated_node   = Neography::Node.load(source_partition, local_id)
            migrated_node_shadows << to_be_migrated_node
            target_partition      = neo4j_instances[target_partition_port]
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

      # @see #collect_node_nei_hashes
      def merge_node_neighbour_hashes
        # "Merging node=>[nei1, nei2, ...] hashes coming from partitions"
        @log.info("#{__method__.to_s} started[#{self.class.to_s}]")

        final_hash = {}
        @neo4j_instances.values.each do |neo_instance|
          final_hash.merge!(neo_instance.collect_vertex_with_neighbour_h) { |key, oldval, newval|
            (oldval + newval).uniq  #arrays merged and duplicates are eliminated
          }
        end
        final_hash
      end

      # before this method node_nei_hashes were collected from neo4j instances via merge_node_neighbour_hashes method
      # but this method collects node_nei_hashes from redis in the format of "gid=>[nei1_gid, nei2_gid, ...] "
      # @see #merge_node_neighbour_hashes
      def collect_node_nei_hashes
        @log.info("#{__method__.to_s} started[#{self.class.to_s}]")

        node_nei_hash = @redis_connector.fetch_relations
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