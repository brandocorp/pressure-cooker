require 'chef/knife'

class Chef
  class Knife
    class CookbookPromote < Knife

      deps do
        require 'chef/environment'
        require 'chef/json_compat'
      end

      banner "knife cookbook promote COOKBOOK VERSION [ENVIRONMENT] (options)"

      def run

        cookbook    = @name_args[0]
        version     = @name_args[1]
        environment = @name_args[2]

        if cookbook.nil? || version.nil?
          show_usage
          ui.fatal("You must specify a cookbook name and version")
          exit 1
        end

        if environment.nil?
          environment = determine_environment(cookbook, version)
        elsif environment != 'development'
          unless validate_environment_version(previous_environment(environment), cookbook, version)
            ui.fatal "Version was not found in the previous environment!"
            exit 1
          end
        end

        set_cookbook_version(environment, cookbook, version)

      end

      def get_cookbook_version(environment, cookbook)
        chef_environment = Chef::Environment.load(environment)
        chef_environment.cookbook_versions[cookbook]
      end

      def set_cookbook_version(environment, cookbook, version)
        chef_environment = Chef::Environment.load(environment)
        if chef_environment.cookbook_versions[cookbook] == "<= #{version}"
          ui.info("Cookbook is up to date for #{environment}")
        else
          chef_environment.cookbook_versions[cookbook] = "<= #{version}"
          chef_environment.save
        end
      end

      def environment_pipeline(environment, pipeline_step)
        env_mapping = {
          'development' => {'previous' => nil, 'next' => 'systemtest'},
          'systemtest'  => {'previous' => 'development', 'next' => 'production'},
          'production'  => {'previous' => 'systemtest', 'next' => nil}
        }
        env_mapping[environment][pipeline_step]
      end

      def next_environment(environment)
        environment_pipeline(environment, 'next')
      end

      def previous_environment(environment)
        environment_pipeline(environment, 'previous')
      end

      def determine_environment(cookbook, version)
        ['development', 'systemtest', 'production'].each do |env|
          return env unless validate_environment_version(env, cookbook, version)
        end
        ui.warn("Unable to promote #{cookbook}-#{version} in any environment!")
        exit
      end

      def validate_environment_version(environment, cookbook, version)
        # @todo ensure we do not promote a lesser version into an environment
        environment_version = get_cookbook_version(environment, cookbook)
        Chef::Log.debug "Found #{cookbook} #{environment_version} in #{environment}"
        if "<= #{version}" == environment_version
          return true
        else
          return false
        end
      end

    end
  end
end
