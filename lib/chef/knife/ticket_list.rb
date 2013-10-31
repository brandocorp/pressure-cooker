require 'chef/knife'

class Chef
  class Knife
    class TicketList < Knife

      deps do
        require 'jiralicious'
        require 'chef/knife/core/jira_context'
        # @todo this needs to be more automatic/programatic
        Jiralicious.load_yml(File.expand_path(ENV['HOME'] + "/.jira/jira.yml"))
      end

      banner 'knife ticket list [PROJECT] (options)'

      def run
        project = @name_args[0] || 'CHEF'
        issues = Jiralicious.search("project = #{project} AND resolution = Unresolved AND assignee = #{Jiralicious.username} ORDER BY priority DESC").issues_raw
        issue_hash = {}
        issues.each do |issue|
          issue_hash.store("#{issue['key']}", { 'status' => issue['fields']['status']['name'], 'summary' => issue['fields']['summary']})
        end
        ui.presenter.text_format(issue_hash)
      end

      # def msg_pair(label, value, color=:cyan)
      #   if value && !value.to_s.empty?
      #     puts "#{ui.color(label, color)}: #{value}"
      #   end
      # end

    end
  end
end
