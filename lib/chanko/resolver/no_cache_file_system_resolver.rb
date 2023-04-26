module Chanko
  module Resolver
    if defined?(ActionView::OptimizedFileSystemResolver)
      class NoCacheFileSystemResolver < ActionView::OptimizedFileSystemResolver
        def query(path, details, formats, locals, cache:)
          super(path, details, formats, locals, cache: false)
        end
      end
    end
  end
end
