require 'mixlib/config'

class PressureCooker
  module Config

    extend Mixlib::Config

    config_strict_mode true

    git_name "Otto McMation"
    git_email "Otto.McMation@apollogrp.edu"
    git_provider :stash

    issue_tracker nil

    jira_username nil
    jira_password nil
    jira_url nil

    stash_dir "#{ENV['HOME']}/.stash"
    stash_url "https://stash.apollogrp.edu"
    stash_project nil
    stash_repo nil
    stash_oauth nil

    github nil
    bitbucket nil
    gitlab nil

  end
end
