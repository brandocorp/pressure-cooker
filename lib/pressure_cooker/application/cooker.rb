require 'pressure_cooker/cooker'
require 'pressure_cooker/application'

class PressureCooker::Application::Cooker < PressureCooker::Application

  NO_COMMAND_GIVEN = "You need to pass a sub-command (e.g., cooker SUB-COMMAND)\n"

  banner 'cooker sub-command (options)'

  option :config_file,
    :short => "-c CONFIG",
    :long  => "--config CONFIG",
    :description => "The configuration file to use",
    :proc => lambda { |path| File.expand_path(path, Dir.pwd) }

  option :help,
    :short        => "-h",
    :long         => "--help",
    :description  => "Show this message",
    :on           => :tail,
    :boolean      => true

  option :version,
    :short        => "-v",
    :long         => "--version",
    :description  => "Show version",
    :boolean      => true,
    :proc         => lambda {|v| puts "PressureCooker: #{::PressureCooker::VERSION}"},
    :exit         => 0

  def run
    Mixlib::Log::Formatter.show_time = false
    validate_and_parse_options
    quiet_traps
    PressureCooker::Cooker.run(ARGV, options)
    exit 0
  end

  private

    def quiet_traps
      trap("TERM") do
        exit 1
      end

      trap("INT") do
        exit 2
      end
    end

    def validate_and_parse_options
      # Checking ARGV validity *before* parse_options because parse_options
      # mangles ARGV in some situations
      if no_command_given?
        print_help_and_exit(1, NO_COMMAND_GIVEN)
      elsif no_subcommand_given?
        if (want_help? || want_version?)
          print_help_and_exit
        else
          print_help_and_exit(2, NO_COMMAND_GIVEN)
        end
      end
    end

    def no_subcommand_given?
      ARGV[0] =~ /^-/
    end

    def no_command_given?
      ARGV.empty?
    end

    def want_help?
      ARGV[0] =~ /^(--help|-h)$/
    end

    def want_version?
      ARGV[0] =~ /^(--version|-v)$/
    end

    def print_help_and_exit(exitcode=1, fatal_message=nil)
      Chef::Log.error(fatal_message) if fatal_message

      begin
        self.parse_options
      rescue OptionParser::InvalidOption => e
        puts "#{e}\n"
      end
      puts self.opt_parser
      puts
      PressureCooker::Cooker.list_commands
      exit exitcode
    end

end
