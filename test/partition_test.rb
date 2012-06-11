require "test/unit"
require '../partition'
require '../redis_connector'

class PartitionTest < Test::Unit::TestCase

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
    test_port = 7379
    @redis_connector = RedisConnector.new(:host => 'localhost', :port => test_port)
    @redis_connector.remove_all

    reset_neo3

    @neo_test = Partition.new({:protocol => 'http://',
                     :server => 'localhost',
                     :port => 9474,
                     :directory => '',  # use '/<my directory>' or leave out for default
                     :authentication => '', # 'basic', 'digest' or leave out for default
                     :username => '', #leave out for default
                     :password => '',  #leave out for default
                     :log_file => STDOUT,
                     :log_enabled => true,
                     :max_threads => 20}, {:host => 'localhost', :port => test_port})


    preload_neo4j(@neo_test)
  end

  def teardown
    # Do nothing
  end

  def test_create_shadow_node_hash
    logger.info("TEST_CREATE_SHADOW_NODE_HASH STARTED")

    node = @neo_test.create_real_node({:title => "test_create_node"})
    node.global_id = 555

    @neo_test.create_shadow_node_hash(node)
    actual_shadow_node_hash = @neo_test.get_shadow_node_index.first

    assert_equal(555, actual_shadow_node_hash["data"]["global_id"], "create_shadow_node_hash failed")
  end

  def test_mark_as_shadow
    logger.info("TEST_MARK_AS_SHADOW STARTED")

    @neo_test.mark_as_shadow(1)
    n1 = @neo_test.get_indexed_node(1)
    assert_equal(true, n1["data"]["shadow"], "Failed to make node shadow")

    n1 = @neo_test.get_shadow_node_index.first
    assert_equal(true, n1["data"]["shadow"], "Shadow node should have been indexed at shadow index")
  end



  #### HELPER METHODS ####

  def reset_neo3
    logger.info("neo3_test is being reset. VT")
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_3/bin/neo4j stop`
    `rm -r ~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_3/data/graph.db/*`
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_3/bin/neo4j start`
  end

  def preload_neo4j (neo4j)
    neo4j.create_node_index(:knows)
    neo4j.create_node_index(:shadows)
    a = neo4j.create_real_node({:title => "a", :sahip => "atakan"})
    v = neo4j.create_real_node({:title => "v", :sahip => "volkan"})


    neo4j.create_unique_relationship(:knows, a.global_id, v.global_id, :knows, a, v)
  end

  def logger
    @logger ||= Logger.new(STDOUT)
    @logger.level=Logger::INFO
    @logger
  end

end