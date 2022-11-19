module Chanko
  module Config
    class << self
      attr_accessor(
        :auto_reload,
        :backtrace_limit,
        :cache_units,
        :compatible_css_class,
        :enable_logger,
        :propagated_errors,
        :proxy_method_name,
        :raise_error,
        :resolver,
      )

      def reset
        self.auto_reload          = Rails.env.development? || Rails.env.test?
        self.backtrace_limit      = 10
        self.compatible_css_class = false
        self.enable_logger        = true
        self.propagated_errors    = []
        self.proxy_method_name    = :unit
        self.raise_error          = Rails.env.development?
        self.resolver             = Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('7') ? ActionView::FileSystemResolver : ActionView::OptimizedFileSystemResolver
        self.units_directory_path = "app/units"
      end

      def units_directory_path=(path)
        @units_directory_path = path
      end

      def units_directory_path
        @resolved_units_directory_path ||= begin
          pathname = Pathname(@units_directory_path)
          if pathname.absolute?
            @units_directory_path
          else
            Rails.root.join(@units_directory_path).to_s
          end
        end
      end
    end

    reset
  end
end
