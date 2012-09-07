# FIXME: Remove this whenever we upgrade Rails
module ActiveResource::BugFixes
  def self.included(base) # :nodoc:
    base.class_eval do
      # ActiveResource::Base doesn't define save(with_params), so whenever
      # it's saved because of a association with an ActiveResource, Rails
      # complains.
      define_method(:save) { |*args| save_with_real_validation }
      define_method(:save!) { save }

      # See https://github.com/rails/rails/issues/7378
      define_method(:destroyed?) { false }

      # Needed for accepts_nested_attributes_for with an ActiveResource
      define_method(:marked_for_destruction?) { false }
    end
  end

  # See http://dev.rubyonrails.org/ticket/10985
  def save_with_real_validation # :nodoc:
    validate if respond_to? :validate
    validate_on_create if new? && respond_to?(:validate_on_create)
    validate_on_update if new? && respond_to?(:validate_on_update)
    valid? ? save_without_validation : false
  rescue ActiveResource::ResourceInvalid => error
    errors.from_xml(error.response.body)
    false
  end
end

ActiveResource::Base.send :include, ActiveResource::BugFixes

# ActiveResource::Errors don't defines each_error, but each is the same as
# ActiveRecord::Errors.each_errors. So we simply alias it here.
# This is needed for using accepts_nested_attributes_for with ActiveResource.
#
# vendor/ruby/1.8/gems/activerecord-2.3.14/lib/active_record/autosave_association.rb:283:in `association_valid?'
module ActiveResource
  class Errors
    alias :each_error :each
  end
end
