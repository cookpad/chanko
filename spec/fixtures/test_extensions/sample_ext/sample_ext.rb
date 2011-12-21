module SampleExt
  include Chanko::Unit
  active_if do |context, ext, options|
    case context
    when TrueClass
      next context
    when FalseClass
      next context
    else
      next true
    end
  end

  scope("Example::ExtensionController") do
    callback(:rendering_haml) do
      render "extension/rendering_haml", :layout => false
    end

    callback(:rendering) do
      render "extension/rendering", :layout => false
    end

    callback(:variable_test) do
      @success = true
    end

    callback(:view_files_must_not_be_used_without_ext) do
      #nothing todo
    end

    callback(:raise_error) do
      raise "hello"
    end

    callback(:helper_test_view) do
      render "/extension/helper_test_view"
    end
  end

  scope(:view) do
    callback(:samename) do
      render(:partial => "/same_partial")
    end

    callback(:render_partial) do
      render(:partial => "extension/partial")
    end

    callback(:render_partial_haml) do
      render(:partial => "extension/partial_haml")
    end

    callback(:render) do
      "render 1"
    end

    callback(:render2) do
      "render 2"
    end

    callback(:render_with_block) do
      "render with block #{run_default}"
    end

    callback(:render_with_inline) do
      "render with inline #{run_default}"
    end

    callback(:render_with_plain) do
      "render with plain #{run_default}"
    end

    callback(:helper) do
      "callback_helper_text #{run_default}"
    end

    callback(:raise_error) do
      raise
    end
  end

  models do
    expand("User") do
      has_one :aka_secure_user, :class_name => "SecureUser"
      has_many :aka_recipes, :class_name => "Recipe"
      scope :named_aka_recipes, :include => [label(:aka_recipes)]
      scope :existence, :conditions => ["dropped_at IS NULL"]
      scope :user, lambda { |id| {:conditions => ["id = ?", id]} }

      def sample_ext_hello
        'hello'
      end

      class_methods do
        def hello
          "hello"
        end
      end
    end

    expand("SecureUser") do
      belongs_to :aka_user, :class_name => "User", :foreign_key => "user_id"
    end

    expand("Recipe") do
      scope :published, :conditions => ["published_at IS NOT NULL"]
      class_methods do
        def hello
          "expanded hello"
        end
      end
    end

    expand("Recipe") do
      scope :test_exists, :conditions => {:deleted_at => nil}
    end

    expand("RecipeBase") do
      class_methods do
        def hello
          "recipe_base expanded hello"
        end
      end
    end
  end

  helpers do
    def helper_hello
      "helper_hello"
    end

    def helper_test
      invoke(:sample_ext, :helper, :capture => false) do
        "in_block_helper_text"
      end
    end
  end
end

