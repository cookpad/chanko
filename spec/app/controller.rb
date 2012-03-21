class ApplicationController < ActionController::Base; end

class InvokeController < ApplicationController
  ext_action :acceptance_test, :text

  def with_view
    render :inline => <<-EOS
      <html>
        <body>
          <%= invoke(:acceptance_test, :render) %>
        </body>
      </html>
    EOS
  end
end

# helpers
Object.const_set(:ApplicationHelper, Module.new)
