require "spec/spec_helper"

describe Question do

  it "should not save if it's not valid" do
    Factory.build(:invalid_question).save.should be_false
  end

  describe "validations" do
    it "should not be valid without name" do
      question = Factory.build(:question, :name => nil)
      question.should_not be_valid
    end

    describe "site is photocracy" do
      it "should not be valid without ideas" do
        question = Factory.build(:question, :ideas => nil)
        question.valid?(photocracy = false).should be_false
      end
    end

    describe "site isn't photocracy" do
      it "should be valid without ideas" do
        question = Factory.build(:question, :ideas => nil)
        question.valid?(photocracy = true).should be_true
      end
    end
  end

  describe "find_id_by_slug" do
    it "returns Earl's question id" do
      earl = Factory(:earl)
      Question.find_id_by_slug(earl.slug.name).should == earl.question.id
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
end
