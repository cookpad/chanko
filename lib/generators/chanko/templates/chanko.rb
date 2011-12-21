module <%= class_name %>
  include Chanko::Unit

=begin
  active_if :always_true do |context, options|
    # "context' is invoking context such as controller
    true
  end

  scope(:controller) do
    callback(:show) do
    end
  end

  scope(:view) do
    callback(:show) do
      render :partial => "/show"
    end
  end

  models do
    expand("Recipe") do
      def your_method
      end

      class_methods do
        def your_class_method
        end
      end
    end
  end

  shared("your_shared_method") do
    'hello'
  end

  helpers do
    def your_helper_method
    end
  end
=end

end
