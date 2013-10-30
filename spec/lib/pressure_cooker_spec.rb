require 'spec_helper'
require 'pressure_cooker'

describe PressureCooker do

  describe "#version" do
    it "displays the version" do
      expect(described_class.version).to equal(PressureCooker::VERSION)
    end
  end

end
