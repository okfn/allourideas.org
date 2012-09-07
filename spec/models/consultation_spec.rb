require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Consultation do

  describe "validations" do
    it "should be valid given valid attributes" do
      Factory.build(:consultation).should be_valid
    end

    it "should not be valid without a name" do
      consultation = Factory.build(:consultation, :name => nil)
      consultation.should_not be_valid
    end
  end

  describe "votes_count" do
    it "returns the sum of its earls' votes count" do
      earls = [Factory.build(:earl), Factory.build(:earl)]
      earls.each { |earl| earl.stub!(:votes_count).and_return(1) }
      votes_count = earls.map(&:votes_count).inject(:+)
      consultation = Factory(:consultation, :earls => earls)

      consultation.votes_count.should == votes_count
    end

    it "returns 0 if its earls haven't received votes yet" do
      consultation = Factory(:consultation)

      consultation.votes_count.should == 0
    end
  end

end
