require "logger"

class Configuration

  #home_dir  = Dir.home
  home_dir  = "/home/ubuntu"

  LOG_LEVEL = Logger::INFO
  LOG_FILE  = home_dir + "/logv.txt"

  GPART_GRF_PATH      = home_dir + "/hede.grf"
  GPART_RESULT_PATH   = home_dir + "/result.map"

  REDIS_URL           = "ec2-54-243-39-105.compute-1.amazonaws.com"

  #Unpartitioned, original one created at first via batch-importer
  NODES_CSV           = home_dir + "/nodes.csv"
  RELS_CSV            = home_dir + "/rels.csv"

  PARTITIONED_CSV_DIR = home_dir + "/partitioned_csv_dir"

  #Hubway
  HUBWAY_STATIONS_CSV = home_dir + "/hubway_original_csv_dir/stations.csv"
  HUBWAY_TRIPS_CSV    = home_dir + "/hubway_original_csv_dir/trips.csv"

  GID_PARTITION_H     = home_dir + "/gid_partition_h"

  GID           = 12
  PORT          = "8474"
  THREAD_COUNT  = 10

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
