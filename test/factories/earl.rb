Factory.define :earl do |earl|
  earl.sequence(:name) { |n| "Earl #{n}" }
  earl.association(:user)
  earl.association(:question)
  earl.association(:consultation)
end
