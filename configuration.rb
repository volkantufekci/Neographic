require "logger"

class Configuration

  LOG_LEVEL = Logger::INFO

  GPART_GRF_PATH = Dir.home << "/hede.grf"
  GPART_RESULT_PATH  = Dir.home << "/result.map"

  #DOMAIN_MAP = {"6474" => "localhost",
  #              "7474" => "localhost",
  #              "8474" => "localhost"}
  #DOMAIN_MAP = {"6474" => "ec2-50-16-182-152.compute-1.amazonaws.com",
  #              "7474" => "ec2-107-20-70-72.compute-1.amazonaws.com",
  #              "8474" => "ec2-50-19-27-130.compute-1.amazonaws.com"}


#  HIGH
  DOMAIN_MAP = {"6474" => "ec2-23-23-21-74.compute-1.amazonaws.com",
                "7474" => "ec2-23-20-79-67.compute-1.amazonaws.com",
                "8474" => "ec2-23-20-207-152.compute-1.amazonaws.com"}
end