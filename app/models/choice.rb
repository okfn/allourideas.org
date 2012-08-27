class Choice < ActiveResource::Base
  self.site = "#{API_HOST}/questions/:question_id/"
  self.user = PAIRWISE_USERNAME
  self.password = PAIRWISE_PASSWORD
  
  attr_accessor :name, :question_text, :question_ideas

  def question_id
    prefix_options[:question_id]
  end
  
  def data
    attributes['data']
  end

  def created_at
    attributes['created_at']
  end
  
  def activate!
    puts "about to activate choice, #{self.inspect}"
    self.active = true
    puts "about to save"
    self.save
    puts "saved"
  end
  
  def active?
    attributes['active']
  end

  def score
	  attributes['score']
  end

  def user_created
	  attributes['user_created']
  end

  def related_choice
    Choice.find(related_choice_id, :params => { :question_id => question_id }) if related_choice_id
  end

  def related_choice_id
    ChoiceChoice.find_by_choice_id(id).related_choice_id rescue nil
  end

  def related_choice=(choice)
    choice_choice.update_attributes!(:related_choice_id => nil) and return unless choice
    return if choice.question_id != question_id
    choice_choice.update_attributes!(:related_choice_id => choice.id)
    choice
  end

  private
  def choice_choice
    ChoiceChoice.find_or_create_by_choice_id(id)
  end
end
