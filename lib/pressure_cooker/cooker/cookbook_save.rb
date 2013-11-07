# cooker cookbook save CHEF-999
#   - commit and push changes to branch
#   - log commit message to CHEF-999 comments
#   * post to CI to upload cookbook and environment

class PressureCooker
  class Cooker
    class CookbookSave < Cooker

      banner 'cooker cookbook save COOKBOOK [TICKET] (options)'

      deps do
        require 'git'
        require 'pressure_cooker/config'
        require 'pressure_cooker/utils/jira'
      end

      option :message,
        :short => "-m",
        :long => "--message",
        :description => "Add an optional message to the ticket operation",
        :boolean => true

      def run
        PressureCooker::Config.from_file("#{ENV['HOME']}/.cooker/config.rb")
        PressureCooker::Config.merge!(config)
        @cookbook_name = validate_param(@name_args[0], "a cookbook name")
        @cookbook_path = PressureCooker::Config[:stash_dir]
        @checkout_path = @cookbook_path + "/" + @cookbook_name
        @git = Git.open(@checkout_path)
        @editor = ENV['EDITOR'] || nil
        @issue_key = validate_param(@name_args[1], "the issue key")
        begin
          @issue = Jira::API::Issue.new(@issue_key)
        rescue Jiralicious::IssueNotFound
          ui.fatal "Issue #{@issue_key} is invalid!"
          exit 1
        end

        if config[:message]
          get_user_message
        end

        # Commit all local changes to the repo
        #  - Add untracked files
        #  - Commit everything
        commit_changes
        add_comment
        run_ci_build

      end

      # ===============================
      #   Step 1
      # ===============================
      # Commit all local changes and push them to Stash
      def commit_changes
        @message = []
        untracked = @git.status.untracked
        added = @git.status.added
        untracked.merge(added).each do |key,file|
          msg = "added #{file.path}"
          ui.info msg
          @message << msg
          @git.add file.path
        end
        @git.status.changed.each do |key,file|
          @message << "modified #{file.path}"
        end
        @git.status.deleted.each do |key,file|
          msg = "deleted #{file.path}"
          ui.info msg
          @git.remove file.path
        end
        ui.info "Commiting changes..."
        begin
          @git.commit_all(@user_message ? @user_message : "changes for #{@issue_key}")
          ui.info "Pushing changes to repo..."
          @git.push(@git.remote, @issue_key)
        rescue Git::GitExecuteError => e
          ui.info e.message.split(':').last
          exit 1
        end
      end

      # ===============================
      #   Step 2
      # ===============================
      # Add a comment to the JIRA Issue
      def add_comment
        @issue.comment @user_message ? @user_message : @message.join("\n")
      end

      # ===============================
      #   Step 3
      # ===============================
      #
      def run_ci_build
        ui.info "TODO: Setup CI Build to:\n - pull in cookbook source\n - upload to chef server\n - modify environment file"
      end

      def git_status
        status = String.new
        @git.status.each do |file|
          if file.type != nil
            status << "\n\n\n\n# ========================================\n"
            status << "#     Git Status Information\n"
            status << "# ========================================\n"
            status << "# #{file.type}\t\t#{file.path}\n"
            @git.diff('HEAD', file.path).to_s.each_line do |line|
              status << "# " + line
            end
          end
        end
        status
      end

      def get_user_message
        require 'tempfile'
        file = Tempfile.new("commit.tmp")
        file.write git_status
        file.fsync
        file.close
        `#{@editor} #{file.path}`
        @user_message = file.open.read.gsub(/^#?$|#.*$/, '').strip
      end

      def validate_param(param, desc)
        if param.nil? || param.empty?
          show_usage
          ui.error "You must provide #{desc}."
          exit 1
        end
        param
      end

    end
  end
end
