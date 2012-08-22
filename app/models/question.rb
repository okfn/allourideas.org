class Question < ActiveResource::Base
  self.site = API_HOST
  self.user = PAIRWISE_USERNAME
  self.password = PAIRWISE_PASSWORD

  attr_accessor :question_text, :ideas, :url, :information, :email, :password
  
  def self.find_id_by_slug(slug)
    Earl.find(slug).question_id rescue nil
  end
  
  def earl
    Earl.find_by_question_id(id) rescue nil
  end

  def user_can_view_results?(user, earl)
    if self.show_results?
      return true
    else
      return (!user.nil? && (user.owns?(earl) || user.admin?))
    end
  end
  
  def slug
    earl.slug.name if earl
  end
 
  %w(name url the_name ideas).each do |attr|
    define_method attr do
      attributes[attr]
    end
  end 
  
  def active_choices
    self.choices_count - self.inactive_choices_count
  end

  def choices_count
    attributes['choices_count'] || 0
  end

  def ideas=(new_ideas)
	  attributes['ideas'] = new_ideas
  end
  
  def creator_id
    c = attributes['local_identifier']
    c = c.first if c.is_a?(Array)
    c.to_i
  end

  def creator
    User.find(creator_id)
  end

  def it_should_autoactivate_ideas
      attributes['it_should_autoactivate_ideas']
  end

  def testmethod
	  puts "TEST METHOD"
  end
  
  def valid?(photocracy=false)
    self.validate(photocracy)
    errors.empty?
  end
  
  def validate(photocracy=false)
    errors.clear
    ideas_cannot_be_blank if !photocracy && choices_count.zero?

    errors
  end
  
  protected
  def ideas_cannot_be_blank
    errors.add("Ideas", "can't be blank") if (ideas.blank? || ideas == default_ideas_text)
  end

  def default_ideas_text
    "Add your own ideas here...\n\nFor example:\nMore hammocks on campus\nImprove student advising\nMore outdoor tables and benches\nVideo game tournaments\nStart late dinner at 8PM\nLower textbook prices\nBring back parking for sophomores"
  end
end
