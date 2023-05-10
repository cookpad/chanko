module Chanko
  class NoCacheFileSystemResolver < ActionView::FileSystemResolver
    def query(path, details, formats, locals, cache:)
      super(path, details, formats, locals, cache: false)
    end
  end

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

        if Rails::VERSION::MAJOR >= 7
          self.resolver = ActionView::FileSystemResolver
        else
          if Rails.env.development?
            self.resolver = Chanko::NoCacheFileSystemResolver
          else
            self.resolver = ActionView::OptimizedFileSystemResolver
          end
        end
        self.units_directory_path = "app/units"
      end

      def units_directory_path=(path)
        @units_directory_path = path
      end

      def units_directory_path
        @resolved_units_directory_path ||= Rails.root.join(@units_directory_path).to_s
      end
    end

    reset
  end
end
