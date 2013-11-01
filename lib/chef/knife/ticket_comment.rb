require 'chef/knife'

class Chef
  class Knife
    class TicketComment < Knife

      deps do
        require 'chef/knife/api/jira'
      end

      banner 'knife ticket comment TICKET (options)'

      def run
        @key = @name_args[0]
        if @key.nil?
          show_usage
          ui.fatal("You must provide a ticket")
          exit 1
        end
        @ticket = Jira::API::Issue.new(@key)
        @ticket.comment "#{query_comment}"
        ui.info("Your comment has been added to #{@key}")
      end

      def query_comment
        ask("\nPlease enter your comments:")
      end
    end
  end
end
