class PromptsController < ApplicationController
  include ActionView::Helpers::TextHelper

  def vote
    bingo!("voted")
    voted_prompt = Prompt.find(params[:id], :params => {:question_id => params[:question_id]})
    session[:has_voted] = true
    
    if params[:direction] &&
      vote = voted_prompt.post(:vote,
        :question_id => params[:question_id],
          :vote => { :direction => params[:direction],
                     :visitor_identifier => request.session_options[:id],
                     :time_viewed => params[:time_viewed],
                     :appearance_lookup => params[:appearance_lookup],
                     :tracking => {:x_click_offset => params[:x_click_offset],
                                   :y_click_offset => params[:y_click_offset]}
                   },
          :next_prompt => { :with_appearance => true,
                            :with_visitor_stats => true,
                            :visitor_identifier => request.session_options[:id]
                          }
        
      )

      next_prompt = Crack::XML.parse(vote.body)['prompt']
      leveling_message = Visitor.leveling_message(:votes => next_prompt['visitor_votes'].to_i,
					                                        :ideas => next_prompt['visitor_ideas'].to_i)

      result = {
        :newleft           => truncate(next_prompt['left_choice_text'], {:length => 137}),
        :newright          => truncate(next_prompt['right_choice_text'], {:length => 137}),
        :appearance_lookup => next_prompt['appearance_id'],
        :prompt_id         => next_prompt['id'],
        :leveling_message  => leveling_message,
      }

      result = add_photocracy_info(result, next_prompt, params[:question_id]) if @photocracy
      render :json => result.to_json
    else
      render :text => 'Vote unsuccessful.', :status => :unprocessable_entity
    end
  end

  def skip
    prompt_id = params[:id]
    appearance_lookup = params[:appearance_lookup]
    time_viewed = params[:time_viewed]
    reason = params[:cant_decide_reason]
    question_id = params[:question_id]

    logger.info "Getting ready to skip out on Prompt #{prompt_id}, Question #{params[:id]}"
    @prompt = Prompt.find(prompt_id, :params => {:question_id => params[:question_id]})

    if skip = @prompt.post(:skip, :question_id => question_id,
                           :skip => {
                             :visitor_identifier => request.session_options[:id],
                             :time_viewed => time_viewed,
                             :skip_reason => reason,
                             :appearance_lookup => params[:appearance_lookup]
                             },
                           :next_prompt => {
                             :with_appearance => true,
                             :with_visitor_stats => true,
                             :visitor_identifier => request.session_options[:id]}
                           )

      next_prompt = Crack::XML.parse(skip.body)['prompt']
      leveling_message = Visitor.leveling_message(:votes => next_prompt['visitor_votes'].to_i,
					                                        :ideas => next_prompt['visitor_ideas'].to_i)

      result = {
        :newleft           => truncate(next_prompt['left_choice_text'], {:length => 137}),
        :newright          => truncate(next_prompt['right_choice_text'], {:length => 137}),
        :appearance_lookup => next_prompt['appearance_id'],
        :prompt_id         => next_prompt['id'],
        :leveling_message  => leveling_message,
        :message => t('vote.cant_decide_message')
      }

      result = add_photocracy_info(result, next_prompt, params[:question_id]) if @photocracy
      render :json => result.to_json
    else
      render :json => '{"error" : "Skip failed"}'
    end
  end

  def flag
    prompt_id = params[:id]
    appearance_lookup = params[:appearance_lookup]
    time_viewed = params[:time_viewed]
    reason = params[:flag_reason]
    inappropriate_side = params[:side]
    question_id = params[:question_id]
    @earl = Earl.find_by_question_id(question_id)

    logger.info "Getting ready to mark #{inappropriate_side} of Prompt #{prompt_id}, Question #{params[:question_id]}"
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
    IdeaMailer.send_later :deliver_flag_notification, @earl, new_choice["id"], new_choice["data"], reason

    begin
      skip = @prompt.post(:skip, :question_id => question_id,
                          :skip => {
                            :visitor_identifier => request.session_options[:id],
                            :time_viewed => time_viewed,
                            :skip_reason => reason },
                          :next_prompt => {
                            :with_appearance => true,
                            :with_visitor_stats => true,
                            :visitor_identifier => request.session_options[:id] }
                          )
    rescue ActiveResource::ResourceConflict
      skip = nil
      flash[:error] = "You flagged an idea as inappropriate. We have deactivated this idea temporarily and sent a notification to the idea marketplace owner. Currently, this idea marketplace does not have enough active ideas. Please contact the owner of this marketplace to resolve this situation"
    end

    if flag_choice_success && skip
      next_prompt = Crack::XML.parse(skip.body)['prompt']
      leveling_message = Visitor.leveling_message(:votes => next_prompt['visitor_votes'].to_i,
					                                        :ideas => next_prompt['visitor_ideas'].to_i)

      result = {
        :newleft           => truncate(next_prompt['left_choice_text'], {:length => 137}),
        :newright          => truncate(next_prompt['right_choice_text'], {:length => 137}),
        :appearance_lookup => next_prompt['appearance_id'],
        :prompt_id         => next_prompt['id'],
        :leveling_message  => leveling_message,
        :message => t('vote.flag_complete_message')
      }

      result = add_photocracy_info(result, next_prompt, params[:question_id]) if @photocracy
      render :json => result.to_json
    else
      render :json => {:error => "Flag of choice failed",
      :redirect => url_for(:controller => :home, :action => :index )}.to_json
    end
  end

  private
  def add_photocracy_info(result, next_prompt, question_id)
    newright_photo = Photo.find(next_prompt['right_choice_text'])
    newleft_photo = Photo.find(next_prompt['left_choice_text'])
    result.merge!({
      :visitor_votes        => next_prompt['visitor_votes'],
      :newright_photo       => newright_photo.image.url(:medium),
      :newright_photo_thumb => newright_photo.image.url(:thumb),
      :newleft_photo        => newleft_photo.image.url(:medium),
      :newleft_photo_thumb  => newleft_photo.image.url(:thumb),
      :newleft_url          => vote_question_prompt_url(question_id, next_prompt['id'], :direction => :left),
      :newright_url         => vote_question_prompt_url(question_id, next_prompt['id'], :direction => :right),
      :flag_url             => flag_question_prompt_url(question_id, next_prompt['id'], :format => :js),
      :skip_url             => skip_question_prompt_url(question_id, next_prompt['id'], :format => :js),
      :voted_at             => Time.now.getutc.iso8601,
      :voted_prompt_winner  => params[:direction]
    })
  end
end