require 'chef/knife'

class Chef
  class Knife
    class TicketAdvance < Knife

      deps do
        require 'chef/knife/api/jira'
      end

      banner 'knife ticket advance TICKET (options)'

      def run
        @key = @name_args[0]
        if @key.nil?
          show_usage
          ui.fatal("You must provide a ticket")
          exit 1
        end
        @ticket = Jira::API::Issue.new(@key)
        #begin
          ui.info("Moving #{@key} from '#{@ticket.status}' to next state")
          @ticket.state.advance
          @ticket.reload
          ui.info("Ticket #{@key} updated successfully to status #{@ticket.status}")
        #rescue
        #  ui.fatal("Failed to update #{@key}!")
        #end
      end
    end
  end
end
