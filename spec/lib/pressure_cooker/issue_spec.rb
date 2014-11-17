require 'spec_helper'
require 'pressure_cooker'
require 'pressure_cooker/issue'
require 'pressure_cooker/issue_provider'

describe PressureCooker::Issue do

  describe ".new" do

    context "when no provider is configured" do

      it "will raise an error" do
        expect { PressureCooker::Issue.new(:key => 'FOO-999') }.to raise_error(PressureCooker::IssueProviderUndefined)
      end

      it "will use the provider option" do
        PressureCooker::IssueProvider.stub(:get) { double(:provider => 'mock') }
        issue = PressureCooker::Issue.new(:key => 'FOO-999', :provider => 'mock')
        issue.provider.should == :mock
      end

    end

    context "an issue provider is pre-configured" do

      it "uses the configured provider" do
        PressureCooker::Config.stub(:[]).with(:issue_provider).and_return(:mock)
        issue = PressureCooker::Issue.new(:key => 'FOO-999')
        issue.provider.should == :mock
      end

    end

  end

  describe ".load" do
    it "gets the data from the provider" do
      mock_return = [ "Otto McMation", ["This is a comment"], "TODO", "This is a summary.", "patch" ]
      PressureCooker::Config.stub(:[]).with(:issue_provider).and_return(:mock)
      PressureCooker::IssueProvider.stub(:get).with('FOO-999').and_return(mock_return)
      issue = PressureCooker::Issue.new(:key => 'FOO-999')
      issue.assignee.should == "Otto McMation"
    end
  end

end
