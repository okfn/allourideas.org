require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Earl do

  describe "validations" do
    it "should be valid given valid attributes" do
      Factory.build(:earl).should be_valid
    end

    it "should not be valid if its question is not valid" do
      earl = Factory.build(:earl)
      question = Factory.build(:question, :name => nil)

      earl.question = question

      earl.save.should be_false
    end

    it "should not be valid if it has a reserved name" do
      earl = Factory.build(:earl)

      Earl.reserved_names.each do |reserved_name|
        earl.name = reserved_name
        earl.should_not be_valid
      end
    end

    it "should not be valid if name is not unique" do
      earl = Factory(:earl)
      Factory.build(:earl, :name => earl.name).should_not be_valid
    end
  end

end
