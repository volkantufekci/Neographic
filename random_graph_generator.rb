require_relative 'redis_connector'
require_relative 'partition_controller'

class RandomGraphGenerator

  def fill_graph_randomly(neo4j_instance_no, random_node_count, redis_dic)
    RedisModul::RedisConnector.new(redis_dic).remove_all

    #calismiyor
    #reset_neo(neo4j_instance_no)

    instance_mapping = {0=>6474, 1=>7474, 2=>8474}
    neo4j_instance = Tez::PartitionController.connect_to_neo4j_instance(
                        'localhost', instance_mapping[neo4j_instance_no], redis_dic)

    neo4j_instance.create_node_index(:knows)
    neo4j_instance.create_node_index(:shadows)

    node_array = create_random_nodes(neo4j_instance, random_node_count)
    create_random_edges(neo4j_instance, node_array)

  end

  private

  def create_random_edges(neo4j_instance, node_array)
    logger.info("CREATE_RANDOM_EDGES")
    node_array_count = node_array.count
    node_array.each { |source_node|
      index = node_array.index(source_node)
      logger.debug "Edges are being created for node with idx: #{index}"
      target_node_ids = []

      2.times { |i|
        #if index < node_array_count / 2
        #  random_id = rand(node_array_count / 2 - 1)
        #else
        #  random_id = rand(node_array_count / 2 - 1) + (node_array_count - 1) / 2
        #end
        random_id = rand(node_array_count - 1)
        unless target_node_ids.include?(random_id) or index == random_id
          target_node_ids << random_id
          target_node = node_array[random_id]
          neo4j_instance.create_unique_relationship(:knows, source_node.global_id, target_node.global_id,
                                                    :knows, source_node, target_node)
        end
      }
    }
  end

  def create_random_nodes(neo4j_instance, random_node_count)
    @log.info("#{self.class.to_s}##{__method__.to_s} started")
    node_array = []

    1.upto(random_node_count) { |i|
      data = {:title => i}
      node_array << neo4j_instance.create_real_node(data)
    }

    node_array
  end

  def reset_neo(instance_no)
    # did not work for 8474 3.8.2012
    instance_mapping = {0=>6474, 1=>7474, 2=>8474}

    if [0, 1, 2].include? instance_no
      logger.info("neo#{instance_no} is being reset. VT")
      port = instance_mapping[instance_no]
      `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_#{instance_no}/bin/neo4j start`
      `curl -X DELETE http://localhost:#{port}/db/data/cleandb/secret-key`
    else
      logger.error("There is no neo instance with no: #{instance_no}. VT")
    end

  end

  def logger
    @logger ||= Logger.new(STDOUT)
    @logger.level=Logger::INFO
    @logger
  end
end

#rgg = RandomGraphGenerator.new
#rgg.fill_graph_randomly(0, 100, {})