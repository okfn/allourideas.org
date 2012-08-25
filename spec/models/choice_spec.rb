require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Choice do
  it "delegates related_choice to its ChoiceChoice" do
    choice = Choice.new(:id => 5)
    related_choice = Choice.new(:id => 10)
    Factory(:choice_choice, :choice_id => choice.id, :related_choice_id => related_choice.id)

    Choice.stub!(:find).with(related_choice.id, :params => { :question_id => choice.question_id }).and_return(related_choice)

    choice.related_choice.should == related_choice
  end

  it "creates the association with its related choice through its ChoiceChoice" do
    choice = Choice.new(:id => 5, :question_id => 1)
    related_choice = Choice.new(:id => 42, :question_id => 1)

    choice.stub!(:choice_belongs_to_the_same_question?).with(related_choice.id).and_return(true)
    choice.related_choice_id = related_choice.id

    ChoiceChoice.find_by_choice_id(choice.id).related_choice_id == related_choice.id
  end

  it "doesn't creates the association with its related choice if they're not from the same question" do
    choice = Choice.new(:id => 5, :question_id => 1)
    related_choice = Choice.new(:id => 42, :question_id => 100)

    choice.related_choice_id = related_choice.id

    ChoiceChoice.find_by_choice_id(choice.id).should be_nil
  end

  it "clears the association with its related choice if passed nil" do
    choice = Choice.new(:id => 5, :question_id => 1)

    choice.related_choice_id = nil

    ChoiceChoice.find_by_choice_id(choice.id).related_choice_id.should be_nil
  end
end
