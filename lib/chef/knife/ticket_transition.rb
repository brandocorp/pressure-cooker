require 'chef/knife'
require 'highline/import'

class Chef
  class Knife
    class TicketTransition < Knife

      deps do
        require 'chef/knife/api/jira'
      end

      option :message,
        :short => "-m",
        :long => "--message",
        :description => "Add an optional message to the ticket operation",
        :boolean => true

      banner 'knife ticket transition TICKET (options)'

      def run
        @id = nil
        @message = nil
        @key = @name_args[0]
        if @key.nil?
          show_usage
          ui.fatal("You must provide a ticket")
          exit 1
        end
        # Get the ticket's transitional states
        allowed_transitions = {}
        transitions = Jiralicious::Issue::Transitions.find("CHEF-371")
        transitions.shift

        while t = transitions.shift
          allowed_transitions[t[1]['id']] = t[1]['name']
        end
        # => {"21"=>"Send for QA Review", "81"=>"Stop Development Work", "111"=>"Abandon"}

        query_new_state(allowed_transitions)
        query_comment if config[:message]
        Jiralicious::Issue::Transitions.go("CHEF-371", @id, @message ? {:comment => "#{@message}"} : {})

        ui.info("\nTicket #{@key} updated successfully.\n")

      end

      def query_comment
        @message = ask("\nPlease enter your comments:")
      end

      def query_new_state(options)
        choose do |menu|
          menu.header = "\nAvailable State Transitions"
          menu.prompt = "\nPlease select an option"
          options.each do |id,name|
            menu.choice name do
              @id = id
            end
          end
        end
      end

    end
  end
end
