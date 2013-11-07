require 'jiralicious'
require 'pressure_cooker/utils/key_chain'

class Jira
  # Namespace for our API calls
  class API
    # Extracts the data we need from Jiralicious::Issue objects
    class Issue

      attr_accessor :assignee, :comments, :status, :issuetype, :username
      attr_reader   :description, :key, :project, :status_id, :state, :summary

      # Creates a new Issue object
      # @param [string] the JIRA issue key
      def initialize(key)
        configure(
          PressureCooker::Config[:jira_username],
          PressureCooker::Config[:jira_password],
          PressureCooker::Config[:jira_url]
        )
        get(key)
        parse
      end

      # Gets an issue object from the api
      def get(key)

        @api = Jiralicious::Issue.find(key)
      end

      # Extract the relevant data from the issue's api data
      def parse
        @key          = @api.jira_key
        @project      = @api['fields']['project']['key']
        @username     = @api['fields']['assignee']['name'] rescue ""
        @assignee     = @api['fields']['assignee']['displayName'] rescue "Unassigned"
        @summary      = @api['fields']['summary']
        @description  = @api['fields']['description']
        @issuetype    = @api['fields']['issuetype']['id']
        @status       = Jira::API::Status.new(@key,  @api['fields']['status']['id'])
        @comments     = parse_comments(@api['fields']['comment']['comments'])
      end

      # Parses the comments for an issue into a hash.
      # @param [Hash] a Jiralicious::Issue::Comment object
      # @return [Hash] the comments arranged in a hash with the author,
      # timestamp and the body of the comment
      def parse_comments(comments)
        comments.map do |c|
          {
            :author => c['author']['displayName'],
            :timestamp => c['created'],
            :comment => c['body']
          }
        end
      end

      # Reload the current data for this issue from JIRA
      def reload
        @api.reload
        parse
      end

      # Add a comment to the issue
      def comment(msg)
        @api.comments.add msg
      end

      # Assign the issue to a specific user
      def assign(user)
        @api.set_assignee user
      end

      # Set the assignee to unassigned
      def unassign
        @api.set_assignee '-1'
      end

      def configure(username, password, uri)
        Jiralicious.username = username
        if Config::CONFIG['host_os'] =~ /darwin/
          Jiralicious.password = get_keychain_password(username, uri[/https?:\/\/(.*)\/?/, 1]).strip
        else
          Jiralicious.password = password
        end
        Jiralicious.uri = uri
      end

      def get_keychain_password(account, server)
        KeyChain.find_internet_password(account, server)
      end

    end

    # Creates an object to represent the current state
    class Status

      STATUS_PIPELINE = {
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

      attr_reader :id, :name, :options, :next, :previous, :abandon

      def initialize(key, id)
        @key = key
        @id = id
        @name = STATUS_PIPELINE[@id]['name']
        @next = STATUS_PIPELINE[@id]['next']
        @previous = STATUS_PIPELINE[@id]['previous']
        @abandon = STATUS_PIPELINE[@id]['abandon']
        states = get(key)
        parse(states)
      end

      # Gets the transitions object for a specified issue
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

      # Transition a ticket to its next workflow status
      # New -> Start Development -> In Development
      # In Development -> Send for QA Review -> QA Review
      # QA Review -> Review - Approved -> In QA
      # In QA -> QA Complete -> Ready for Production
      # Ready for Production -> Deployed to Production -> Closed
      def advance
        Jiralicious::Issue::Transitions.go(@key, @next, {})
      end

      # Transition a ticket to its previous workflow status.
      # In Development -> Stop Development Work -> New
      # QA Review -> Review Rejected -> In Development
      # In QA -> QA Failed -> In Development
      # Ready for Production -> Failed in Production -> In QA
      def retreat
        Jiralicious::Issue::Transitions.go(@key, @previous, {})
      end

      # Transition a ticket via Abandon to Closed status.
      def abandon
        Jiralicious::Issue::Transitions.go(@key, @abandon, {})
      end
    end
  end
end
