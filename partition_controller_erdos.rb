require_relative './partition_controller'

module Tez
  class PartitionControllerErdos < PartitionController
    def generate_csvs(gid_partition_h, gid_relidnei_h, exclude_partition=-1)
      @log.info("#{__method__.to_s} started[#{self.class.to_s}]")
      #shadow_partition_gids_h, partition_gids_h = {}, {}
      partitions = Set.new

      gid_partition_h.each_value { |partition|
        partitions.add(partition) unless partition == exclude_partition
      }

      partitions.each do |partition|
        @gid_neoid_h.clear

        gids = []
        gid_partition_h.each { |k, v| gids << k if v == partition }

        shadow_partition_gids_h = {}
        gids.each do |gid|
          relid_nei_h = gid_relidnei_h[gid]
          relid_nei_h.each_value { |nei_visited|
            collect_shadows(nei_visited, partition, gid_partition_h, shadow_partition_gids_h)
          }
        end

        @log.info("Building #{gids.size} node lines for #{partition} started")
        lines = "gid\tname\tshadow:boolean\tport\n"
        self.write_to_file(partition, lines, "nodes.csv")
        lines = "id\tgid\tname\n"
        self.write_to_file(partition, lines, "nodes_index.csv")
        build_node_csv_lines(gids, partition, gid_partition_h, false)

        shadow_gids = []
        unless shadow_partition_gids_h[partition] == nil
          shadow_gids = shadow_partition_gids_h[partition].uniq
          @log.info("Building #{shadow_gids.size} shadow node lines for #{partition} started")
          build_node_csv_lines(gids.length, shadow_gids, partition, gid_partition_h, true)
        end

        @log.info("Building rel lines for #{partition} started")
        lines    = "Start\tEnde\tType\n"
        self.write_to_file(partition, lines, "rels.csv")
        all_gids = gids + shadow_gids
        build_rels_csv_lines(all_gids, partition)
      end

    end
  end
end
