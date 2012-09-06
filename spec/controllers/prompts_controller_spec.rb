require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for "returns next prompt" do
  before do
    @earl = Factory(:earl)
    mock_prompt = double('prompt').as_null_object
    Prompt.stub!(:find).and_return(mock_prompt)
    @expected_response = { 'redirect' => consultation_earl_url(@earl.consultation, @earl) }
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

    JSON.parse(response.body).should == @expected_response
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
