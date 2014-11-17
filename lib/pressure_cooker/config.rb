require 'mixlib/config'

class PressureCooker
  module Config

    extend Mixlib::Config

    config_strict_mode true

    # git config
    config_context :git do
      default :name, "Otto McMation"
      default :email, "Otto.McMation@apollogrp.edu"
      default :provider, "stash"
    end

    configurable :issue_provider
    configurable :ci_provider
    configurable :vcs_provider

    # jira config
    config_context :jira do
      configurable :username
      configurable :password
      configurable :url
    end

    # Stash config
    config_context :stash do
      default :dir, "#{ENV['HOME']}/.stash"
      configurable :url
      configurable :cookbook_project
      configurable :databag_project
      configurable :repo
      configurable :oauth
    end

    # Bamboo config
    config_context :bamboo do
      configurable :username
      configurable :password
      configurable :url
    end

    # Other vcs providers
    configurable :github
    configurable :bitbucket
    configurable :gitlab

    # Other CI providers
    config_context :jenkins do
      configurable :username
      configurable :password
      configurable :url
    end

    config_context :travisci do
      configurable :username
      configurable :password
      configurable :url
    end

  end
end
