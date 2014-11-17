class PressureCooker
  class Cooker
    class CookbookSpecs < Cooker

      banner 'cooker cookbook specs COOKBOOK'

      deps do
        require 'chef/knife'
      end

      def run
        # Chef / Stash Cookbook Variables
        PressureCooker::Config.from_file("#{ENV['HOME']}/.cooker/config.rb")
        @config = PressureCooker::Config.merge!(config)
        @cookbook_name = validate_param(@name_args[0], "a cookbook name")
        @cookbook_path = @config[:stash][:dir]
        @checkout_path = @cookbook_path + "/" + @cookbook_name

        run_specs

      end

      def run_specs
        ui.info "Testing cookbook with Rspec"
        cmd = "rspec"
        shell = Mixlib::ShellOut.new(cmd, :cwd => @checkout_path)
        shell.run_command
        shell.error!
        ui.info shell.stdout.strip
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
