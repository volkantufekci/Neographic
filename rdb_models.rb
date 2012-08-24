require 'data_mapper'

DataMapper::Logger.new($stdout, :info)
DataMapper.setup(:default, 'mysql://neographic:Elma12345@localhost/neographic')

class Node
  include DataMapper::Resource

  property :id,        Serial
  property :gid,       Integer
  property :lid,       Integer
  property :partition, String

  has n, :node_properties
end

class NodeProperty
  include DataMapper::Resource

  property :id,     Serial
  property :name,   String
  property :value,  String
  property :z_type, String # prefix "z_" is used not to conflict with a db's potential keyword 'type'

  belongs_to :node
end

class Relation
  include DataMapper::Resource

  property :id,         Serial
  property :start,      Integer
  property :end,        Integer
  property :z_type,     String # prefix "z_" is used not to conflict with a db's potential keyword 'type'
  property :partition,  String

  has n, :relation_properties
end

class RelationProperty
  include DataMapper::Resource

  property :id,     Serial
  property :name,   String
  property :value,  String
  property :z_type, String # prefix "z_" is used not to conflict with a db's potential keyword 'type'

  belongs_to :relation
end