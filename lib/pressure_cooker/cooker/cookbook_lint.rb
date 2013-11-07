class PressureCooker
  class Cooker
    class CookbookLint < Cooker

      banner 'cooker cookbook lint COOKBOOK'

      deps do
        require 'chef/knife'
      end

      def run
        # Chef / Stash Cookbook Variables
        PressureCooker::Config.from_file("#{ENV['HOME']}/.cooker/config.rb")
        PressureCooker::Config.merge!(config)
        @cookbook_name = validate_param(@name_args[0], "a cookbook name")
        @cookbook_path = PressureCooker::Config[:stash_dir]
        @checkout_path = @cookbook_path + "/" + @cookbook_name

        test_with_knife
        test_with_foodcritic

      end

      def test_with_knife
        ui.info "Testing cookbook with knife"
        cmd = "knife cookbook test #{@cookbook_name} -o #{@cookbook_path}"
        shell = Mixlib::ShellOut.new(cmd)
        shell.run_command
        shell.error!
        ui.info shell.stdout.strip
      end

      def test_with_foodcritic
        ui.info "Testing cookbook with foodcritic"
        cmd = "foodcritic #{@checkout_path} -f correctness"
        shell = Mixlib::ShellOut.new(cmd)
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
