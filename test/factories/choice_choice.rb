Factory.define :choice_choice do |choice_choice|
  choice_choice.sequence(:choice_id) { |id| id }
  choice_choice.sequence(:related_choice_id) { |id| id }
end
