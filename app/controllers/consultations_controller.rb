class ConsultationsController < ApplicationController
  before_filter :authenticate, :except => [:show, :new, :create]

  def index
    @consultations = current_user.consultations
    redirect_to new_consultation_url if @consultations.empty?
  end

  def show
    consultation = Consultation.find(params[:id])
    random_earl = consultation.earls.active.choice
    if random_earl
      redirect_to consultation_earl_url(consultation, random_earl)
    else
      redirect_to root_url
    end
  end

  def admin
    @consultation = current_user.consultations.find(params[:id])
  end

  def new
    @consultation = Consultation.new
    if signed_in?
      @consultation.user = current_user
    else
      @consultation.build_user
    end
  end

  def create
    @consultation = Consultation.new(params[:consultation])
    @consultation.user_id = current_user.id if signed_in?

    if @consultation.save
      sign_in(@consultation.user) unless signed_in?
      redirect_to admin_consultation_url(@consultation)
    else
      render :new
    end
  end

  def update
    consultation = current_user.consultations.find(params[:id])

    respond_to do |format|
      if consultation.update_attributes(params[:consultation])
        format.json { render :json => { :status => 'success', :consultation => consultation.attributes }, :status => 200 }
      else
        format.json { render :json => { :status => 'failed', :consultation => consultation.attributes }, :status => 403 }
      end
    end
  end

  def create_earl
    add_visitor_identifier_to_earls_question_attributes
    @consultation = current_user.consultations.find(params[:id])
    @earl = @consultation.earls.build(params[:earl])

    if @earl.save
      redirect_to admin_consultation_url(@consultation)
    else
      render :admin
    end
  end

  def toggle
    consultation = current_user.consultations.find(params[:id])

    respond_to do |format|
      format.js  {
        consultation.active = !(consultation.active)
        verb = consultation.active ? t('items.list.activated') : t('items.list.deactivated')
        if consultation.save!
          render :json => {:message => "You've just #{verb.downcase} your consultation", :verb => verb}.to_json
        else
          render :json => {:message => "You've just #{verb.downcase} your consultation", :verb => verb}.to_json
        end
      }
    end
  end

  def results
    @consultation = Consultation.find(params[:id])
    redirect_to root_url unless (@consultation.user == current_user) || current_user.admin?
    @choices = choices_with_earl_sorted_by_score(@consultation.earls)
  end

  private
  def add_visitor_identifier_to_earls_question_attributes
    return unless params[:earl][:question_attributes]
    identifiers = { :visitor_identifier => request.session_options[:id],
                    :local_identifier => current_user.id }
    params[:earl][:question_attributes].merge!(identifiers)
  end

  def choices_with_earl_sorted_by_score(earls)
    earls.map do |earl|
      choices = Choice.find(:all, :params => { :question_id => earl.question_id })
      choices.map { |c| c.earl = earl; c }
    end.flatten.sort_by(&:score).reverse
  end

end
