require 'chef/knife'
require 'jiralicious'

class Chef
  class Knife
    class TicketList < Knife

      deps do
        require 'chef/knife/api/jira'
      end

      banner 'knife ticket list [PROJECT] (options)'

      def run
        project = @name_args[0] || 'CHEF'
        issues = Jiralicious.search("project = #{project} AND resolution = Unresolved AND assignee = #{Jiralicious.username} ORDER BY priority DESC").issues_raw
        issue_hash = {}
        issues.each do |issue|
          issue_hash.store("#{issue['key']}", { 'status' => issue['fields']['status']['name'], 'summary' => issue['fields']['summary']})
        end
        ui.output({"total"=>issues.length})
        ui.output(issue_hash)
      end

    end
  end
end
