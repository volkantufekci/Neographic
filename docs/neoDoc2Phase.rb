Neography::Node.create("age" => 31, "name" => "Max")                 # Create a node with some properties
Neography::Node.create(@neo2, {"age" => 31, "name" => "Max"})        # Create a node on the server defined in @neo2

Neography::Node.load(5)                                              # Get a node and its properties by id
Neography::Node.load(existing_node)                                  # Get a node and its properties by Node
Neography::Node.load("http://localhost:7474/db/data/node/2")         # Get a node and its properties by String

Neography::Node.load(@neo2, 5)                                       # Get a node on the server defined in @neo2

n1 = Node.create
n1.del                                                               # Deletes the node
n1.exist?                                                            # returns true/false if node exists in Neo4j

n1 = Node.create("age" => 31, "name" => "Max")
n1[:age] #returns 31                                                 # Get a node property using [:key]
n1.name  #returns "Max"                                              # Get a node property as a method
n1[:age] = 24                                                        # Set a node property using [:key] =
n1.name = "Alex"                                                     # Set a node property as a method
n1[:hair] = "black"                                                  # Add a node property using [:key] =
n1.weight = 190                                                      # Add a node property as a method
n1[:name] = nil                                                      # Delete a node property using [:key] = nil
n1.name = nil                                                        # Delete a node property by setting it to nil

n2 = Neography::Node.create
new_rel = Neography::Relationship.create(:family, n1, n2)            # Create a relationship from my_node to node2
new_rel.start_node                                                   # Get the start/from node of a relationship
new_rel.end_node                                                     # Get the end/to node of a relationship
new_rel.other_node(n2)                                               # Get the other node of a relationship
new_rel.attributes                                                   # Get the attributes of the relationship as an array

existing_rel = Neography::Relationship.load(12)                      # Get an existing relationship by id
existing_rel.del                                                     # Delete a relationship

Neography::Relationship.create(:friends, n1, n2)
n1.outgoing(:friends) << n2                                          # Create outgoing relationship
n1.incoming(:friends) << n2                                          # Create incoming relationship
n1.both(:friends) << n2                                              # Create both relationships

n1.outgoing                                                          # Get nodes related by outgoing relationships
n1.incoming                                                          # Get nodes related by incoming relationships
n1.both                                                              # Get nodes related by any relationships

n1.outgoing(:friends)                                                # Get nodes related by outgoing friends relationship
n1.incoming(:friends)                                                # Get nodes related by incoming friends relationship
n1.both(:friends)                                                    # Get nodes related by friends relationship

n1.outgoing(:friends).incoming(:enemies)                             # Get nodes related by one of multiple relationships
n1.outgoing(:friends).depth(2)                                       # Get nodes related by friends and friends of friends
n1.outgoing(:friends).depth(:all)                                    # Get nodes related by friends until the end of the graph
n1.outgoing(:friends).depth(2).include_start_node                    # Get n1 and nodes related by friends and friends of friends

n1.outgoing(:friends).prune("position.endNode().getProperty('name') == 'Tom';")
n1.outgoing(:friends).filter("position.length() == 2;")

n1.rel?(:friends)                                                    # Has a friends relationship
n1.rel?(:outgoing, :friends)                                         # Has outgoing friends relationship
n1.rel?(:friends, :outgoing)                                         # same, just the other way
n1.rel?(:outgoing)                                                   # Has any outgoing relationships
n1.rel?(:both)                                                       # Has any relationships
n1.rel?(:all)                                                        # same as above
n1.rel?                                                              # same as above

n1.rels                                                              # Get node relationships
n1.rels(:friends)                                                    # Get friends relationships
n1.rels(:friends).outgoing                                           # Get outgoing friends relationships
n1.rels(:friends).incoming                                           # Get incoming friends relationships
n1.rels(:friends,:work)                                              # Get friends and work relationships
n1.rels(:friends,:work).outgoing                                     # Get outgoing friends and work relationships

n1.all_paths_to(n2).incoming(:friends).depth(4)                      # Gets all paths of a specified type
n1.all_simple_paths_to(n2).incoming(:friends).depth(4)               # for the relationships defined
n1.all_shortest_paths_to(n2).incoming(:friends).depth(4)             # at a maximum depth
n1.path_to(n2).incoming(:friends).depth(4)                           # Same as above, but just one path.
n1.simple_path_to(n2).incoming(:friends).depth(4)
n1.shortest_path_to(n2).incoming(:friends).depth(4)

n1.shortest_path_to(n2).incoming(:friends).depth(4).rels             # Gets just relationships in path
n1.shortest_path_to(n2).incoming(:friends).depth(4).nodes            # Gets just nodes in path
