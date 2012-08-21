Factory.define :earl do |earl|
  earl.sequence(:name) { |n| "Earl #{n}" }
  earl.association(:question)
  earl.association(:user)
end
