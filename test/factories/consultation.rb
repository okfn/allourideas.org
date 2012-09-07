Factory.define :consultation do |c|
  c.sequence(:name) { |n| "Consultation #{n}" }
  c.association(:user)
  c.after_build { |consultation| Factory.build(:earl, :consultation => consultation) }
end
