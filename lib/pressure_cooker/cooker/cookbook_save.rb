require 'pressure_cooker/cooker/cookbook_base'

class PressureCooker
  class Cooker
    class CookbookSave < Cooker

      include PressureCooker::Cooker::CookbookBase
      include Git::API::Utils

      banner 'cooker cookbook save COOKBOOK TICKET (options)'

      def run
        common_setup
        checkout_path = @cookbook_path + "/" + @cookbook_name
        @git = open_repo(checkout_path)
        determine_local_changes

        if @config[:message]
          get_user_message
        end

        commit_changes
      end

      # ===============================
      #   Step 1a
      # ===============================
      # Commit all local changes and push them to Stash
      #
      def commit_changes
        @message = "commiting changes for #{@issue_key}"
        begin
          ui.info "Commiting changes..."
          @git.commit_all(@user_message.empty? ? @message : @user_message)
        rescue Git::GitExecuteError => e
          error_message = e.message.split(':').last
          ui.info error_message
          unless error_message =~ /nothing to commit/
            exit 1
          end
        end
        push_changes
      end

      # ===============================
      #   Step 1b
      # ===============================
      # Push all local changes to Stash. If no local
      # changes are found this will be skipped.
      #
      def push_changes
        begin
          ui.info "Pushing changes to repo..."
          @git.push(@git.remote, @issue_key)
          add_comment
        rescue Git::GitExecuteError => e
          error_message = e.message.split(':').last
          ui.info error_message
          exit 1
        end
      end


      # ===============================
      #   Step 1c
      # ===============================
      # Add a comment to the JIRA Issue if there were
      # changes made to the repo.
      #
      def add_comment
        @issue.comment @user_message.empty? ? @message : @user_message
      end

      def determine_local_changes
        change_types = {
          :untracked => :add,
          :added => nil,
          :changed => nil,
          :deleted => :remove
        }
        change_types.each do |status,action|
          files = @git.status.send(status)
          files.each do |key,file|
            ui.info "#{file.type || "?"} #{file.path}"
            @git.send(action, file.path) if not action.nil? and File.exists? file.path
          end
          @git.add(:all=>true)
        end
      end

      def git_status
        status = String.new
        status << "\n\n\n\n# ========================================\n"
        status << "#     Git Status Information\n"
        status << "# ========================================\n"
        @git.status.each do |file|
          if file.type != nil and File.exists? file.path
            status << "# #{file.type}\t\t#{file.path}\n"
            @git.diff('HEAD', file.path).to_s.each_line do |line|
              status << "# " + line
            end
          end
        end
        status
      end

    end
  end
end
