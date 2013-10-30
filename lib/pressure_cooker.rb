require "pressure_cooker/version"

module PressureCooker
  class << self
    attr_reader :version
  end
  @version = PressureCooker::VERSION
end

# Shorthand the Namespace
PC = PressureCooker
