require 'spec_helper'
require 'pressure_cooker'

describe PressureCooker do

  describe ".version" do

    let(:version) do
      PressureCooker::VERSION
    end

    it "displays the version" do
      PressureCooker.version.should == version
    end
  end

end
