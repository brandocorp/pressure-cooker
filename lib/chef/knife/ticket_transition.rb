require 'chef/knife'

class Chef
  class Knife
    class TicketTransition < Knife



    end
  end
end

#######################
# Example Code
#######################

# Find a ticket
Jiralicious.load_yml(File.expand_path(ENV['HOME'] + "/.jira/jira.yml"))
ticket = Jiralicious::Issue.find("CHEF-371")

# Assign a ticket to a user
ticket.set_assignee Jiralicious.username

# Add a comment to a ticket
ticket.comments.add "Testing JIRA API"

# Get the ticket's transitional states
allowed_transitions = {}
transitions = Jiralicious::Issue::Transitions.find("CHEF-371")
transitions.shift #=> ["jira_key", "CHEF-371"]
while t = transitions.shift
  allowed_transitions[t[1]['id']] = t[1]['name']
end
# => {"21"=>"Send for QA Review", "81"=>"Stop Development Work", "111"=>"Abandon"}
