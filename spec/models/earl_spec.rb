require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Earl do

  describe "validations" do
    it "should be valid given valid attributes" do
      Factory.build(:earl).should be_valid
    end

    it "should be valid with a non-unique name, but different consultation" do
      earl = Factory(:earl_without_question)
      Factory.build(:earl_without_question, :name => earl.name).should be_valid
    end

    it "should not be valid with non-unique name within the same consultation" do
      earl = Factory(:earl_without_question)
      Factory.build(:earl_without_question, :consultation => earl.consultation, :name => earl.name).should_not be_valid
    end

    it "should not be valid with an invalid question" do
      earl = Factory.build(:earl, :question => Factory.build(:invalid_question))
      earl.should_not be_valid
    end

    it "should not be valid without a name" do
      earl = Factory.build(:earl_without_question, :name => nil)
      earl.should_not be_valid
    end
  end

  it "should be able to add a question" do
    earl = Factory(:earl_without_question)
    question = mock_model(Question)

    earl.question = question

    earl.question_id.should == question.id
  end

  it "should delegate votes count to its question" do
    earl = Factory(:earl)
    earl.question.stub!(:votes_count).and_return(:the_votes_count)

    earl.votes_count.should == :the_votes_count
  end

  describe "accepts nested attributes for question" do
    it "creates a new question with passed attributes" do
      question_attributes = { :ideas => 'question ideas',
                              :visitor_identifier => 'identifier' }
      earl_attributes = Factory.build(:earl_without_question).attributes
      earl_attributes[:question_attributes] = question_attributes

      earl = Earl.create(earl_attributes)

      earl.question.ideas.should == 'question ideas'
      earl.question.visitor_identifier.should == 'identifier'
      earl.question.local_identifier.should == earl.user_id
    end
  end

end
