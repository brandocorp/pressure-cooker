require 'pressure_cooker/config'
require 'pressure_cooker/issue_provider'

class PressureCooker

  class IssueProviderUndefined < StandardError; end
  class IssueNotFound < StandardError; end

  class Issue

    attr_reader :assignee, :comments, :key, :project, :provider, :status, :summary, :type

    def initialize(options)

      options = options.dup

      if options.keys.include?(:provider)
        @provider = options.delete(:provider).to_s.downcase.to_sym
      elsif PressureCooker::Config[:issue_provider]
        @provider = PressureCooker::Config[:issue_provider].to_s.downcase.to_sym
      else
        raise PressureCooker::IssueProviderUndefined, "Issue Provider was not passed in, and could not be determined from your configuration."
      end

      @key = options[:key]

      @api = PressureCooker::IssueProvider.new(:provider => provider)

      load
    end

    def load
      @assignee, @comments, @status, @summary, @type = @api.get(@key)
    end

    def provider
      @api.name
    end



  end

end
