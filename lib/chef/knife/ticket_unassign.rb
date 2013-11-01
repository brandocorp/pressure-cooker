require 'chef/knife'

class Chef
  class Knife
    class TicketUnassign < Knife

      deps do
        require 'chef/knife/api/jira'
      end

      banner 'knife ticket assign TICKET [USERNAME] (options)'

      def run
        @key = @name_args[0]
        @user = @name_args[1] || Jiralicious.username
        if @key.nil?
          show_usage
          ui.fatal("You must provide a ticket")
          exit 1
        end
        @ticket = Jira::API::Issue.new(@key)
        @ticket.set_assignee '-1'
        ui.info("Ticket #{@key} has been unassigned.")
      end

    end
  end
end
