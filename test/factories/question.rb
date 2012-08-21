Factory.define :question do |q|
	q.name "test name"
	q.ideas "samplechoice1\nsamplechoice2"
end

Factory.define :invalid_question, :parent => :question do |q|
  q.name nil
end
