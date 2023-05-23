unless defined?(ActionView::FileSystemResolver)
  require 'action_view/template/resolver'
end

module Chanko
  module Resolver
    class NoCacheFileSystemResolver < ActionView::FileSystemResolver
      def query(path, details, formats, locals, cache:)
        super(path, details, formats, locals, cache: false)
      end
    end
  end
end
