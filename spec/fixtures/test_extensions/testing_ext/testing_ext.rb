module TestingExt
  include Chanko::Unit
  active_if do |context, ext, options|
    true
  end

  scope("Example::ExtensionController") do
    callback(:hello) do
      render "/testing_hello"
    end
  end

  scope(:view) do
    callback(:partial_hello) do
      render :partial => "/partial_hello"
    end
  end

=begin
  models do
    expand("ExpandedModel") do
      #expanded_model.ext.has_many_associations
      has_many :has_many_associations
      has_one :has_one_association
      named_scope :exists, :conditions => {:deleted_at => nil}

      # expanded_model.ext.new_method
      def new_method
      end

      class_methods do
        # ExpandedModel.ext.cmethod
        def cmethod
        end
      end
    end
  end
=end

  helpers do
    def testing_hello
      "testing hello"
    end
  end
end
