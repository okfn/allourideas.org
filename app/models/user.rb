class User < ActiveRecord::Base
  include Clearance::User
  has_many :consultations
  has_many :earls
  has_many :session_infos
  has_many :clicks
  attr_accessible :default
  before_validation_on_create :set_confirmed_email
  
  def owns?(earl)
    earl.user_id == id
  end
  
  def email_activated=(value)
      self.email_confirmed = value
  end

  def set_confirmed_email
      self.email_activated = true
  end

  def admin?
      self.admin
  end
  
  def self.find_or_create_from_facebook(email, facebook_id)
    user = User.find_or_initialize_by_email(email)
    user.facebook_id = facebook_id
    user.save(false)
    user
  end
end
