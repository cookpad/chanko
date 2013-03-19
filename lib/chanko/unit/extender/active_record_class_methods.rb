module Chanko
  module Unit
    class Extender
      module ActiveRecordClassMethods
        delegate(
          :apply_modules,
          :arel,
          :array_of_strings?,
          :build_arel,
          :build_joins,
          :build_select,
          :build_where,
          :create_with,
          :custom_join_sql,
          :eager_load,
          :extending,
          :from,
          :group,
          :having,
          :includes,
          :joins,
          :limit,
          :lock,
          :offset,
          :order,
          :preload,
          :readonly,
          :reorder,
          :reverse_order,
          :reverse_sql_order,
          :scope,
          :select,
          :where,
          :to => :@mod
        )

        %w[belongs_to has_many has_one].each do |method_name|
          class_eval <<-EOS
            def #{method_name}(*args, &block)
              label   = args.shift.to_s
              name    = @prefix + label
              options = args.extract_options!
              options = options.reverse_merge(:class_name => label.singularize.camelize)
              args << options
              @mod.#{method_name}(name.to_sym, *args, &block)
            end
          EOS
        end

        def scope(*args, &block)
          name = @prefix + args.shift.to_s
          @mod.scope(name, *args)
        end
      end
    end
  end
end
