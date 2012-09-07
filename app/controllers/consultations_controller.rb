class ConsultationsController < ApplicationController
  before_filter :authenticate, :except => [:new, :create]

  def show
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
      redirect_to consultation_url(@consultation)
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
    @earl = Earl.create(params[:earl])
    @earl.consultation = @consultation

    if @earl.save
      redirect_to consultation_url(@consultation)
    else
      render :show
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
