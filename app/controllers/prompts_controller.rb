class PromptsController < ApplicationController
  include ActionView::Helpers::TextHelper

  def vote
    bingo!("voted")
    voted_prompt = Prompt.find(params[:id], :params => {:question_id => params[:question_id]})
    session[:has_voted] = true

    @earl = Earl.find_by_question_id(params[:question_id])
    if params[:direction] &&
       vote = voted_prompt.post(:vote, :question_id => params[:question_id],
                                       :vote => get_object_request_options(params, :vote))

      render :json => next_prompt.to_json
    else
      render :text => 'Vote unsuccessful.', :status => :unprocessable_entity
    end
  end

  def skip
    prompt_id = params[:id]
    question_id = params[:question_id]

    logger.info "Getting ready to skip out on Prompt #{prompt_id}, Question #{params[:id]}"
    @prompt = Prompt.find(prompt_id, :params => {:question_id => params[:question_id]})
    @earl = Earl.find_by_question_id(params[:question_id])

    if skip = @prompt.post(:skip, :question_id => question_id,
                           :skip => get_object_request_options(params, :skip))
      render :json => next_prompt.to_json
    else
      render :json => '{"error" : "Skip failed"}'
    end
  end

  def flag
    prompt_id = params[:id]
    reason = params[:flag_reason]
    inappropriate_side = params[:side]
    question_id = params[:question_id]
    question = Question.find(question_id)
    @earl = question.earl

    @prompt = Prompt.find(prompt_id, :params => {:question_id => question_id})
    choice_id = inappropriate_side == "left_flag" ? @prompt.left_choice_id : @prompt.right_choice_id 

    @choice = Choice.new
    @choice.id = choice_id
    @choice.prefix_options[:question_id] = question_id

    c = @choice.put(:flag,
                    :visitor_identifier => request.session_options[:id],
                    :explanation => reason)

    new_choice = Crack::XML.parse(c.body)['choice']
    flag_choice_success = (c.code == "201" && new_choice['active'] == false)
    IdeaMailer.delay.deliver_flag_notification(question, new_choice["id"], new_choice["data"], reason, @photocracy)

    begin
      skip = @prompt.post(:skip, :question_id => question_id,
                          :skip => get_object_request_options(params, :skip_after_flag))
    rescue ActiveResource::ResourceConflict
      skip = nil
      flash[:error] = "You flagged an idea as inappropriate. We have deactivated this idea temporarily and sent a notification to the idea marketplace owner. Currently, this idea marketplace does not have enough active ideas. Please contact the owner of this marketplace to resolve this situation"
    end

    if flag_choice_success && skip
      render :json => next_prompt.to_json
    else
      render :json => {:error => "Flag of choice failed",
      :redirect => url_for(:controller => :home, :action => :index )}.to_json
    end
  end

  def load_wikipedia_marketplace
    result = switch_wikipedia_marketplace(params[:question_id])
    render :json => result.to_json
  end

  private
  def next_prompt
    earl = random_earl
    { :redirect => consultation_earl_url(earl.consultation, earl) }
  end

  def random_earl
    @earl.consultation.earls.active.choice
  end

  def get_object_request_options(params, request_type)
     options = { :visitor_identifier => request.session_options[:id],
                 :time_viewed => params[:time_viewed],
                 :appearance_lookup => params[:appearance_lookup]
     }
     case request_type
       when :vote
           options.merge!({:direction => params[:direction],
		     :skip_fraud_protection => true,
                     :tracking => {:x_click_offset => params[:x_click_offset],
                                   :y_click_offset => params[:y_click_offset]}
	       })
       when :skip
	   options.merge!(:skip_reason => params[:cant_decide_reason])
       when :skip_after_flag
	   options.merge!(:skip_reason => params[:flag_reason])
 
     end

      if wikipedia?
        options.merge!({:force_invalid_vote => true})
      end
     options
  end
end
