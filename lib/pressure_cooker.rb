require "pressure_cooker/version"
require "pressure_cooker/config"

class PressureCooker

  def self.version
    "#{PressureCooker::VERSION}"
  end

end

# Shorthand the Namespace
PC = PressureCooker
