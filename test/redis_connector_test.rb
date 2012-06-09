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
    test_port = 7379
    @redis_connector = RedisConnector.new(:host => 'localhost', :port => test_port)
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

  def test_update_partition_list
    gid = 1
    old_partition_port = "222"
    @redis_connector.add_to_partition_list_for_node(gid, old_partition_port)
    array = @redis_connector.partitions_have_the_node(gid)
    assert(array.count == 1)

    expected_new_partition_port = "333"
    @redis_connector.update_partition_list_for_node(gid, expected_new_partition_port)
    actual_new_partition_port = @redis_connector.partitions_have_the_node(gid).first
    assert_equal(expected_new_partition_port, actual_new_partition_port,
                 "expected: #{expected_new_partition_port} but was #{actual_new_partition_port}")

  end

  def test_real_partition_of_node
    gid = "volkan"
    @redis_connector.add_to_partition_list_for_node(gid, "first")
    @redis_connector.add_to_partition_list_for_node(gid, "second")

    real_partition = @redis_connector.real_partition_of_node(gid)
    assert_equal("second", real_partition, "expected real partition was second but got #{real_partition}")
  end

end