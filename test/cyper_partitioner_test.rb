require "test/unit"
require "../cypher_partitioner"

class CypherPartitionerTest < Test::Unit::TestCase

  require 'minitest/reporters'
  MiniTest::Unit.runner = MiniTest::SuiteRunner.new
  MiniTest::Unit.runner.reporters << MiniTest::Reporters::RubyMineReporter.new

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @cypher_partition = CypherPartitioner.new
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_read_partition_mapping
    mapping = @cypher_partition.read_partition_mapping
    assert(mapping.size > 0, "there is no line in the file")

    assert(mapping[1].kind_of? 1.class)
  end

  def test_inject_partition_ports
    mapping = {555 => 0, 666 => 1, 777 => 0, 888 => 3}
    injected_mapping = @cypher_partition.inject_partition_ports(mapping)
    assert(injected_mapping[555] == 6474, "expected: 6474, actual: #{injected_mapping[555]}")
    assert(injected_mapping[666] == 7474, "wrong port injection")
    assert(injected_mapping[777] == 6474, "wrong port injection")
    assert(injected_mapping[888] == 9474, "wrong port injection")
  end
end