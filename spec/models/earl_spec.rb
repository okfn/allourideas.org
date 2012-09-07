require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Earl do

  describe "validations" do
    it "should be valid given valid attributes" do
      Factory.build(:earl).should be_valid
    end

    it "should not be valid with an invalid question" do
      earl = Factory.build(:earl, :question => Factory.build(:invalid_question))
      earl.should_not be_valid
    end

    it "should not be valid without a name" do
      earl = Factory.build(:earl, :name => nil)
      earl.should_not be_valid
    end

    it "should not be valid with a reserved name" do
      earl = Factory.build(:earl)

      Earl.reserved_names.each do |reserved_name|
        earl.name = reserved_name
        earl.should_not be_valid
      end
    end

    it "should not be valid with a non-unique name" do
      earl = Factory(:earl)
      Factory.build(:earl, :name => earl.name).should_not be_valid
    end
  end

  it "should be able to add a question" do
    earl = Factory(:earl)
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
      earl = Earl.create(:name => 'some unique name',
                         :user => Factory.build(:user),
                         :question_attributes => { :ideas => 'question ideas',
                                                   :visitor_identifier => 'identifier' })

      earl.question.ideas.should == 'question ideas'
      earl.question.visitor_identifier.should == 'identifier'
      earl.question.local_identifier.should == earl.user_id
    end
  end

end
