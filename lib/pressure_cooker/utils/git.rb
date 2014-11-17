require 'git'

module Git
  module API
    module Utils

      def init_repo(local_path)
        Git.init(local_path)
      end

      def open_repo(local_path)
        Git.open(local_path)
      end

      def clone_repo(git_url, name, local_path)
        Git.clone(git_url, name, :path => local_path)
      end

    end
  end
end
