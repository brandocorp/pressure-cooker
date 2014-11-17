require 'bamboo-client'
require 'pressure_cooker/utils/key_chain'

module Bamboo
  class API
    class Rest

      attr_reader :project, :plan

      def initialize(username, password, uri)
        @api = Bamboo::Client.for(:rest, uri)
        if RbConfig::CONFIG['host_os'] =~ /darwin/
          password = get_keychain_password(username, uri[/https?:\/\/(.*)\/?/, 1]).strip
        end
        begin
          @api.login(username, password)
        rescue => e
          ui.info "Error: Unable to authenticate with Bamboo"
          exit 1
        end
      end

      def get_branch_plan(cookbook_name, branch)
        # set the main plan key value so we can get all build results later on
        plan_key = "CHEFCB-#{cookbook_name.upcase.gsub(/[^A-Z]/, '')}"
        branch_key = plan_key + "/branch/#{branch}"
        @api.plan_for(branch_key)
      end

      def latest_build(plan_key)
        @api.results_for(plan_key).first
      end

      def get_keychain_password(account, server)
        KeyChain.find_internet_password(account, server)
      end

      def reload_plan(plan_key)
        @api.plan_for(plan_key)
      end

    end
  end
end
