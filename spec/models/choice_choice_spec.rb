require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChoiceChoice do

  describe "validations" do
    describe "should be valid" do
      it "given valid attributes" do
        choice_choice = Factory.build(:choice_choice)
        choice_choice.should be_valid
      end

      it "without an unique related choice" do
        existing = Factory(:choice_choice)
        choice_choice = Factory.build(:choice_choice,
                                      :related_choice_id => existing.related_choice_id)
        choice_choice.should be_valid
      end

      it "without a related choice" do
        choice_choice = Factory.build(:choice_choice, :related_choice_id => nil)
        choice_choice.should be_valid
      end
    end

    describe "should be invalid" do
      it "without a choice" do
        choice_choice = Factory.build(:choice_choice, :choice_id => nil)
        choice_choice.should_not be_valid
      end
    
      it "without an unique choice" do
        existing = Factory(:choice_choice)
        choice_choice = Factory.build(:choice_choice,
                                      :choice_id => existing.choice_id)
        choice_choice.should_not be_valid
      end
    
      it "without an unique choice and related choice pair" do
        existing = Factory(:choice_choice)
        choice_choice = Factory.build(:choice_choice,
                                      :choice_id => existing.choice_id,
                                      :related_choice_id => existing.related_choice_id)
        choice_choice.should_not be_valid
      end
    end
  end

end
