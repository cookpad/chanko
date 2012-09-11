# coding: utf-8
module <%= class_name %>
  include Chanko::Unit

=begin
  active_if :always_true do |context, options|
    # "context' is invoking context such as controller
    true
  end

  scope(:controller) do
    function(:show) do
    end
  end

  scope(:view) do
    function(:show) do
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
