require "test/unit"
require_relative "../gpart_controller"

class GpartControllerTest < Test::Unit::TestCase

  require 'minitest/reporters'
  MiniTest::Unit.runner = MiniTest::SuiteRunner.new
  if ENV["RM_INFO"] || ENV["TEAMCITY_VERSION"]
    MiniTest::Unit.runner.reporters << MiniTest::Reporters::RubyMineReporter.new
  elsif ENV['TM_PID']
    MiniTest::Unit.runner.reporters << MiniTest::Reporters::RubyMateReporter.new
  else
    MiniTest::Unit.runner.reporters << MiniTest::Reporters::ProgressReporter.new
  end

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @gpc = GpartController.new
  end

  def test_map_gids_to_gpart_indexes
    logger.debug("TEST_MAP_GIDS_TO_GPART_INDEXES STARTED")

    gid_nei_hash = {1=>[2, 3], 2=>[1, 3, 4, 5], 3=>[1, 2, 5, 7, 8], 4=>[2], 5=>[2, 3, 6], 6=>[5], 7=>[3], 8=>[3]}
    actual = @gpc.map_gids_to_gpart_indexes(gid_nei_hash)
    expected = [1, 2, 3, 4, 5, 6, 7, 8]
    assert_equal(expected, actual, "#{actual} does not match #{expected}")

    gid_nei_hash = {3=>[1, 2, 5, 7, 8], 4=>[2], 1=>[2, 3], 2=>[1, 3, 4, 5], 5=>[2, 3, 6], 6=>[5], 7=>[3], 8=>[3]}
    actual = @gpc.map_gids_to_gpart_indexes(gid_nei_hash)
    expected = [3, 4, 1, 2, 5, 6, 7, 8]
    assert_equal(expected, actual, "#{actual} does not match #{expected}")
  end

  def test_build_grf_file
    logger.debug("TEST_BUILD_GRF_FILE STARTED")

    gid_nei_hash = {1=>[2, 3], 2=>[1, 3, 4, 5], 3=>[1, 2, 5, 7, 8], 4=>[2], 5=>[2, 3, 6], 6=>[5], 7=>[3], 8=>[3]}
    @gpc.map_gids_to_gpart_indexes(gid_nei_hash)
    actual = @gpc.build_grf_file(gid_nei_hash.values)

    lines = "\n2\t1\t2\n4\t0\t2\t3\t4\n5\t0\t1\t4\t6\t7\n1\t1\n3\t1\t2\t5\n1\t4\n1\t2\n1\t2"
    expected = "0\n" << "8\t" << "18\n" << "0\t000" << lines

    assert(expected.eql?(actual), "exp: #{expected} act: #{actual} does not match")
  end

  def logger
    @logger ||= Logger.new(STDOUT)
    @logger.level=Logger::DEBUG
    @logger
  end
end