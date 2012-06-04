require "test/unit"
require '../redis_connector'

class RedisConnectorTest < Test::Unit::TestCase

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
  end

  def teardown
    # Do nothing
  end

  def test_remove_partition_holding
    gid = 1
    partition = 2
    @redis_connector.add_to_partition_list_for_node(gid, partition)
    array = @redis_connector.partitions_have_the_node(gid)
    assert(array.count == 1)

    @redis_connector.remove_partition_holding_real(gid)
    array = @redis_connector.partitions_have_the_node(gid)
    assert(array.count == 0)
  end

end