require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for "returns next prompt" do
  before do
    @earl = Factory(:earl)
    mock_prompt = double('prompt').as_null_object
    Prompt.stub!(:find).and_return(mock_prompt)
    next_prompt = { 'left_choice_text' => 'left-choice-text',
                    'right_choice_text' => 'right-choice-text',
                    'appearance_id' => 'appearance_id',
                    'id' => 'prompt_id',
                    'visitor_votes' => 5,
                    'visitor_ideas' => 10 }
    Crack::XML.stub!(:parse).with(mock_prompt).and_return({'prompt' => next_prompt})
    @expected_response = { 'newleft' => 'left-choice-text',
                           'leveling_message' => 'Now you have cast 5 votes and added 10 ideas: fantastic',
                           'appearance_lookup' => 'appearance_id',
                           'newright' => 'right-choice-text',
                           'prompt_id' => 'prompt_id' }
    @expected_response['message'] = @message if @message
  end

  it "should return the expected response as json" do
    post @action, :question_id => @earl.question_id,
                 :id => 1,
                 :direction => 'left'

    JSON.parse(response.body).should == @expected_response
  end

  it "should add wikipedia info if it's a wikipedia prompt" do
    controller.stub!(:wikipedia?).and_return(true)
    post @action, :question_id => @earl.question_id,
                :id => 1,
                :direction => 'left'

    wikipedia = { 'left_image_id' => 'left',
                  'right_image_id' => 'right',
                  'newleft' => 'choice-text',
                  'newright' => 'choice-text' }

    JSON.parse(response.body).should == @expected_response.merge(wikipedia)
  end
end

describe PromptsController do

  describe "vote" do
    before(:all) do
      @action = :vote
    end
    it_should_behave_like "returns next prompt"
  end

  describe "skip" do
    before(:all) do
      @action = :skip
      @message = "You couldn't decide."
    end
    it_should_behave_like "returns next prompt"
  end

  describe "flag" do
    before(:all) do
      @action = :flag
      @message = "You flagged a choice as inappropriate."
    end

    before(:each) do
      mock_choice = double('choice').as_null_object
      mock_choice.stub!(:code).and_return("201")
      Choice.stub!(:new).and_return(mock_choice)
      Crack::XML.stub!(:parse).with(mock_choice).and_return({'choice' => {'active' => false}})
    end

    it_should_behave_like "returns next prompt"
  end
end
