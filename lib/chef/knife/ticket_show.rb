require 'chef/knife'

class Chef
  class Knife
    class TicketShow < Knife

      deps do
        require 'chef/knife/api/jira'
      end

      banner 'knife ticket show TICKET (options)'

      def run
        @key = @name_args[0]

        if @key.nil?
          show_usage
          ui.fatal("You must provide a ticket")
          exit 1
        end

        ui.info("-" * 30)
        ui.info("    #{@key}")
        ui.info("-" * 30)
        @ticket = Jira::API::Issue.new(@key)
        ui.output({
          :assignee => @ticket.assignee,
          :summary => @ticket.summary,
          :description => @ticket.description,
          :status => @ticket.status
        })
        ui.info("\n")
        ui.info("-" * 30)
        ui.info("  Comments:")
        @ticket.comments.each_with_index do |comment, index|
          ui.info("-" * 30)
          ui.output("#{index + 1}" => comment)
        end
      end

    end
  end
end
