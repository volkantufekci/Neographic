require "test/unit"
require_relative '../partition_controller'
require '../redis_connector'

class PartitionControllerTest < Test::Unit::TestCase

  include RedisModul

  require 'minitest/reporters'
  MiniTest::Unit.runner = MiniTest::SuiteRunner.new
  if ENV["RM_INFO"] || ENV["TEAMCITY_VERSION"]
    MiniTest::Unit.runner.reporters << MiniTest::Reporters::RubyMineReporter.new
  elsif ENV['TM_PID']
    MiniTest::Unit.runner.reporters << MiniTest::Reporters::RubyMateReporter.new
  else
    MiniTest::Unit.runner.reporters << MiniTest::Reporters::ProgressReporter.new
  end

  def setup
    @redis_connector = RedisConnector.new
    @redis_connector.remove_all
    self.reset_neo1
    self.reset_neo2
    @pc = Tez::PartitionController.new
    @pc.preload_neo4j(@pc.neo2)
  end

  def teardown
    # Do nothing
  end

  def test_migrate_node_to_partition
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 1), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 3), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 7), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 8), 7474)

    @pc.migrate_relations_of_node( 1, @pc.neo2, @pc.neo1, :both)
    @pc.migrate_relations_of_node( 3, @pc.neo2, @pc.neo1, :both)
    @pc.migrate_relations_of_node( 7, @pc.neo2, @pc.neo1, :both)
    @pc.migrate_relations_of_node( 8, @pc.neo2, @pc.neo1, :both)

    n1_migrated = @pc.neo1.get_indexed_node(1)
    assert_not_nil(n1_migrated, "Node with gid:1 is not migrated!!!")
  end

  def reset_neo1
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_1/bin/neo4j stop`
    `rm -r ~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_1/data/graph.db/*`
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_1/bin/neo4j start`
  end

  def reset_neo2
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_2/bin/neo4j stop`
    `rm -r ~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_2/data/graph.db/*`
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_2/bin/neo4j start`
  end
end