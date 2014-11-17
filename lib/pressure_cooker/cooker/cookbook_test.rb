require 'pressure_cooker/cooker/cookbook_base'

class PressureCooker
  class Cooker
    class CookbookTest < Cooker

      include PressureCooker::Cooker::CookbookBase

      banner 'cooker cookbook test COOKBOOK'

      deps do
        require 'pressure_cooker/utils/bamboo'
      end

      def run
        common_setup
        @bamboo = Bamboo::API::Rest.new(
          @config[:bamboo][:username],
          @config[:bamboo][:password],
          @config[:bamboo][:url]
        )

        case @issue.status.name
        when "In Development", "QA Review"
          true
        else
          raise StandardError, "Issue #{@issue_key} is in an invalid state: #{@issue.status.name}"
        end

        ui.info("Getting Bamboo plan information...")
        @branch = @bamboo.get_branch_plan(@cookbook_name, @issue_key)

        run_ci_build
        @build_result = wait_for_finish(@branch.key)
        ui.info "Build #{@build_result}!"
        if @build_result == :successful
          upload_cookbook(@cookbook_name, @cookbook_path)
          update_environment("development", @cookbook_name, @cookbook_path)
          update_issue("In QA")
        end
      end

      # ===============================
      #   Step 1
      # ===============================
      # Run the bamboo plan for this cookbook and branch
      #
      def run_ci_build
        # Get the number of the last build
        @last_build = @branch.results.first.number
        ui.info("Last Build: #{@last_build}")

        # Queue a new build
        ui.info("Requesting new build for branch #{@issue_key}")
        @branch.queue
        sleep 3

        loop do
          # Reload our branch plan and get the build number
          @branch = @bamboo.reload_plan(@branch.key)
          @this_build = @branch.results.first

          # fail if the last and current are still the same number
          if @last_build == @this_build.number
            #raise StandardError, "A new build failed to be triggered."
            next
          else
            ui.info "Waiting for build #{@this_build.number} to complete..."
            break
          end

        end

      end

      def wait_for_finish(branch_key)
        state = String.new
        (1..60).each do
          sleep 1
          build = @bamboo.reload_plan(branch_key).results.first
          state = build.state
          case state
          when :failed
            ui.fatal "Build failed!"
            raise StandardError, "Bamboo build reported a failure"
          when :unknown
            ui.debug build.life_cycle_state
            next
          when :successful
            ui.info "Build completed successfully!"
            break
          end
        end
        state
      end

      def upload_cookbook(cookbook_name, local_path)
        ui.info "Uploading Cookbook"
        cmd = "knife cookbook upload #{cookbook_name} -o #{local_path}"
        shell = Mixlib::ShellOut.new(cmd)
        shell.run_command
        shell.error!
        ui.info shell.stdout.strip
      end

      def update_environment(environment, cookbook_name, local_path)
        metadata_file = find_metadata_file(cookbook_name, local_path)
        cookbook_metadata = generate_metadata(metadata_file)
        ui.info "Updating Development: #{cookbook_name}@#{cookbook_metadata.version}"
        set_environment_cookbook_version(environment, cookbook_name, cookbook_metadata.version)
      end

      def update_issue(required_state)
        loop do
          status = @issue.status.name
          if status != required_state
            ui.info("Moving #{@issue.key} from '#{status}' to next state")
            issue_advance
            next
          else
            ui.info("Ticket #{@issue.key} updated successfully to status #{@issue.status.name}")
            break
          end
        end
      end

    end
  end
end
