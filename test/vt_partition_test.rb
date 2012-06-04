require "test/unit"
require '../vt_partition'
require '../redis_connector'

class VtPartition < Test::Unit::TestCase

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
    @redis_connector = RedisConnector.new(:host => 'localhost', :port => 7379)
    @redis_connector.remove_all

    reset_neo3

    @neo_test = VTPartition.new({:protocol => 'http://',
                     :server => 'localhost',
                     :port => 9474,
                     :directory => '',  # use '/<my directory>' or leave out for default
                     :authentication => '', # 'basic', 'digest' or leave out for default
                     :username => '', #leave out for default
                     :password => '',  #leave out for default
                     :log_file => STDOUT,
                     :log_enabled => true,
                     :max_threads => 20}, {:host => 'localhost', :port => 7379})


    preload_neo4j(@neo_test)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_shadow_node
    @neo_test.shadow_node(1)
    n1 = @neo_test.get_indexed_node(1)

    assert_equal(true, n1["data"]["shadow"], "Failed to make node shadow")
  end

  def reset_neo3
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_3/bin/neo4j stop`
    `rm -r ~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_3/data/graph.db/*`
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_3/bin/neo4j start`
  end

  def preload_neo4j (neo4j)
    neo4j.create_node_index(:knows)
    a = neo4j.create_real_node({:title => "a", :sahip => "atakan"})
    v = neo4j.create_real_node({:title => "v", :sahip => "volkan"})


    neo4j.create_unique_relationship(:knows, a.global_id, v.global_id, :knows, a, v)
  end

end