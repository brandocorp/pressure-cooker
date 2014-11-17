require 'chef/cookbook_loader'
require 'chef/cookbook/metadata'
require 'chef/knife'
require 'mixlib/shellout'
require 'pressure_cooker/utils/jira'
require 'pressure_cooker/utils/git'
require 'pressure_cooker/config'
require 'pressure_cooker/utils/bamboo'

class PressureCooker
  class Cooker
    module CookbookBase

      def self.included(includer)
        includer.class_eval do

          option :message,
            :short => "-m",
            :long => "--message",
            :description => "Add an optional message to the issue operation",
            :boolean => true

        end
      end

      # ===============================
      #   Common Setup
      # ===============================
      def common_setup
        PressureCooker::Config.from_file("#{ENV['HOME']}/.cooker/config.rb")
        @config = PressureCooker::Config.merge!(config)

        # Cookbok Setup
        # -------------------
        @cookbook_name = validate_param(@name_args[0], "a cookbook name")
        @cookbook_path = @config[:stash][:dir]
        @cookbook_source = @config[:stash][:url] +
          "/" + @config[:stash][:cookbook_project] + "/#{@cookbook_name}.git"

        # JIRA Setup
        # -------------------
        @issue_key = validate_param(@name_args[1], "the issue key")
        begin
          @issue = Jira::API::Issue.new(
            @config[:jira][:username],
            @config[:jira][:password],
            @config[:jira][:url]
          )
          @issue.get(@issue_key)
        rescue Jiralicious::IssueNotFound
          ui.fatal "Issue #{@issue_key} is invalid!"
          exit 1
        end

        # Misc.
        # -------------------
        @editor = ENV['EDITOR'] || "vim"
        @user_message = ""

      end

      # ===============================
      #   Metatdata Manipulation
      # ===============================
      def find_metadata_file(cookbook_name, local_path)
        Array(local_path).reverse.each do |path|
          file = File.expand_path(File.join(path, cookbook_name, 'metadata.rb'))
          if File.exists?(file)
            ui.info "Using metadata file: #{file}"
            return file
          else
            ui.stderr.puts "ERROR: The cookbook metadata for '#{cookbook_name}' is missing or invalid."
            exit 1
          end
        end
      end

      def generate_metadata(metadata_file)
        metadata = Chef::Cookbook::Metadata.new
        metadata.from_file(metadata_file)
        metadata
      end

      def next_version(issuetype, version)
        puts "Issue Type: " + issuetype
        major, minor, patch = version.split('.')
        case issuetype
        when 1, "1" #Bug
          ui.info("Incrementing patch level...")
          patch.succ!
        when 4, "4" #Improvement
          ui.info("Incrementing minor version...")
          minor.succ!
          patch = "0"
        when 39, "39" #User Story
          ui.info("Incrementing major version...")
          major.succ!
          minor = "0"
          patch = "0"
        else
          ui.error("Jira issue isn't a Bug, Feature or User Story!")
          ui.info("Incrementing patch level...")
          patch.succ!
        end
        "#{major}.#{minor}.#{patch}"
      end

      def set_environment_cookbook_version(environment, cookbook_name, cookbook_version)
        chef_environment = Chef::Environment.load(environment)
        if chef_environment.cookbook_versions[cookbook_name] == "<= #{cookbook_version}"
          ui.info("Cookbook is up to date for #{environment}")
        else
          chef_environment.cookbook_versions[cookbook_name] = "<= #{cookbook_version}"
          chef_environment.save
        end
      end

      # ===============================
      #   JIRA Helpers
      # ===============================
      def issue_advance
        @issue.status.advance
        @issue.reload
      end

      def issue_retreat
        @issue.status.retreat
        @issue.reload
      end

      # ===============================
      #   Command Helpers
      # ===============================
      def run_command(cmd, opts = {})
        shell = Mixlib::ShellOut.new(cmd, opts)
        shell.run_command
        shell.error!
        shell
      end

      # ===============================
      #   Generic Helper Methods
      # ===============================
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

      def render_changelog(current_changes = {}, previous_changes)
        ERB.new(<<-EOT.gsub(/^\ +/, ""), 0, "<>").result binding
          # apol_cheftest Cookbook CHANGELOG

          This file is used to list changes made in each version of the apol_cheftest cookbook.

          ---

          <% current_changes["versions"].each do |version,info| %>
            ## <%= version %>

            <% info.each do |type,ticket| %>
              ### <%= type %>

              <% ticket.each do |id,desc| %>
                - [<%= id %>](https://jira.apollogrp.edu/browse/<%= id %>) - <%= desc %>
              <% end %>

            <% end %>
          <% end %>

          <%= previous_changes %>
        EOT
      end

    end
  end
end
