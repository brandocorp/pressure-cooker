class PressureCooker

  class BadIssueProviderDefinition < StandardError; end

  class IssueProvider

    def initialize(options)
      provider = options[:provider].to_s
      #require_relative "issue_provider/#{provider}"
    end

    def get(key)
      "This will be overriden"
    end

    def name
      "This will be overriden"
    end

    def load
      "This will be overriden"
    end

  end
end
