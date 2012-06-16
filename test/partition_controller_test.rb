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
    self.reset_neo(0)
    self.reset_neo(1)
    self.reset_neo(2)
    @pc = Tez::PartitionController.new
    preload_neo4j(@pc.neo4j_instances[6474])
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

  def test_migrate_via_gpart_for2
    logger.info("TEST_MIGRATE_VIA_GPART_MAPPING STARTED")

    gid_nei_h = @pc.merge_node_neighbour_hashes
    before_mapping_hash = @pc.before_mapping_hash(gid_nei_h.keys)

    @gpc = GpartController.new(gid_nei_h, 2)
    gpart_mapping_hash = @gpc.partition_and_return_mapping

    migrated_nodes = @pc.migrate_via_gpart_mapping gpart_mapping_hash, before_mapping_hash

    #n1=Neography::Node.load(@pc.neo4j_instances[6474], 1)
    n1=@pc.neo4j_instances[6474].get_indexed_node(1)
    n3=@pc.neo4j_instances[6474].get_indexed_node(3)
    n7=@pc.neo4j_instances[6474].get_indexed_node(7)
    n8=@pc.neo4j_instances[6474].get_indexed_node(8)

    assert(n1, "Node with gid=1 should exist!")
    assert(n3, "Node with gid=3 should exist!")

    assert(!n7, "Node with gid=7 should not exist!")
    assert(!n8, "Node with gid=8 should not exist!")

  end

  def test_migrate_via_gpart_for3
    logger.info("TEST_MIGRATE_VIA_GPART_MAPPING STARTED")

    gid_nei_h = @pc.merge_node_neighbour_hashes
    before_mapping_hash = @pc.before_mapping_hash(gid_nei_h.keys)

    @gpc = GpartController.new(gid_nei_h, 3)
    gpart_mapping_hash = @gpc.partition_and_return_mapping

    migrated_nodes = @pc.migrate_via_gpart_mapping gpart_mapping_hash, before_mapping_hash

    #n1=Neography::Node.load(@pc.neo4j_instances[6474], 1)
    n1=@pc.neo4j_instances[7474].get_indexed_node(1)
    n3=@pc.neo4j_instances[8474].get_indexed_node(3)
    n7=@pc.neo4j_instances[6474].get_indexed_node(7)
    n8=@pc.neo4j_instances[6474].get_indexed_node(8)

    assert(n1, "Node with gid=1 should exist!")
    assert(n3, "Node with gid=3 should exist!")

    assert(!n7, "Node with gid=7 should not exist!")
    assert(!n8, "Node with gid=8 should not exist!")

  end

  #def test_merge_node_nei_hashes
  #  logger.info("TEST_MERGE_NODE_NEIG_HASHES STARTED")
  #
  #  actual = @pc.merge_node_neighbour_hashes
  #  expected = {1=>[2, 3], 2=>[1, 3, 4, 5], 3=>[1, 2, 5, 7, 8], 4=>[2], 5=>[2, 3, 6], 6=>[5], 7=>[3], 8=>[3]}
  #  assert_equal(expected, actual, "neighbour hash is not correct!")
  #  logger.debug("actual:   #{actual} \n expected: #{expected}")
  #end

  ### END OF TESTS - BEGINNING OF HELPER METHODS

  def preload_neo4j (neo4j)
    a = neo4j.create_real_node({:title => "a"})
    b = neo4j.create_real_node({:title => "b"})
    c = neo4j.create_real_node({:title => "c"})
    d = neo4j.create_real_node({:title => "d"})
    e = neo4j.create_real_node({:title => "e"})
    f = neo4j.create_real_node({:title => "f"})
    g = neo4j.create_real_node({:title => "g"})
    h = neo4j.create_real_node({:title => "h"})
    #Relationships
    neo4j.create_node_index(:knows)
    neo4j.create_node_index(:shadows)
    #Neography::Relationship.create(:knows, a, b)
    neo4j.create_unique_relationship(:knows, a.global_id, b.global_id, :knows, a, b)
    neo4j.create_unique_relationship(:knows, a.global_id, c.global_id, :knows, a, c)
    neo4j.create_unique_relationship(:knows, b.global_id, c.global_id, :knows, b, c)
    neo4j.create_unique_relationship(:knows, b.global_id, d.global_id, :knows, b, d)
    neo4j.create_unique_relationship(:knows, b.global_id, e.global_id, :knows, b, e)
    neo4j.create_unique_relationship(:knows, c.global_id, e.global_id, :knows, c, e)
    neo4j.create_unique_relationship(:knows, c.global_id, g.global_id, :knows, c, g)
    neo4j.create_unique_relationship(:knows, c.global_id, h.global_id, :knows, c, h)
    neo4j.create_unique_relationship(:knows, e.global_id, f.global_id, :knows, e, f)
  end

  def shadow_nodes
    @pc.neo2.mark_as_shadow(1)
    @pc.neo2.mark_as_shadow(3)
    @pc.neo2.mark_as_shadow(7)
    @pc.neo2.mark_as_shadow(8)
  end

  def migrate_relations
    #migrate_relations_of_node is moved into relation_controller
    @pc.rel_controller.migrate_relations_of_node(1, @pc.neo2, @pc.neo1, :both)
    @pc.rel_controller.migrate_relations_of_node(3, @pc.neo2, @pc.neo1, :both)
    @pc.rel_controller.migrate_relations_of_node(7, @pc.neo2, @pc.neo1, :both)
    @pc.rel_controller.migrate_relations_of_node(8, @pc.neo2, @pc.neo1, :both)
  end

  def migrate_nodes_to_partition
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 1), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 3), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 7), 7474)
    @pc.migrate_node_to_partition(Neography::Node.load(@pc.neo2, 8), 7474)
  end

  def reset_neo2(instance_no)
    if [0, 1, 2].include? instance_no
      logger.info("neo#{instance_no} is being reset. VT")
      `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_#{instance_no}/bin/neo4j stop`
      `rm -r ~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_#{instance_no}/data/graph.db/*`
      `~/Development/tez/Neo4jSurumleri/neo4j-community-1.7_#{instance_no}/bin/neo4j start`
    else
      logger.error("There is no neo instance with no: #{instance_no}. VT")
    end

  end


  def reset_neo(instance_no)
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