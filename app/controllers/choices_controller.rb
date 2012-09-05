class ChoicesController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :authenticate, :only => [:toggle]
  before_filter :earl_owner_or_admin_only, :only => [:activate, :deactivate, :rotate, :update]

  def show
    @question = Question.find(params[:question_id])
    @earl = @question.earl
    
    if params[:locale].nil? && @earl.default_lang != I18n.default_locale.to_s
	      I18n.locale = @earl.default_lang
	      redirect_to :action => :show, :controller => :choices, 
		      :question_id => params[:question_id], :id => params[:id]  and return
    end
    @choice = Choice.find(params[:id], :params => {:question_id => @question.id, :version => 'all'})
    @choices = Choice.find(:all, :params => {:question_id => @question.id, :include_inactive => true})
    @choices.reject! { |choice| choice.id == @choice.id }
    @num_votes = @choice.wins + @choice.losses

    if @photocracy
      @photo = Photo.find(@choice.data.strip)
      @votes = @choice.get(:votes)

      if params[:login_reminder]
          unless (current_user && (current_user.owns?(@earl) || current_user.admin?))
    	      deny_access(t('user.deny_access_error')) and return
          end
      end
    end

    if @choice
      respond_to do |format|
        format.html  { render :layout => !request.xhr? }
      end
    else
      redirect_to(root_url) and return
    end
  end
  
  def toggle
    @earl = Earl.find(params[:earl_id])
    unless (current_user.owns?(@earl) || current_user.admin?)
      render(:json => {:message => t('items.toggle_error')}.to_json) and return
    end
    @choice = Choice.find(params[:id], :params => {:question_id => @earl.question_id})
    @choice.active = !@choice.active
    
    verb = {true => t('items.list.activated'), false => t('items.list.deactivated')}
    
    respond_to do |format|
        format.xml  {  head :ok }
        format.js  { 
          
        if @choice.save
          render :json => {:verb => verb[@choice.active?], :active => @choice.active?}.to_json
        else
          render :json => {:verb => verb[!@choice.active?], :active => !@choice.active?}.to_json
        end
        }
    end
  end
  
  def update
    choice = Choice.find(params[:id], :params => {:question_id => params[:question_id]})

    if params[:choice]
      choice.data = params[:choice][:data]
      related_choice_id = params[:choice][:related_choice_id]
      related_choice_id = nil if related_choice_id.blank?
      choice.related_choice_id = related_choice_id
    end
    choice.save

    redirect_to admin_question_url(params[:question_id])
  end

  def activate
    set_choice_active(true,  t('items.you_have_successfully_activated'))
  end
  
  def deactivate
    set_choice_active(false, t('items.you_have_successfully_deactivated'))
  end

  def rotate
    if @photocracy
       @choice = Choice.find(params[:id], :params => {:question_id => params[:question_id]})
       @image = Photo.find(@choice.data.strip)
       rotation = params[:deg].to_f
       rotation ||= 90 # Optional, otherwise, check for nil!
    
       @image.rotate!(rotation)
       flash[:notice] = "The image has been rotated. If it does not appear rotated on your screen, please hit the reload button on your browser."
    end
     
    redirect_to question_choice_path
  end
  
  protected 

  def set_choice_active(value, success_message)
    @choice = Choice.find(params[:id], :params => {:question_id => @earl.question_id})
    @choice.active = value
    
    respond_to do |format|
       if @choice.save
         flash[:notice] = success_message + " '#{@choice.attributes['data']}'"
       else
         flash[:notice] = "There was an error, could not save choice settings"
       end
       format.html {redirect_to consultation_earl_url(@earl.consultation, @earl) and return}
    end

  end
  
end
