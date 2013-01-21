require_relative "./configuration"

class HubwayCSVParser
  def initialize
    @log      = Logger.new(STDOUT)
    @log.level= Configuration::LOG_LEVEL
  end

  def convert_hubwaycsv_to_neo4jcsv
    stations = read_stations_csv
    line_number = 0 #This is equal to the neo_id
    stations.each { |station_id, station|
      line = ""
    }
    end

  def read_stations_csv
    stations = {}
    is_first_line = true
    File.open(Configuration::HUBWAY_STATIONS_CSV, "r").each_line do |line|
      if is_first_line #To skip the first line
        is_first_line = false
        next
      end

      splitted_line = line.split(',')
      station_id    = splitted_line.first
      terminal_name = splitted_line[1]
      name          = splitted_line[2]

      station = {}
      station["terminalName"] = terminal_name
      station["name"] = name
      stations[station_id] = station
    end

    stations.each { |station_id, station|
      puts "#{station_id}\t#{station["terminalName"]}\t#{station["name"]}"
    }

    stations
  end

  def write_to_grf_file(content)
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    nodes_csv = File.new Configuration::NODES_CSV, "w"
    nodes_csv.write content
    nodes_csv.close

    @log.debug("\n#{content}\nis written to the grf file")
  end

end