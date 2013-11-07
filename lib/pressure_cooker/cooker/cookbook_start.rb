class PressureCooker
  class Cooker
    class CookbookStart < Cooker

      banner 'cooker cookbook start COOKBOOK TICKET (options)'

      deps do
        require 'git'
        require 'pressure_cooker/config'
        require 'pressure_cooker/utils/jira'
        require 'chef/cookbook_loader'
        require 'chef/cookbook/metadata'
        require 'chef/knife'
      end

      def run
        # Chef / Stash Cookbook Variables
        PressureCooker::Config.from_file("#{ENV['HOME']}/.cooker/config.rb")
        PressureCooker::Config.merge!(config)
        @cookbook_name   = validate_param(@name_args[0], "a cookbook name")
        @cookbook_path   = PressureCooker::Config[:stash_dir]
        @cookbook_source = PressureCooker::Config[:stash_url] +
                           "/" + PressureCooker::Config[:cookbook_project] + "/#{@cookbook_name}.git"
        @checkout_path   = @cookbook_path + "/" + @cookbook_name

        # JIRA Variables
        @issue_key = validate_param(@name_args[1], "the issue key")
        begin
          @issue = Jira::API::Issue.new(@issue_key)
        rescue Jiralicious::IssueNotFound
          ui.fatal "Issue #{@issue_key} is invalid!"
          exit 1
        end

        # Assigne JIRA, and transition to In Development
        update_ticket

        # Get the cookbook source from Stash
        checkout_source

        # Create and/or switch our new branch
        create_branch
      end

      def validate_param(param, desc)
        if param.nil? || param.empty?
          show_usage
          ui.error "You must provide #{desc}."
          exit 1
        end
        param
      end

      # ===============================
      #   Step 1
      # ===============================
      # Updates the assignee and advances the ticket-state
      # This expects that a ticket is in New status
      def update_ticket
        if @issue.status.name == "New"
          @issue.assign PressureCooker::Config[:jira_username]
          @issue.status.advance
          @issue.comment "Claiming ticket and starting work."
        elsif @issue.username == PressureCooker::Config[:jira_username] and @issue.status.name == "In Development"
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
      def checkout_source
        if ::File.exists?(@checkout_path)
          ui.info "Found existing local repo..."
          @git = open_repo
        else
          begin
            @git = clone_repo
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
      # @todo compare development/master to see if the version
      # has already been incremented
      def create_branch
        ui.info "Checking for existing branch..."
        unless @git.branches.collect {|branch| branch.name }.include? @issue_key
          ui.info "Creating new branch: #{@issue_key}"
          @git.branch(@issue_key).checkout
          update_version
          @git.commit_all("Creating new branch for #{@issue_key}")
          @git.push(@git.remote, @issue_key)
          @issue.comment("Created new branch: #{@issue_key}")
        else
          ui.info "Using existing branch: #{@issue_key}"
          @git.checkout(@issue_key)
        end
      end

      # ===============================
      #   Step 4
      # ===============================
      # Update the cookbook version based upon the
      # ticket's issuetype
      def update_version
        # Get current cookbook metadata from file
        @cookbook_metadata = generate_metadata(@cookbook_name)
        increment_metadata_version
      end

      # Generate our updated version number and write it to file
      def increment_metadata_version
        new_version = determine_version(@issue.issuetype, @cookbook_metadata.version)
        content = File.read(@metadata_file)
        version_line = /version\s+\"\d+\.\d+\.\d+\"/.match(content)[0]
        ui.info "Current " + version_line
        replacement = version_line.gsub(/\d+\.\d+\.\d+/, new_version)
        ui.info "Updated " + replacement
        File.open(@metadata_file, 'w+') do |f|
          f.write content.sub(/#{version_line}/, replacement)
        end
      end

      def open_repo
        ui.info "Using existing local repo..."
        Git.open(@checkout_path)
      end

      def clone_repo
        ui.info "Cloning repo..."
        Git.clone(@cookbook_source, @cookbook_name, :path => @cookbook_path)
      end

      def branch_repo
        ui.info "Creating #{@cookbook_name} branch #{@issue_key}..."
        @git.branch(@issue_key).checkout
      end

      def init_repo
        ui.info "Creating new repo..."
        Git.init(@checkout_path)
      end

      def knife_cookbook_create
        ui.info "Adding cookbook skeleton"
        Chef::Knife.run(["cookbook", "create", @cookbook_name, "-o", @cookbook_path])
      end

      def generate_metadata(cookbook)
        ui.info "Loading metadata for cookbook: #{cookbook}"
        metadata = Chef::Cookbook::Metadata.new
        metadata.from_file(metadata_file)
        metadata
      end

      def metadata_file
        @metadata_file ||= find_metadata_file
      end

      def find_metadata_file
        Array(@cookbook_path).reverse.each do |path|
          file = File.expand_path(File.join(path, @cookbook_name, 'metadata.rb'))
          if File.exists?(file)
            ui.info "Using metadata file: #{file}"
            return file
          else
            ui.stderr.puts "ERROR: The cookbook metadata for '#{@cookbook_name}' is missing or invalid."
            exit 1
          end
        end
      end

      def determine_version(issuetype, version)
        major, minor, patch = version.split('.')
        case issuetype
        when 1 #Bug
          ui.info("Incrementing patch level...")
          patch.succ!
        when 4 #Improvement
          ui.info("Incrementing minor version...")
          minor.succ!
          patch = "0"
        when 39 #User Story
          ui.info("Incrementing major version...")
          major.succ!
          minor = "0"
          patch = "0"
        else
          ui.error("Jira ticket isn't a Bug, Feature or User Story!")
          ui.info("Incrementing patch level...")
          patch.succ!
        end
        "#{major}.#{minor}.#{patch}"
      end

    end
  end
end
