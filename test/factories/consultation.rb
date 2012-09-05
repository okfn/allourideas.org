Factory.define :consultation_without_earls, :class => Consultation do |c|
  c.sequence(:name) { |n| "Consultation #{n}" }
  c.association(:user)
end

Factory.define :consultation, :parent => :consultation_without_earls do |c|
  c.after_build { |consultation| Factory.build(:earl, :consultation => consultation) }
end

