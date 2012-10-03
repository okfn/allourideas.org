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
      consultation = Factory(:consultation_without_earls, :earls => earls)

      consultation.votes_count.should == votes_count
    end

    it "returns 0 if its earls haven't received votes yet" do
      consultation = Factory(:consultation)

      consultation.votes_count.should == 0
    end
  end

  describe "accepts nested attributes" do
    it "creates a new earl with passed attributes" do
      earls_attributes = { "0" => Factory.build(:earl_without_question).attributes }
      consultation_attributes = { :name => "Consultation",
                                  :earls_attributes => earls_attributes }

      consultation = Consultation.create(consultation_attributes)

      consultation.earls.length.should == 1
    end

    it "creates a new user with passed attributes" do
      user_attributes = { :email => "email@email.com",
                          :password => "123456" }
      consultation_attributes = { :name => "Consultation",
                                  :user_attributes => user_attributes }

      consultation = Consultation.create(consultation_attributes)

      consultation.user.should_not be_nil
    end
  end

  describe "activate!" do
    it "should activate and save the consultation" do
      consultation = Factory.build(:consultation_without_earls, :active => false)

      consultation.activate!

      consultation.should be_active
      consultation.should_not be_new_record
    end
  end

end
