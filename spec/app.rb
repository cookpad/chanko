require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_record'
require 'database_cleaner'

::ActiveRecord::Base.configurations = {'test' => {:adapter => 'sqlite3', :database => ':memory:'}}
::ActiveRecord::Base.establish_connection('test')

module Chanko
  class Application < Rails::Application
    config.secret_token = '0606ef9eca2318ec13ae836a4f786232'
    config.session_store :cookie_store, :key => "_myapp_session"
    config.active_support.deprecation = :log
    initialize!
  end
end

require 'app/route.rb'
require 'app/controller'


class User < ::ActiveRecord::Base
end

class Recipe < ::ActiveRecord::Base
end

class CreateAllTables < ::ActiveRecord::Migration
  def self.up
    create_table(:users) {|t| t.string :name }
    create_table(:recipes) {|t| t.string :title; t.integer :user_id }
  end
end

