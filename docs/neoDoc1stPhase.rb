@neo.get_root                                              # Get the root node
@neo.create_node                                           # Create an empty node
@neo.create_node("age" => 31, "name" => "Max")             # Create a node with some properties
@neo.create_unique_node(index_name, key, unique_value,     # Create a unique node
                       {"age" => 31, "name" => "Max"})     # this needs an existing index

@neo.get_node(node2)                                       # Get a node and its properties
@neo.delete_node(node2)                                    # Delete an unrelated node
@neo.delete_node!(node2)                                   # Delete a node and all its relationships

@neo.reset_node_properties(node1, {"age" => 31})           # Reset a node's properties
@neo.set_node_properties(node1, {"weight" => 200})         # Set a node's properties
@neo.get_node_properties(node1)                            # Get just the node properties
@neo.get_node_properties(node1, ["weight","age"])          # Get some of the node properties
@neo.remove_node_properties(node1)                         # Remove all properties of a node
@neo.remove_node_properties(node1, "weight")               # Remove one property of a node
@neo.remove_node_properties(node1, ["weight","age"])       # Remove multiple properties of a node

@neo.create_relationship("friends", node1, node2)          # Create a relationship between node1 and node2
@neo.create_unique_relationship(index_name, key, value,    # Create a unique relationship between nodes
                        "friends", new_node1, new_node2)   # this needs an existing index

@neo.get_relationship(rel1)                                # Get a relationship
@neo.get_node_relationships(node1)                         # Get all relationships
@neo.get_node_relationships(node1, "in")                   # Get only incoming relationships
@neo.get_node_relationships(node1, "all", "enemies")       # Get all relationships of type enemies
@neo.get_node_relationships(node1, "in", "enemies")        # Get only incoming relationships of type enemies
@neo.delete_relationship(rel1)                             # Delete a relationship

@neo.reset_relationship_properties(rel1, {"age" => 31})    # Reset a relationship's properties
@neo.set_relationship_properties(rel1, {"weight" => 200})  # Set a relationship's properties
@neo.get_relationship_properties(rel1)                     # Get just the relationship properties
@neo.get_relationship_properties(rel1, ["since","met"])    # Get some of the relationship properties
@neo.remove_relationship_properties(rel1)                  # Remove all properties of a relationship
@neo.remove_relationship_properties(rel1, "since")         # Remove one property of a relationship
@neo.remove_relationship_properties(rel1, ["since","met"]) # Remove multiple properties of a relationship

@neo.list_node_indexes                                     # gives names and query templates for all defined indices
@neo.create_node_index(name, type, provider)               # creates an index, defaults are "exact" and "lucene"
@neo.add_node_to_index(index, key, value, node1)           # adds a node to the index with the given key/value pair
@neo.remove_node_from_index(index, key, value, node1)      # removes a node from the index with the given key/value pair
@neo.remove_node_from_index(index, key, node1)             # removes a node from the index with the given key
@neo.remove_node_from_index(index, node1)                  # removes a node from the index
@neo.get_node_index(index, key, value)                     # exact query of the node index with the given key/value pair
@neo.find_node_index(index, key, value)                    # advanced query of the node index with the given key/value pair
@neo.find_node_index(index, query )                        # advanced query of the node index with the given query
@neo.list_relationship_indexes                             # gives names and query templates for relationship indices
@neo.create_relationship_index(name, "fulltext", provider) # creates a relationship index with "fulltext" option
@neo.add_relationship_to_index(index, key, value, rel1)    # adds a relationship to the index with the given key/value pair
@neo.remove_relationship_from_index(index, key, value, rel1) # removes a relationship from the index with the given key/value pair
@neo.remove_relationship_from_index(index, key, rel1)      # removes a relationship from the index with the given key
@neo.remove_relationship_from_index(index, rel1)           # removes a relationship from the index
@neo.get_relationship_index(index, key, value)             # exact query of the relationship index with the given key/value pair
@neo.find_relationship_index(index, key, value)            # advanced query of the relationship index with the given key/value pair
@neo.find_relationship_index(index, query)                 # advanced query of the relationship index with the given query
@neo.execute_script("g.v(0)")                              # sends a Groovy script (through the Gremlin plugin)
@neo.execute_script("g.v(id)", {:id => 3})                 # sends a parameterized Groovy script (optimized for repeated calls)
@neo.execute_query("start n=node(0) return n")             # sends a Cypher query (through the Cypher plugin)
@neo.execute_query("start n=node(id) return n", {:id => 3}) # sends a parameterized Cypher query (optimized for repeated calls)

@neo.get_path(node1, node2, relationships, depth=4, algorithm="shortestPath") # finds the shortest path between two nodes
@neo.get_paths(node1, node2, relationships, depth=3, algorithm="allPaths")    # finds all paths between two nodes
@neo.get_shortest_weighted_path(node1, node2, relationships,   # find the shortest path between two nodes
                                weight_attr='weight', depth=2, # accounting for weight in the relationships
                                algorithm='dijkstra')          # using 'weight' as the attribute

nodes = @neo.traverse(node1,                                              # the node where the traversal starts
                      "nodes",                                            # return_type "nodes", "relationships" or "paths"
                      {"order" => "breadth first",                        # "breadth first" or "depth first" traversal order
                       "uniqueness" => "node global",                     # See Uniqueness in API documentation for options.
                       "relationships" => [{"type"=> "roommates",         # A hash containg a description of the traversal
                                            "direction" => "all"},        # two relationships.
                                           {"type"=> "friends",           #
                                            "direction" => "out"}],       #
                       "prune evaluator" => {"language" => "javascript",  # A prune evaluator (when to stop traversing)
                                             "body" => "position.endNode().getProperty('age') < 21;"},
                       "return filter" => {"language" => "builtin",       # "all" or "all but start node"
                                           "name" => "all"},
                       "depth" => 4})

# "depth" is a short-hand way of specifying a prune evaluator which prunes after a certain depth.
# If not specified a depth of 1 is used and if a "prune evaluator" is specified instead of a depth, no depth limit is set.

@neo.batch [:get_node, node1], [:get_node, node2]                        # Gets two nodes in a batch
@neo.batch [:create_node, {"name" => "Max"}],
           [:create_node, {"name" => "Marc"}]                            # Creates two nodes in a batch
@neo.batch [:set_node_property, node1, {"name" => "Tom"}],
           [:set_node_property, node2, {"name" => "Jerry"}]              # Sets the property of two nodes
@neo.batch [:create_unique_node, index_name, key, value,
             {"age" => 33, "name" => "Max"}]                             # Creates a unique node
@neo.batch [:get_node_relationships, node1, "out",
           [:get_node_relationships, node2, "out"]                       # Get node relationships in a batch
@neo.batch [:get_relationship, rel1],
           [:get_relationship, rel2]                                     # Gets two relationships in a batch
@neo.batch [:create_relationship, "friends",
             node1, node2, {:since => "high school"}],
           [:create_relationship, "friends",
             node1, node3, {:since => "college"}]                        # Creates two relationships in a batch
@neo.batch [:create_unique_relationship, index_name,
             key, value, "friends", node1, node2]                        # Creates a unique relationship
@neo.batch [:get_node_index, index_name, key, value]                     # Get node index
@neo.batch [:get_relationship_index, index_name, key, value]             # Get relationship index

@neo.batch [:create_node, {"name" => "Max"}],
           [:create_node, {"name" => "Marc"}],                           # Creates two nodes and index them
           [:add_node_to_index, "test_node_index", key, value, "{0}"],
           [:add_node_to_index, "test_node_index", key, value, "{1}"],
           [:create_relationship, "friends",                             # and create a relationship for those
             "{0}", "{1}", {:since => "college"}],                       # newly created nodes
           [:add_relationship_to_index,
             "test_relationship_index", key, value, "{4}"]               # and index the new relationship

@neo.batch *[[:create_node, {"name" => "Max"}],
             [:create_node, {"name" => "Marc"}]]                         # Use the Splat (*) with Arrays of Arrays
