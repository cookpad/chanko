# Chanko [![Build Status](https://travis-ci.org/cookpad/chanko.svg?branch=master)](https://travis-ci.org/cookpad/chanko) [![Code Climate](https://codeclimate.com/github/cookpad/chanko/badges/gpa.svg)](https://codeclimate.com/github/cookpad/chanko) [![Coverage Status](https://coveralls.io/repos/cookpad/chanko/badge.svg?branch=master)](https://coveralls.io/r/cookpad/chanko?branch=master)

http://cookpad.github.io/chanko/

Chanko provides a simple framework for rapidly and safely prototyping new
features in your production Rails app, and exposing these prototypes to
specified segments of your user base.

With Chanko, you can release many features concurrently and manage target users independently.
When any errors are raised from chanko's features,
it will be automatically hidden and fallback to its normal behavior.

## Requirements
* Ruby >= 3.0.0
* Rails >= 6.1.0

## Usage
Add to your Gemfile.

```ruby
gem "chanko"
```

## Files
Chanko provides a generator to create templates of an unit.

```
$ rails generate chanko:unit example_unit
      create  app/units/example_unit
      create  app/units/example_unit/example_unit.rb
      create  app/units/example_unit/views/.gitkeep
      create  app/units/example_unit/images/.gitkeep
      create  app/units/example_unit/javascripts/.gitkeep
      create  app/units/example_unit/stylesheets/.gitkeep
      create  app/assets/images/units/example_unit
      create  app/assets/javascripts/units/example_unit
      create  app/assets/stylesheets/units/example_unit
```

## Invoke
You can invoke the logics defined in your units via `invoke` and `unit` methods.
In controller class context, `unit_action` utility is also provided.
The block passed to `invoke` is a fallback executed if any problem occurs in invoking.

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  unit_action :example_unit, :show

  def index
    invoke(:example_unit, :index) do
      @users = User.all
    end
  end
end
```

```
-# app/views/examples/index.html.slim
= unit.helper_method
= invoke(:example_unit, :render_example)
```

## Unit
You can see [the real example of an unit module file](https://github.com/cookpad/chanko/blob/master/spec/dummy/app/units/entry_deletion/entry_deletion.rb).

### module
You can define your MVC code here.

```ruby
# app/units/example_unit/example_unit.rb
module ExampleUnit
  include Chanko::Unit
  ...
end
```

### active_if
This block is used to decide if this unit is active or not.
`context` is the receiver object of `invoke`.
`options` is passed via `invoke(:foo, :bar, :active_if_options => { ... })`.
By default, this is set as `active_if { true }`.

```ruby
active_if do |context, options|
  true
end
```

### raise_error
By default, any error raised in production env is ignored.
`raise_error` is used to force an unit to raise up errors occured in invoking.
You can force all units to raise up errors by `Config.raise_error = true`.

```ruby
raise_error
```

### function
In controller or view context, you can call functions defined by `function`
via `invoke(:example_unit, :function_name)`.

```ruby
scope(:controller) do
  function(:show) do
    @user = User.find(params[:id])
  end

  function(:index) do
    @users = User.active
  end
end
```

### render
In version 2 and earlier, Chanko extended Rails' search path to include the views path of the unit. This functionality has been discontinued. To maintain the views path under the unit, you will need to manually create a symbolic link in app/views/units to access it.

### shared
You can call methods defined by `shared` in invoking.

```ruby
shared(:hello) do |world|
  "Hello, #{world}"
end
```

### helpers
You can call helpers in view via unit proxy like `unit.helper_method`.

```ruby
helpers do
  def helper_method
    "helper method"
  end
end
```

## Example
https://github.com/cookpad/chanko/tree/master/spec/dummy  
Chanko provides an example rails application in spec/dummy directory.

```
$ git clone git@github.com:cookpad/chanko.git
$ cd chanko/spec/dummy
$ bundle install
$ bundle exec rake db:create db:migrate
$ rails s
$ open http://localhost:3000
```
