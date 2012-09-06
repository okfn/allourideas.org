class ConsultationsController < ApplicationController
  before_filter :authenticate, :except => [:show, :new, :create]

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
    @consultation.user = current_user if signed_in?

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

  private
  def add_visitor_identifier_to_earls_question_attributes
    return unless params[:earl][:question_attributes]
    identifiers = { :visitor_identifier => request.session_options[:id],
                    :local_identifier => current_user.id }
    params[:earl][:question_attributes].merge!(identifiers)
  end

end
