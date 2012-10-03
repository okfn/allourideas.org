unless Rails.env == "development" || Rails.env == "test"
   include SendGrid
end
class IdeaMailer < ActionMailer::Base

  default_url_options[:host] = APP_CONFIG[:HOST]

  def notification(earl, question, choice_text, choice_id, photocracy=false)
    setup_email(earl.user, photocracy)

    @subject += "#{photocracy ? 'photo' : 'idea'} added to question: #{question.name}"
    @body[:question_name] = question_name
    @body[:earl] = earl
    @body[:choice_text] = choice_text
    @body[:choice_id] = choice_id
    @body[:choice_url] = get_choice_url(question, choice_id, photocracy, true)
    @body[:photocracy] = photocracy
    @body[:object_type] = photocracy ? I18n.t('common.photo') : I18n.t('common.idea')

  end
  
  def notification_for_active(earl, question, choice_text, choice_id, photocracy=false)
    setup_email(earl.user, photocracy)
    @subject += "#{photocracy ? 'photo' : 'idea'} added to question: #{question.name}"
    @body[:question_name] = question_name
    @body[:earl] = earl
    @body[:choice_text] = choice_text
    @body[:choice_id] = choice_id
    @body[:choice_url] = get_choice_url(question, choice_id, photocracy, false)
    @body[:photocracy] = photocracy
    @body[:object_type] = photocracy ? I18n.t('common.photo') : I18n.t('common.idea')
  end

  def flag_notification(question, choice_id, choice_data, explanation, photocracy=false)
    earl = question.earl
    setup_email(earl.user, photocracy)
    
    @subject += "Possible inappropriate #{photocracy ? 'photo' : 'idea'} flagged by user"
    @bcc = photocracy ? APP_CONFIG[:INFO_PHOTOCRACY_EMAIL] : APP_CONFIG[:INFO_ALLOURIDEAS_EMAIL]
    @body[:earl] = earl
    @body[:choice_id] = choice_id
    @body[:choice_data] = choice_data
    @body[:choice_url] = get_choice_url(question, choice_id, photocracy, true)
    @body[:explanation] = explanation
    @body[:photocracy] = photocracy
    @body[:object_type] = photocracy ? I18n.t('common.photo') : I18n.t('common.idea')
  end
  
  def extra_information(user, question_name, information, photocracy=false)
    @recipients  = APP_CONFIG[:SIGNUPS_ALLOURIDEAS_EMAIL]
    @from        = APP_CONFIG[:INFO_ALLOURIDEAS_EMAIL]
    @subject     = photocracy ? "[Photocracy] " : "[All Our Ideas] "
    @sent_on     = Time.now
    @body[:user] = user
    @body[:host] = photocracy ? "www.photocracy.org" : "www.allourideas.org"
    @body[:photocracy] = photocracy

    @subject += "Extra Information included in #{question_name}"

    @body[:question_name] = question_name
    @body[:information] = information
  end

  def export_data_ready(email, link, photocracy=false)
     setup_email(nil, photocracy)
     @recipients  = email
     @subject += "Data export ready"
     @body[:url] = link
     @body[:photocracy] = photocracy
  end

  def export_failed(email, photocracy=false)
    setup_email(nil, photocracy)
    @recipients = email
    @subject += "Data export failed"
    @body[:photocracy] = photocracy
  end
  
  protected
    def setup_email(user, photocracy=false)
      if user
        @recipients  = user.email
      end
      @from        = photocracy ? APP_CONFIG[:INFO_PHOTOCRACY_EMAIL] : APP_CONFIG[:INFO_ALLOURIDEAS_EMAIL]
      @subject     = photocracy ? "[Photocracy] " : "[All Our Ideas] "
      @sent_on     = Time.now
      @body[:user] = user
      @body[:host] = "www.#{photocracy ? 'photocracy' : 'allourideas'}.org"

    end

    def get_choice_url(question, choice_id, photocracy, activate)
       url_options = {:question_id => question.id, :id => choice_id}
       url_options.merge!(:photocracy_mode => true) if photocracy && Rails.env == "cucumber"
       url_options.merge!(:login_reminder => true) if photocracy

       if photocracy
           choice_path = question_choice_path(url_options)
       elsif activate
           choice_path = activate_question_choice_path(url_options)
       else
           choice_path = deactivate_question_choice_path(url_options)
       end

       if photocracy
	       choice_url = "http://#{APP_CONFIG[:PHOTOCRACY_HOST]}#{choice_path}"
       else
	       choice_url = "http://#{APP_CONFIG[:HOST]}#{choice_path}"
       end
       choice_url
    end

end
