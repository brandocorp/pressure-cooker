require 'spec_helper'
require 'pressure_cooker/config'
require 'pressure_cooker/issue_provider'

describe PressureCooker::IssueProvider do

  class PressureCooker::IssueProvider::Mock; end

  describe ".new" do
    it "returns the correct provider API class" do
      Kernel.stub(:require_relative)
      provider = PressureCooker::IssueProvider.new(:provider => "mock")
      provider.name.should == 'Mock'
    end
  end

  describe ".configure" do
  end

  describe ".get" do
  end

  describe ".name" do
  end

  describe ".comment" do
  end

  describe "" do

  end

end
