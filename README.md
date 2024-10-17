# README

# Distributed System Simulation

This project simulates a distributed system where nodes reach consensus on a shared state using a simple consensus algorithm. The system handles network partitions and node failures gracefully.

## Setup

1. Clone the repository.
2. Run `bundle install`.
3. change database.yml with database configurations.
4. Run `rails db:migrate` to set up the database.

## Running the Simulation

Run the Rails console to interact with the nodes and simulate different scenarios.

```bash
rails console


to run test do bundle exec rspec

to run the code run rails c and:

    node1 = Node.create(identifier: 1)
    node2 = Node.create(identifier: 2)
    node3 = Node.create(identifier: 3)

    node1.add_neighbor(node2)
    node1.add_neighbor(node3)
    node2.add_neighbor(node1)
    node2.add_neighbor(node3)
    node3.add_neighbor(node1)
    node3.add_neighbor(node2)

    node1.propose_state(1)
    node2.propose_state(2)
    node3.simulate_partition([node1])
    node2.propose_state(3)

    puts node1.retrieve_log
    puts node2.retrieve_log
    puts node3.retrieve_log


