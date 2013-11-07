require 'pressure_cooker/version'

class PressureCooker
  class Cooker
    class SubcommandLoader

      attr_reader :pressure_cooker_config_dir
      attr_reader :env

      def initialize(pressure_cooker_config_dir, env=ENV)
        @pressure_cooker_config_dir, @env = pressure_cooker_config_dir, env
        @forced_activate = {}
      end

      # Load all the sub-commands
      def load_commands
        subcommand_files.each { |subcommand| Kernel.load subcommand }
        true
      end

      # Returns an Array of paths to cooker commands located in pressure_cooker_config_dir/plugins/cooker/
      # and ~/.pressure_cooker/plugins/cooker/
      def site_subcommands
        user_specific_files = []

        if pressure_cooker_config_dir
          user_specific_files.concat Dir.glob(File.expand_path("plugins/cooker/*.rb", pressure_cooker_config_dir))
        end

        # finally search ~/.pressure_cooker/plugins/cooker/*.rb
        user_specific_files.concat Dir.glob(File.join(env['HOME'], '.pressure_cooker', 'plugins', 'cooker', '*.rb')) if env['HOME']

        user_specific_files
      end

      # Returns a Hash of paths to cooker commands built-in to pressure_cooker, or installed via gem.
      # If rubygems is not installed, falls back to globbing the cooker directory.
      # The Hash is of the form {"relative/path" => "/absolute/path"}
      #--
      # Note: the "right" way to load the plugins is to require the relative path, i.e.,
      #   require 'pressure_cooker/cooker/command'
      # but we're getting frustrated by bugs at every turn, and it's slow besides. So
      # subcommand loader has been modified to load the plugins by using Kernel.load
      # with the absolute path.
      def gem_and_builtin_subcommands
        # search all gems for pressure_cooker/cooker/*.rb
        require 'rubygems'
        find_subcommands_via_rubygems
      rescue LoadError
        find_subcommands_via_dirglob
      end

      def subcommand_files
        @subcommand_files ||= (gem_and_builtin_subcommands.values + site_subcommands).flatten.uniq
      end

      def find_subcommands_via_dirglob
        # The "require paths" of the core cooker subcommands bundled with pressure_cooker
        files = Dir[File.expand_path('../../../cooker/*.rb', __FILE__)]
        subcommand_files = {}
        files.each do |cooker_file|
          rel_path = cooker_file[/#{PRESSURE_COOKER_ROOT}#{Regexp.escape(File::SEPARATOR)}(.*)\.rb/,1]
          subcommand_files[rel_path] = cooker_file
        end
        subcommand_files
      end

      def find_subcommands_via_rubygems
        files = find_files_latest_gems 'pressure_cooker/cooker/*.rb'
        subcommand_files = {}
        files.each do |file|
          rel_path = file[/(#{Regexp.escape File.join('pressure_cooker', 'cooker', '')}.*)\.rb/, 1]
          subcommand_files[rel_path] = file
        end

        subcommand_files.merge(find_subcommands_via_dirglob)
      end

      private

      def find_files_latest_gems(glob, check_load_path=true)
        files = []

        if check_load_path
          files = $LOAD_PATH.map { |load_path|
            Dir["#{File.expand_path glob, load_path}#{Gem.suffix_pattern}"]
          }.flatten.select { |file| File.file? file.untaint }
        end

        gem_files = latest_gem_specs.map do |spec|
          # Gem::Specification#matches_for_glob wasn't added until RubyGems 1.8
          if spec.respond_to? :matches_for_glob
            spec.matches_for_glob("#{glob}#{Gem.suffix_pattern}")
          else
            check_spec_for_glob(spec, glob)
          end
        end.flatten

        files.concat gem_files
        files.uniq! if check_load_path

        return files
      end

      def latest_gem_specs
        @latest_gem_specs ||= if Gem::Specification.respond_to? :latest_specs
          Gem::Specification.latest_specs
        else
          Gem.source_index.latest_specs
        end
      end

      def check_spec_for_glob(spec, glob)
        dirs = if spec.require_paths.size > 1 then
          "{#{spec.require_paths.join(',')}}"
        else
          spec.require_paths.first
        end

        glob = File.join("#{spec.full_gem_path}/#{dirs}", glob)

        Dir[glob].map { |f| f.untaint }
      end
    end
  end
end
