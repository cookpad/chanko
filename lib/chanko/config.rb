module Chanko
  module Config
    class << self
      attr_accessor(
        :auto_reload,
        :backtrace_limit,
        :cache_units,
        :compatible_css_class,
        :enable_logger,
        :proxy_method_name,
        :raise_error,
        :resolver,
        :units_directory_path
      )

      def reset
        self.auto_reload          = Rails.env.development? || Rails.env.test?
        self.backtrace_limit      = 10
        self.compatible_css_class = false
        self.enable_logger        = true
        self.proxy_method_name    = :unit
        self.raise_error          = Rails.env.development?
        self.resolver             = ActionView::OptimizedFileSystemResolver
        self.units_directory_path = "app/units"
      end
    end

    reset
  end
end
