class Earl < ActiveRecord::Base
  belongs_to :user
  belongs_to :consultation
  belongs_to :question
  accepts_nested_attributes_for :question
  validates_presence_of :name, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :name, :scope => :consultation_id
  validates_length_of :welcome_message, :maximum=>350, :allow_nil => true, :allow_blank => true
  has_friendly_id :name, :use_slug => true, :scope => :consultation_id
  has_attached_file :logo, :whiny_thumbnails => true, :styles => { :banner => "450x47>", :medium => "150x150>" }

  delegate :votes_count, :to => :question

  named_scope :photocracy, :conditions => { :photocracy => true }
  named_scope :not_photocracy, :conditions => { :photocracy => false }
  named_scope :by_creation_date, :order => "created_at ASC"
  named_scope :active, :conditions => { :active => true }

  before_create :set_user_to_consultations_user, :update_question_user_if_theres_one

  def self.voter_map(earl_slug, type)
    if type == "all"
      votes_by_sids = Question.get(:all_num_votes_by_visitor_id, :scope => "all_votes")
    elsif type == 'all_photocracy_votes'
      votes_by_sids = Question.get(:all_num_votes_by_visitor_id, :scope => type)
    elsif type == 'all_aoi_votes'
      votes_by_sids = Question.get(:all_num_votes_by_visitor_id, :scope => type)
    elsif type == "all_creators"
      votes_by_sids = Question.get(:all_num_votes_by_visitor_id, :scope => "creators")
    elsif type == "uploaded_ideas"
         
      earl = Earl.find earl_slug
      question = Question.new
      question.id = earl.question_id
      votes_by_sids = question.get(:object_info_by_visitor_id, :object_type => 'uploaded_ideas')
    elsif type == "bounces"
      earl = Earl.find earl_slug
      question = Question.new
      question.id = earl.question_id
      votes_by_sids = question.get(:object_info_by_visitor_id, :object_type => 'bounces')

    elsif type == "votes"
      earl = Earl.find earl_slug
      question = Question.new
      question.id = earl.question_id
      votes_by_sids = question.get(:object_info_by_visitor_id, :object_type => 'votes')
    end
     
    votes_by_geoloc= {}
    object_total = 0
    votes_by_sids.each do |vote|
      sid = vote["visitor_id"]
      num_votes = vote["count"]
      num_votes = num_votes.to_i
      session = SessionInfo.find_by_session_id(sid)

      if type == "bounces" &&  session.clicks.size > 1
        next
      end

      object_total += num_votes
      if session.nil? || session.loc_info.nil? 
        if votes_by_geoloc["Unknown Location"].nil?
          votes_by_geoloc["Unknown Location"] = {}
          votes_by_geoloc["Unknown Location"][:num_votes] = num_votes
        else 
          votes_by_geoloc["Unknown Location"][:num_votes] += num_votes
        end

        next
      end

   #   if session.loc_info.empty?
   #     loc = Geokit::Geocoders::MultiGeocoder.geocode(session.ip_addr)
   #     if loc.success
   #       session.loc_info= {}
   #       session.loc_info[:city] = loc.city
   #       session.loc_info[:state] = loc.state
   #       session.loc_info[:country] = loc.country
   #       session.loc_info[:lat] = loc.lat
   #       session.loc_info[:lng] = loc.lng
   #       session.save
   #     end
   #   end
       
      if !session.loc_info.empty?
        display_fields = [:city, :region, :country_code]

        display_text = []
        display_fields.each do|key|
          if session.loc_info[key] && !(/^[0-9]+$/ =~ session.loc_info[key])
            display_text << session.loc_info[key] 
          end
        end

        city_state_string = display_text.join(", ")
        if votes_by_geoloc[city_state_string].nil?
          votes_by_geoloc[city_state_string] = {}
          votes_by_geoloc[city_state_string][:lat] = session.loc_info[:latitude]
          votes_by_geoloc[city_state_string][:lng] = session.loc_info[:longitude]
          votes_by_geoloc[city_state_string][:num_votes] = num_votes
        else
          votes_by_geoloc[city_state_string][:num_votes] += num_votes
        end
      else
        if votes_by_geoloc["Unknown Location"].nil?
          votes_by_geoloc["Unknown Location"] = {}
          votes_by_geoloc["Unknown Location"][:num_votes] = num_votes
        else 
          votes_by_geoloc["Unknown Location"][:num_votes] += num_votes
        end
      end
    end

    return {:total => object_total, :votes_by_geoloc => votes_by_geoloc }
  end

  def active?
    consultation_active = true
    consultation_active = consultation.active if consultation
    super && consultation_active
  end
  alias :active :active?

  private

  def set_user_to_consultations_user
    self.user = consultation.user unless consultation.nil?
  end

  def update_question_user_if_theres_one
    return if question.nil? || user.nil?
    question.local_identifier = user_id
    question.save!
  end

end
