class Node < ApplicationRecord
  serialize :log, Array
  serialize :neighbors, Array
  
  after_initialize :initialize_state
  
  attr_accessor :role, :term, :votes, :leader_id
  
  # Initialize the state of the node
  def initialize_state
    self.state ||= 0
    self.log ||= []
    self.neighbors ||= []
    @term ||= 0
    @votes ||= 0
    @role ||= :follower # Nodes start as followers
    @leader_id = nil
  end
  
  # Add a neighboring node
  def add_neighbor(node)
    self.neighbors << node.identifier
    save
  end
  
  # Start a new election if node is a candidate
  def start_election
    @term += 1
    @role = :candidate
    @votes = 1 # Vote for self
    log_message("Node #{identifier} starts election for term #{@term}")
    
    neighbors.each do |neighbor_id|
      neighbor = Node.find_by(identifier: neighbor_id)
      next unless neighbor
      
      neighbor.request_vote(self)
    end
  end
  
  # Request vote from a neighbor
  def request_vote(candidate)
    if candidate.term > @term
      @term = candidate.term
      @role = :follower
      log_message("Node #{identifier} votes for Node #{candidate.identifier} in term #{@term}")
      candidate.receive_vote
    else
      log_message("Node #{identifier} rejects vote for Node #{candidate.identifier}")
    end
  end
  
  # Receive a vote from another node
  def receive_vote
    @votes += 1
    log_message("Node #{identifier} receives a vote, now has #{@votes} votes")
    
    if @votes > (neighbors.size / 2)
      become_leader
    end
  end
  
  # Become the leader for the current term
  def become_leader
    @role = :leader
    @leader_id = self.identifier
    log_message("Node #{identifier} becomes leader for term #{@term}")
    
    send_heartbeat
  end
  
  # Send heartbeat to all followers to maintain leadership
  def send_heartbeat
    log_message("Node #{identifier} (Leader) sends heartbeat")
    
    neighbors.each do |neighbor_id|
      neighbor = Node.find_by(identifier: neighbor_id)
      next unless neighbor
      neighbor.receive_heartbeat(self)
    end
  end
  
  # Receive heartbeat from leader
  def receive_heartbeat(leader)
    if leader.term >= @term
      @term = leader.term
      @role = :follower
      @leader_id = leader.identifier
      log_message("Node #{identifier} acknowledges heartbeat from Leader #{leader.identifier}")
    else
      log_message("Node #{identifier} rejects outdated heartbeat from Leader #{leader.identifier}")
    end
  end
  
  # Propose a new state (only the leader can propose)
  def propose_state(new_state)
    if @role == :leader
      self.state = new_state
      log_message("Leader Node #{identifier} proposes state #{new_state}")
      replicate_log(new_state)
      save
    else
      log_message("Node #{identifier} is not a leader, cannot propose state")
    end
  end
  
  # Replicate log to followers
  def replicate_log(new_state)
    neighbors.each do |neighbor_id|
      neighbor = Node.find_by(identifier: neighbor_id)
      next unless neighbor
      neighbor.append_log_entry(new_state, self)
    end
  end
  
  # Append log entry on follower node
  def append_log_entry(new_state, leader)
    if leader.term >= @term
      self.state = new_state
      log_message("Node #{identifier} appends log entry state #{new_state} from Leader #{leader.identifier}")
      save
    else
      log_message("Node #{identifier} rejects log entry from outdated Leader #{leader.identifier}")
    end
  end
  
  # Log message with timestamp
  def log_message(message)
    self.log << { timestamp: Time.now.iso8601, message: message }
    save
  end
  
  # Retrieve the log
  def retrieve_log
    log
  end
end
