# Chanko
## What is Chanko
Chanko provides a simple framework for rapidly and safely prototyping new
features in your production Rails app, and exposing these prototypes to
specified segments of your user base.

With Chanko, you can release many concurrent features and independently manage
which users see them. If there are errors with any chanko, it will be
automatically removed, without impacting your site.

Please take a look at https://github.com/cookpad/chanko_sample which is a
simple example app using chanko.

Chanko is currently released as a beta.

## Supported versions
Ruby 1.8.7, 1.9.2

Rails 3.0.10 ~

## Install
Add to your Gemfile.
```ruby
gem 'chanko', :git => 'git://github.com/cookpad/chanko.git'
```
Run install.

```ruby
rails generate chanko:install
```
Add this code to ApplicationHelper.
```ruby
include Chanko::Invoker
include Chanko::Helper
```

## Files

Generate chanko.
```
rails generate chanko sample
      create  app/units/sample/sample.rb
      create  app/units/sample/views/_show.html.haml
      create  app/units/sample/stylesheets/tutorial.scss
      create  app/units/sample/images/logo.png
      create  app/units/sample/spec/models/sample_spec.rb
      create  app/units/sample/spec/controllers/sample_controller_spec.rb
      create  app/units/sample/spec/helpers/sample_helper_spec.rb
```

### app/units/sample/sample.rb
Main file. You write your model and controller logic in this file.

### app/units/sample/views
The view files for your chanko. Each chanko refers to its own views directory.

### app/units/sample/stylesheets/tutorial.scss
Write styles for your chanko in this file. These files will be merged during
startup or first access.

### app/units/sample/images/logo.png
The image files for this chanko.
If you manually created this directory, you should create a symbolic link from
app/units/sample/images to  (public or assets)/images/units/#{unit_name}
be sure to use the relative path.
If you used the generator, the symbolic link is automatically generated.

### app/units/sample/spec/
Spec files for this chanko go here.

## Syntax
```ruby
module Sample
  include Chanko::Unit

  # active_if's block is used to decide if the chanko is active or not.
  # context is the object which invoked the function.
  active_if :always_true do |context, options|
    true
  end

  shared(:hello) do |name|
    "hello #{name}"
  end

  scope(:controller) do
    function(:controller_show) do
      # controller code here
    end
  end

  scope(:view) do
    function(:view_show) do
      render :partial => "/show"
    end
  end

  models do
    expand("ExpandedModel") do
      #expanded_model.ext(:sample).has_many_associations
      has_many :has_many_associations
      has_one :has_one_association

      # should use lambda
      scope :exists, lambda { where(:deleted_at => nil) }

      # expanded_model_instance.ext.new_method
      def new_method
      end

      #expanded_mode.ext.new_method
      class_methods do
        def new_class_method
        end
      end
    end
  end

  helpers do
    # ext.helper_method
    def helper_method
    end
  end
end
```

## active_if
`active_if()` decides if the chanko is enabled or not. active_if receives an
arg of the invoked context, such as the controller.
The chanko is enabled when the block returns true.
```ruby
# activeif's block is used to decide if the chanko is active or not.
# context is the object which invoked the function.
active_if do |context, options|
  true
end
```

Also, `active_if()` accepts predefined symbols. `active_if()` evaluates the AND
result for all symbols and the block.
```ruby
# This definition means "the user is staff and the environment is not production"
active_if :staff, :not_production do |context, options|
  # some additional conditions
end
```

You can define additional symbols in lib/active_if_files/main.rb.
```ruby
Chanko::ActiveIf.define(:not_production?) do |context, options|
  !Rails.env.production?
end

Chanko::ActiveIf.define(:staff) do |context, options|
  user = options[:user] || context.instance_variable_get('@login_user')
  next false unless user
  next false unless user.staff?
  next true
end
```

When you want to use an OR condition, use `any()`.
```ruby
  # This means "the current user is staff or a paid user. And the environment is not production"
  active_if any(:staff, :paid), :not_production
```

## shared method
"shared()" is the syntax for shared method definitions. You can use the defined
method through functions of either :controller or :view. The block of a shared
method behaves like an instance method.
```ruby
  shared(:hello) do |name|
    "hello #{name}"
  end

  scope(:view) do
    function(:hello) do
      hello("alice")
    end
  end
```

## function
A `function()` is expanded in the calling code. This block's context behaves
like an invoked context, so you can access the original context's instance
variables. If you need to access local variables, a function provides a :locals
option that is similar to :locals use in render. Also similar to render,
you can omit to use :locals and give variables just as options when you don't
use options without :locals.
A function is scoped, and its scope is a restriction for the function. The
function is only called from scoped context.

```ruby
#scope can receive specified context such as "scope('UsersController')".
scope(:controller) do
  function(:controller_show) do
    # controller code here
  end
end
```

`invoke()` in your controller runs a function block if the active_if block
returns true. In this case, if active_if for the sample chanko is true, then
controller_show will be invoked in the chanko main.rb
```ruby
class UsersController
  def show
    invoke(:sample, :controller_show)
  end
end
```

`invoke()` can receive a block as a default fallback. The block is executed if
the active_if block returns false or the function raises an error.
  invoke(:sample, :controller_show) do
     default_behaviour
  end

`run_default()` method runs default block and return a result as string.
it is used by function block
```ruby
function(:hello) do
  result = run_default
  "#{result} + hello"
end
```

`invoke()` can receive multiple functions. "invoke" tries to run the functions
in turn. Only the first enabled function is executed.

```ruby
  #invoke doesn't run the second_unit function if first_unit is enabled.
  invoke([:first_unit, :show], [:second_unit, :show])
```

`invoke()` doesn't run if the specified chanko in the :if is disabled

```ruby
invoke(:sample, :show, :if => :depend_on_unit)
```

## expand
`expand()` expands existing model methods and adds chanko helper methods. The
expanded method is only used by the expanding chanko.
All expanded methods must be used in your code via the **ext** proxy like the sample below.

```ruby
user_instance.ext.expanded_method
```

You can write expanding methods for current models. The "models()" block
provides association and named_scope and class method syntax.
```ruby
models do
  expand("ExpandedModel") do
     #expanded_model.ext.has_many_associations
     has_many :has_many_associations
     has_one :has_one_association
     has_many :through_associations, :through => label(:has_many_associations)
     named_scope :exists, :conditions => {:deleted_at => nil}
      # expanded_model_instance.ext.new_method
     def new_method
     end

     #expanded_mode.ext.new_method
     class_methods do
      def cmethod
      end
    end
  end
end
```

When used as a symbol as an :include option for ActiveRecord, you must wrap
label with "ext.label()" syntax.
  User.find(:first, :include => [ext.label(:recipes)])

## Helpers
You can write chanko helpers.
```ruby
helpers do
  def helper_method
  end
end
```

And can use helpers in views and controllers via the **ext** proxy.
```ruby
function(:sample) { ext.hello }
helpers { def hello; 'hello'; end }
```

## Tips
To return from inside of an invoke block.
Use the following code.
```ruby
invoke(:hoge, :aaa) do
  redirect_to xxx
end
return if performed?
```

Permanently activate or deactivate a chanko.
Use :always_true/:always_false on active_if.

```ruby
active_if :always_true # or :always_false
```

Invoke with before_filter.
Use block and invoke.

```ruby
before_filter :only => :index do |controller|
  controller.invoke(:your_unit, :before_function)
end
```

Check the status of a particular chanko. In almost all situations, context is controller.
```ruby
ext(:sample).active? #=> return boolean
```

When invoking a chanko in a view context to render some output, you may want to suppress the default
behavior of wrapping the output in a div.
To suppress the div you can pass a special option when invoking the chanko:
```ruby
# :type => :plain renders the view without any wrapper
# :type => :inline renders the view with a span element wrapper
# default is a div
invoke(:sample, :some_method, :type => :plain)
```
