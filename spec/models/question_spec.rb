require "spec/spec_helper"

describe Question do

  it "should not save if it's not valid" do
    Factory.build(:invalid_question).save.should be_false
  end

  it "should not cache the errors" do
    question = Factory.build(:question, :ideas => nil)
    question.valid?.should be_false

    question.ideas = "some idea"
    question.valid?.should be_true
  end

  describe "validations" do
    describe "site is photocracy" do
      it "should not be valid without ideas" do
        question = Factory.build(:question, :ideas => nil)
        question.valid?(photocracy = false).should be_false
      end

      it "should be valid without ideas if the question has any choices" do
        question = Factory.build(:question, :ideas => nil, :choices_count => 2)
        question.valid?(photocracy = false).should be_true
      end
    end

    describe "site isn't photocracy" do
      it "should be valid without ideas" do
        question = Factory.build(:question, :ideas => nil)
        question.valid?(photocracy = true).should be_true
      end
    end
  end

  describe "earl" do
    it "should return the question's Earl" do
      earl = Factory(:earl)
      question = earl.question
      question.earl.should == earl
    end

    it "should return nil if couldn't find an Earl" do
      Question.new.earl.should be_nil
    end
  end

  describe "user_can_view_results?" do
    describe "question allows to results" do
      it "should be true if the question allows to show results" do
        question = Factory.build(:question)
        question.stub(:show_results?).and_return(true)

        question.user_can_view_results?(nil, nil).should be_true
      end
    end

    describe "question doesn't allow to show results" do
      before do
        @question = Factory.build(:question)
        @question.stub(:show_results?).and_return(false)
        @earl = Factory(:earl)
      end

      it "should be true if the user owns the earl" do
        @question.user_can_view_results?(@earl.user, @earl).should be_true
      end

      it "should be true if the user is an admin" do
        admin = Factory(:admin)
        @question.user_can_view_results?(admin, @earl).should be_true
      end

      it "should be false if the user wasn't passed" do
        @question.user_can_view_results?(nil, @earl).should be_false
      end

      it "should be false if the user doesn't owns the earl and isn't an admin" do
        user = Factory(:user)
        @question.user_can_view_results?(user, @earl).should be_false
      end
    end
  end

  describe "slug" do
    it "should return earl's slug" do
      earl = Factory(:earl)
      question = earl.question

      question.slug.should == earl.slug.name
    end

    it "should return nil if there's no earl" do
      Question.new.slug.should be_nil
    end
  end

  describe "active_choices" do
    it "should be the difference between the total and the inactive choices" do
      question = Factory.build(:question, :choices_count => 51,
                                          :inactive_choices_count => 9)

      question.active_choices.should == 42
    end
  end

  describe "choices_count" do
    it "should return 0 if there're no choices_count" do
      Factory.build(:question).choices_count == 0
    end

    it "should return the choices_count if there's one" do
      Factory.build(:question, :choices_count => 50).choices_count == 50
    end
  end

  describe "name" do
    it "should return name" do
      question = Factory.build(:question, :name => 'question name')
      question.stub!(:earl).and_return(mock(:name => 'earl name'))
      question.name.should == 'question name'
    end

    it "should return earl's name, if we have no name" do
      question = Factory.build(:question, :name => nil)
      question.stub!(:earl).and_return(mock(:name => 'earl name'))
      question.name.should == 'earl name'
    end
  end

  it "should delegate consultation to its earl" do
    question = Factory.build(:question)
    earl = mock
    question.stub!(:earl).and_return(earl)

    earl.should_receive(:consultation)

    question.consultation
  end
end
