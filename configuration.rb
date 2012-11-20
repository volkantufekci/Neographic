require "logger"

class Configuration

  LOG_LEVEL = Logger::INFO

  GPART_GRF_PATH      = Dir.home << "/hede.grf"
  GPART_RESULT_PATH   = Dir.home << "/result.map"

  REDIS_URL           = "ec2-54-243-39-105.compute-1.amazonaws.com"

  #Unpartitioned, original one created at first via batch-importer
  NODES_CSV           = Dir.home << "/nodes.csv"
  RELS_CSV            = Dir.home << "/rels.csv"

  PARTITIONED_CSV_DIR = Dir.home << "/partitioned_csv_dir"

  #Hubway
  HUBWAY_STATIONS_CSV = Dir.home << "/hubway_original_csv_dir/stations.csv"
  HUBWAY_TRIPS_CSV    = Dir.home << "/hubway_original_csv_dir/trips.csv"

  GID_PARTITION_H     = Dir.home << "/gid_partition_h"

  DOMAIN_MAP = {"6474" => "localhost",
                "7474" => "localhost",
                "8474" => "localhost"}
  #DOMAIN_MAP = {"6474" => "ec2-50-16-182-152.compute-1.amazonaws.com",
  #              "7474" => "ec2-107-20-70-72.compute-1.amazonaws.com",
  #              "8474" => "ec2-50-19-27-130.compute-1.amazonaws.com"}


#  HIGH
#  DOMAIN_MAP = {"6474" => "ec2-23-23-21-74.compute-1.amazonaws.com",
#                "7474" => "ec2-23-20-79-67.compute-1.amazonaws.com",
#                "8474" => "ec2-23-20-207-152.compute-1.amazonaws.com"}
end
