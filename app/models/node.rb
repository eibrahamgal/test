class Node < ApplicationRecord
    serialize :log, Array
    serialize :neighbors, Array
  
    after_initialize :initialize_state
  
    # Initializes the state of the node
    def initialize_state
      self.state ||= 0
      self.log ||= []
      self.neighbors ||= []
    end
  
    # Add a neighboring node
    def add_neighbor(node)
      self.neighbors << node.identifier
      save
    end
  
    # Propose a new state and initiate the consensus process
    def propose_state(new_state)
      self.state = new_state
      log_message("Node #{identifier} proposes state #{new_state}")
      send_message_to_neighbors(new_state)
      save
    end
  
    # Simulate sending message to neighbors
    def send_message_to_neighbors(proposed_state)
      neighbors.each do |neighbor_id|
        neighbor = Node.find_by(identifier: neighbor_id)
        next unless neighbor
  
        neighbor.receive_message(proposed_state)
      end
    end
  
    # Receive a message from a neighboring node
    def receive_message(message)
        if message[:state] > self.state
          self.state = message[:state]
          log_message("Node #{self.identifier} adopts state #{self.state}")
        end
    end
  
    # Simulate network partition by removing certain neighbors
    def simulate_partition(partitioned_nodes)
      self.neighbors -= partitioned_nodes.map(&:identifier)
      save
    end
  
    # Log message with timestamp
    def log_message(message)
      # Store timestamp as an ISO8601 string
      self.log << { timestamp: Time.now.iso8601, message: message }
      save
    end
  
    # Retrieve the log
    def retrieve_log
      log
    end
  end
  