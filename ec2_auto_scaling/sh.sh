#!/bin/bash -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

cd /home/ubuntu/Neographic
rm configuration.rb

echo "require \"logger\"

class Configuration

  LOG_LEVEL = Logger::INFO
  LOG_FILE  = Dir.home << \"/logv.txt\"

  GPART_GRF_PATH      = Dir.home << \"/hede.grf\"
  GPART_RESULT_PATH   = Dir.home << \"/result.map\"

  REDIS_URL           = \"ec2-23-22-159-95.compute-1.amazonaws.com\"

  #Unpartitioned, original one created at first via batch-importer
  NODES_CSV           = Dir.home << \"/nodes.csv\"
  RELS_CSV            = Dir.home << \"/rels.csv\"

  PARTITIONED_CSV_DIR = Dir.home << \"/partitioned_csv_dir\"

  #Hubway
  HUBWAY_STATIONS_CSV = Dir.home << \"/hubway_original_csv_dir/stations.csv\"
  HUBWAY_TRIPS_CSV    = Dir.home << \"/hubway_original_csv_dir/trips.csv\"

  GID_PARTITION_H     = Dir.home << \"/gid_partition_h\"

  GID        = 12
  PORT       = \"8474\"
  THREAD_COUNT  = 10

  DOMAIN_MAP = {\"6474\" => \"localhost\",
                \"7474\" => \"localhost\",
                \"8474\" => \"ec2-54-243-39-105.compute-1.amazonaws.com\"}
end
" >> configuration.rb
