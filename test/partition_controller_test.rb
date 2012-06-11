require "test/unit"
require_relative '../partition_controller'
require '../redis_connector'
require '../gpart_controller'

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

    @gpart_controller = GpartController.new

  end

  def teardown
    # Do nothing
  end

  #def test_migrate_node_to_partition
  #  migrate_node_to_partition()
  #
  #  migrate_relations()
  #
  #  n1_migrated = @pc.neo1.get_indexed_node(1)
  #  assert_not_nil(n1_migrated, "Node with gid:1 is not migrated!!!")
  #
  #  shadow_nodes()
  #end
  #
  #def test_migrate_relations
  #  migrate_node_to_partition
  #  migrate_relations
  #end

  #def test_shadow_nodes
  #  logger.info("TEST_SHADOW_NODES STARTED")
  #
  #  migrate_nodes_to_partition
  #  migrate_relations
  #  n1_migrated = @pc.neo1.get_indexed_node(1)
  #  assert_not_nil(n1_migrated, "Node with gid:1 is not migrated!!!")
  #
  #  shadow_nodes
  #
  #  n8_migrated = @pc.neo2.get_indexed_node(8)
  #  result = n8_migrated["data"]["shadow"]
  #  assert(result, "n8 should have been shadow but #{result}")
  #end

  #def test_remove_alone_shadows
  #  logger.info("TEST_REMOVE_ALONE_SHADOWS STARTED")
  #
  #  migrate_nodes_to_partition
  #  migrate_relations
  #  shadow_nodes
  #
  #  migrated_nodes = Array.new
  #  migrated_nodes << Neography::Node.load(@pc.neo2, 1)
  #  migrated_nodes << Neography::Node.load(@pc.neo2, 3)
  #  migrated_nodes << Neography::Node.load(@pc.neo2, 7)
  #  migrated_nodes << Neography::Node.load(@pc.neo2, 8)
  #
  #  migrated_nodes.each { |node| @pc.del_rels_to_shadows_for_node(node) }
  #
  #
  #  n1=Neography::Node.load(@pc.neo2, 1)
  #  n3=Neography::Node.load(@pc.neo2, 3)
  #  n7=Neography::Node.load(@pc.neo2, 7)
  #  n8=Neography::Node.load(@pc.neo2, 8)
  #  migrated_nodes = Array.new
  #  migrated_nodes << n1 << n3 << n7 << n8
  #
  #  migrated_nodes.each { |node|
  #    unless @pc.has_any_relation?(node)
  #      node.del
  #    end
  #  }
  #
  #  assert(n1.exist?, "Node with gid=1 should exist!")
  #  assert(n3.exist?, "Node with gid=3 should exist!")
  #
  #  assert(!n7.exist?, "Node with gid=7 should not exist!")
  #  assert(!n8.exist?, "Node with gid=8 should not exist!")
  #end

  def test_migrate_via_gpart_mapping
    logger.info("TEST_MIGRATE_VIA_GPART_MAPPING STARTED")

    gpart_mapping = @gpart_controller.perform_gpart_mapping
    before_mapping_hash = @gpart_controller.before_mapping_hash

    @pc.migrate_via_gpart_mapping gpart_mapping, before_mapping_hash

    migrated_nodes = Array.new
    migrated_nodes << Neography::Node.load(@pc.neo2, 1)
    migrated_nodes << Neography::Node.load(@pc.neo2, 3)
    migrated_nodes << Neography::Node.load(@pc.neo2, 7)
    migrated_nodes << Neography::Node.load(@pc.neo2, 8)

    migrated_nodes.each { |node| @pc.del_rels_to_shadows_for_node(node) }


    n1=Neography::Node.load(@pc.neo2, 1)
    n3=Neography::Node.load(@pc.neo2, 3)
    n7=Neography::Node.load(@pc.neo2, 7)
    n8=Neography::Node.load(@pc.neo2, 8)
    migrated_nodes = Array.new
    migrated_nodes << n1 << n3 << n7 << n8

    migrated_nodes.each { |node|
      unless @pc.has_any_relation?(node)
        node.del
      end
    }

    assert(n1.exist?, "Node with gid=1 should exist!")
    assert(n3.exist?, "Node with gid=3 should exist!")

    assert(!n7.exist?, "Node with gid=7 should not exist!")
    assert(!n8.exist?, "Node with gid=8 should not exist!")

  end


  ### END OF TESTS - BEGINNING OF HELPER METHODS

  def shadow_nodes
    @pc.neo2.mark_as_shadow(1)
    @pc.neo2.mark_as_shadow(3)
    @pc.neo2.mark_as_shadow(7)
    @pc.neo2.mark_as_shadow(8)
  end

  def migrate_relations
    @pc.migrate_relations_of_node(1, @pc.neo2, @pc.neo1, :both)
    @pc.migrate_relations_of_node(3, @pc.neo2, @pc.neo1, :both)
    @pc.migrate_relations_of_node(7, @pc.neo2, @pc.neo1, :both)
    @pc.migrate_relations_of_node(8, @pc.neo2, @pc.neo1, :both)
  end

  def migrate_nodes_to_partition
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 1), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 3), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 7), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 8), 7474)
  end

  def reset_neo1
    logger.info("neo1 is being reset. VT")
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_1/bin/neo4j stop`
    `rm -r ~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_1/data/graph.db/*`
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_1/bin/neo4j start`
  end

  def reset_neo2
    logger.info("neo2 is being reset. VT")
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_2/bin/neo4j stop`
    `rm -r ~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_2/data/graph.db/*`
    `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_2/bin/neo4j start`
  end

  def logger
    @logger ||= Logger.new(STDOUT)
    @logger.level=Logger::INFO
    @logger
  end

end