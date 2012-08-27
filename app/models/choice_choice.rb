class ChoiceChoice < ActiveRecord::Base
  belongs_to :choice
  belongs_to :related_choice, :class_name => :choice

  validates_presence_of :choice_id
  validates_uniqueness_of :choice_id
  validates_uniqueness_of :related_choice_id, :scope => :choice_id
end
