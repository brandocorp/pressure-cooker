require 'jiralicious'
# @todo This needs to be changed to use OAuth,
# which might mean changing the gem to ruby-jira
Jiralicious.load_yml(File.expand_path(ENV['HOME'] + "/.jira/jira.yml"))

class Jira
  # Namespace for our API calls
  class API
    # Extracts the data we need from Jiralicious::Issue objects
    class Issue

      attr_accessor :assignee, :comments, :status
      attr_reader   :description, :key, :project, :status_id, :state, :summary

      def initialize(key)
        get(key)
        parse
      end

      def get(key)
        @api = Jiralicious::Issue.find(key)
      end

      def parse
        @key         = @api.jira_key
        @project     = @api['fields']['project']['key']
        @username    = @api['fields']['assignee']['name'] rescue ""
        @assignee    = @api['fields']['assignee']['displayName'] rescue "Unassigned"
        @summary     = @api['fields']['summary']
        @description = @api['fields']['description']
        @status      = @api['fields']['status']['name']
        @status_id   = @api['fields']['status']['id']
        @state       = Jira::API::State.new(@key, @status_id)
        @comments    = @api['fields']['comment']['comments'].map {|c| {:author => c['author']['displayName'], :timestamp => c['created'], :comment => c['body']}}
      end

      def reload
        @api.reload
        parse
      end

      def comment(msg)
        @api.comments.add msg
      end

      def assign(user)
        @api.set_assignee user
      end

      def unassign
        @api.set_assignee '-1'
      end

    end

    class State

      STATE_PIPELINE = {
        "10040" => {
          "name" => "New",
          "next" => "11",
          "previous" => "101",
          "abandon" => "101"
        },
        "10030" => {
          "name" => "In Development",
          "next" => "21",
          "previous" => "81",
          "abandon" => "111"
        },
        "10101" => {
          "name" => "QA Review",
          "next" => "31",
          "previous" => "41",
          "abandon" => "121"
        },
        "10001" => {
          "name" => "In QA",
          "next" => "51",
          "previous" => "91",
          "abandon" => "131"
        },
        "10102" => {
          "name" => "Ready for Production",
          "next" => "61",
          "previous" => "71",
          "abandon" => "141"
        }
      }

      attr_reader :current
      attr_reader :options

      def initialize(key, status_id)
        @key = key
        @current = status_id
        states = get(key)
        parse(states)
      end

      def get(key)
        Jiralicious::Issue::Transitions.find(key)
      end

      def parse(states)
        # removes the jira_key from object
        # => ["jira_key", "CHEF-371"]
        states.shift

        # build a hash objects containing the state id, and it's friendly name
        # => {"31"=>"Reviewed - Approved", "41"=>"Reviewed - Rejected", "121"=>"Abandon"}
        @options = Hash[states.map {|id,data| [ data.id, data.name ] }]
      end

      def next_state
        STATE_PIPELINE[@current]['next']
      end

      def previous_state
        STATE_PIPELINE[@current]['previous']
      end

      def abandon_state
        STATE_PIPELINE[@current]['abandon']
      end

      def advance
        id = next_state
        Jiralicious::Issue::Transitions.go(@key, id, {})
      end

      def retreat
        id = previous_state
        Jiralicious::Issue::Transitions.go(@key, id, {})
      end

      def abandon
        id = abandon_state
        Jiralicious::Issue::Transitions.go(@key, id, {})
      end
    end
  end
end
