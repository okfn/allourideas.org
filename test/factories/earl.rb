Factory.define :earl do |earl|
  earl.sequence(:name) { |n| "Earl #{n}" }
  earl.association(:user)
  earl.association(:question)
  earl.consultation { |e| e.association(:consultation_without_earls) }
end

Factory.define :earl_without_question, :parent => :earl do |earl|
  earl.question nil
end
