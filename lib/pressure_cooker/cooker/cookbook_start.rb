require 'pressure_cooker/cooker/cookbook_base'

class PressureCooker
  class Cooker
    class CookbookStart < Cooker

      include PressureCooker::Cooker::CookbookBase
      include Git::API::Utils


      banner 'cooker cookbook start COOKBOOK TICKET (options)'

      def run

        common_setup
        update_ticket
        checkout_source(@cookbook_source, @cookbook_name, @cookbook_path)
        create_branch(@issue_key)

      end


      # ===============================
      #   Step 1
      # ===============================
      # Updates the assignee and advances the ticket-state
      # This expects that a ticket is in New status
      def update_ticket
        if @issue.status.name == "New"
          @issue.assign @config[:jira][:username]
          @issue.status.advance
          @issue.comment "Claiming ticket and starting work."
        elsif @issue.username == @config[:jira][:username] and @issue.status.name == "In Development"
          ui.info "Ticket is already assigned and in the correct state."
        else
          ui.error "Invalid Workflow State: #{@issue.key} is not currently in 'New' status."
          exit 1
        end
      end

      # ===============================
      #   Step 2
      # ===============================
      # Establishes a new, or uses an existing local copy
      # of the code. This expects the repo to already exist
      # in the project in Stash
      def checkout_source(git_url, name, local_path)
        checkout_path = "#{local_path}/#{name}"
        if ::File.exists?(checkout_path)
          ui.info "Found existing local repo..."
          @git = open_repo(checkout_path)
        else
          begin
            @git = clone_repo(git_url, name, local_path)
          rescue Git::GitExecuteError => e
            # @todo prompt the user to create a new repo
            if e.message.match(/does not exist/)
              ui.fatal "The repo doesn't appear to exist\nURL: #{@cookbook_source}"
              ui.info "-" * 30 + "\n" + e.message
              exit 1
            end
          end
        end
      end

      # ===============================
      #   Step 3
      # ===============================
      # Create or switch to our issue branch. If the branch
      # already exists, no version modification will be
      # run. Otherwise, we bump the version.
      #
      def create_branch(issue_key)
        ui.info "Checking for existing branch..."
        unless @git.branches.collect {|branch| branch.name }.include? issue_key

          #create the new branch
          branch_repo(issue_key)

          # create, update and write the new cookbook version
          increment_version(@issue.issuetype, @cookbook_name, @cookbook_path)

          # commit our changes and push
          @git.commit_all("Creating new branch for #{issue_key}")
          @git.push(@git.remote, issue_key)

          # add a comment to the issue
          @issue.comment("Created new branch: #{issue_key}")
        else
          ui.info "Using existing branch: #{issue_key}"
          @git.checkout(issue_key)
        end
      end

      # ===============================
      #   Step 4
      # ===============================
      # Update the cookbook version based upon the
      # ticket's issuetype
      def increment_version(issue_type, cookbook_name, local_path)
        # Get current cookbook metadata from file
        metadata_file = find_metadata_file(cookbook_name, local_path)
        cookbook_metadata = generate_metadata(metadata_file)
        find_and_update_version(issue_type, cookbook_metadata.version, metadata_file)
      end

      # Finds a list of issues tagged with cookbook@version, and
      # compiles them into the CHANGELOG.md file using an erb template
      #
      # @param [String] the name of the cookbook
      # @param [String] the cookbook version
      #
      def update_changelog(cookbook_name, cookbook_version)
        # get list of issues labeled as cookbook@verion
        # Jiralicious.search("labels in ('#{cookbook_name}','')"")
        # => { version => { issue.key => issue.description } }
        # content = File.read(changelog_file)
        # strip out the header and save the previous changelog
        # previous_changes = content.split("\n---\n\n", 2)[1]
        # render_changelog(current_changes, previous_changes)
      end

      # Generate our updated version number and write it to file
      def find_and_update_version(issue_type, metadata_version, metadata_file)
        # @todo This needs to be more advanced than it is. We sould be able
        # to track updates for a given version somehow so that not every
        # ticket is a one-to-one version bump. We can also use a changelog
        # JSON file to render a erb-type template of the CHANGELOG.md file.

        # @note run a diff on master and development. If development is ahead
        # of master, we should not increment again; just add our ticket info
        # to the change log json for this version and render the CHANGELOG.md
        # file again.
        updated_version = next_version(issue_type, metadata_version)
        content = File.read(metadata_file)
        version_line = /version\s+\"\d+\.\d+\.\d+\"/.match(content)[0]
        ui.info "Current " + version_line
        replacement = version_line.gsub(/\d+\.\d+\.\d+/, updated_version)
        ui.info "Updated " + replacement
        File.open(metadata_file, 'w+') do |f|
          f.write content.sub(/#{version_line}/, replacement)
        end
      end

      def branch_repo(issue_key)
        ui.info "Creating new branch: #{issue_key}"
        @git.checkout('master')
        origin = @git.log.first.sha[0..6]
        # This will not work currently due to a bug in JIRA
        #@issue.fields.append_a("labels", [origin])
        #@issue.save
        @git.branch('development').checkout
        @git.push
        @git.branch(issue_key).checkout
      end

      def knife_cookbook_create(cookbook_name, local_path)
        ui.info "Adding cookbook skeleton"
        Chef::Knife.run(["cookbook", "create", cookbook, "-o", local_path])
      end

    end
  end
end
