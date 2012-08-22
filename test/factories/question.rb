Factory.define :question do |q|
	q.ideas "samplechoice1\nsamplechoice2"
end

Factory.define :invalid_question, :parent => :question do |q|
  q.ideas nil
end
