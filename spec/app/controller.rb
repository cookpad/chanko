# helpers
module ApplicationHelper
  include Chanko::Invoker
end

class ApplicationController < ActionController::Base
  include Chanko::Invoker
  include Rails.application.routes.url_helpers
  def _routes() ::Rails.application.routes end
  def controller() parent_controller end
end

ActionView::TestCase::TestController.class_eval do
  include Chanko::Invoker
  include Rails.application.routes.url_helpers
  def _routes() ::Rails.application.routes end
  def controller() parent_controller end
end

ApplicationController.view_paths = File.join(File.dirname(__FILE__), 'views')
ActionView::TestCase::TestController.view_paths = File.join(File.dirname(__FILE__), 'views')


class InvokeController < ApplicationController
  layout 'application'
  unit_action :acceptance_test, :text

  def nested
    render :action => 'nested'
  end

  def with_view
    render :inline => <<-EOS
      <html>
        <body>
          <%= invoke(:acceptance_test, :render) %>
        </body>
      </html>
    EOS
  end

  def content_for_hello
  end
end

