class Consultation < ActiveRecord::Base
  belongs_to :user
  has_many :earls
  validates_presence_of :name
  accepts_nested_attributes_for :user
  accepts_nested_attributes_for :earls

  attr_accessible :name, :user_attributes, :earls_attributes

  def votes_count
    earls.map(&:votes_count).inject(:+) || 0
  end

  def activate!
    self.active = true
    save!
  end
end
