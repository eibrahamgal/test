require 'rails_helper'

RSpec.describe Node, type: :model do
  let(:node1) { Node.create(identifier: 1) }
  let(:node2) { Node.create(identifier: 2) }
  let(:node3) { Node.create(identifier: 3) }

  before do
    node1.add_neighbor(node2)
    node1.add_neighbor(node3)
    node2.add_neighbor(node1)
    node2.add_neighbor(node3)
    node3.add_neighbor(node1)
    node3.add_neighbor(node2)
  end

  describe 'Propose State' do
    it 'allows a node to propose a state and logs it' do
      node1.propose_state(1)
      expect(node1.state).to eq(1)
      expect(node1.log.last[:message]).to include('Node 1 proposes state 1')
    end
  end

  describe 'Message Passing and Consensus' do
    it 'reaches consensus on the highest state proposed' do
      node1.propose_state(1)
      node2.propose_state(2)

      expect(node1.state).to eq(2) # Node 1 should adopt the higher state from Node 2
      expect(node1.log.last[:message]).to include('Node 1 adopts state 2')
    end

    it 'proposes and adopts a new state after partition is restored' do
      node1.propose_state(1)
      node2.propose_state(2)
      node3.simulate_partition([node1]) # Partition node3 from node1

      node2.propose_state(3)
      expect(node1.state).to eq(3) # Node 1 should adopt the highest state from Node 2
    end
  end

  describe 'Network Partition' do
    it 'prevents communication during a partition' do
      node3.simulate_partition([node1])

      node1.propose_state(1)
      node2.propose_state(2)

      # Node 3 should not adopt any states since it's partitioned
      expect(node3.state).to eq(0) # Default state
      expect(node3.log).to be_empty
    end
  end

  describe 'Node Failures' do
    it 'handles node failures gracefully' do
      allow(node3).to receive(:receive_message).and_raise('Node failure') # Simulate failure

      node1.propose_state(1)
      node2.propose_state(2)

      expect { node1.propose_state(3) }.not_to raise_error # Node failure shouldn't crash the system
      expect(node1.state).to eq(3)
    end
  end

  describe 'Logging' do
    it 'logs state transitions and messages' do
      node1.propose_state(1)
      expect(node1.log.last[:message]).to include('Node 1 proposes state 1')

      node2.propose_state(2)
      expect(node2.log.last[:message]).to include('Node 2 proposes state 2')
    end

    it 'retrieves log for analysis' do
      node1.propose_state(1)
      expect(node1.retrieve_log).to be_an(Array)
      expect(node1.retrieve_log.last[:message]).to include('Node 1 proposes state 1')
    end
  end
end
