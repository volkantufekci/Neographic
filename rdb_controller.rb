require_relative "configuration"
require_relative "rdb_models"

DataMapper.finalize
DataMapper.auto_migrate!

class RDBController
  puts "baslangic: #{Time.now}"

  i = -1
  File.open(Configuration::NODES_CSV, 'r') do |input|
    while (line = input.gets)
      #break if i < 0
      i += 1
      next if i == 0
      splitted_token = line.chomp.split("\t")
      tokens = []
      splitted_token.each { |token|
        tokens << token
      }
      node = Node.create(:gid => tokens[0])
      node_property = NodeProperty.create(:name => "rels", :value => tokens[1], :z_type => "int")
      node.node_properties << node_property
      node.save
      #node.node_properties.create(:name => "rels", :value => tokens[1], :z_type => "int")
    end
  end

  i = -1
  File.open(Configuration::RELS_CSV, 'r') do |input|
    while (line = input.gets)
      i += 1
      next if i == 0
      splitted_token = line.chomp.split("\t")
      tokens = []
      splitted_token.each { |token|
        tokens << token
      }

      relation = Relation.create(:start => tokens[0], :end => tokens[1], :z_type => tokens[2])
      rel_property = RelationProperty.create(:name => "rels", :value => tokens[4], :z_type => "String")
      relation.relation_properties << rel_property
      relation.save
    end
  end

  puts "bitis: #{Time.now}"
end