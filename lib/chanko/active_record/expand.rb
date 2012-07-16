module Chanko
  module ActiveRecord
    module Expand
      def self.included(obj)
        obj.send(:include, Chanko::Expand)
        obj.extend(ActiveRecordClassMethods)
        obj.class_eval do
          %w(has_many has_one belongs_to scope).each do |association|
            definitions = instance_variable_get("@__#{association}_definitions")
            instance_variable_set("@__#{association}_definitions", definitions || [])

            add_after_function do |target, prefix|
              begin
                instance_variable_get("@__#{association}_definitions").each do |name, options, block|
                  if block
                    target.send(association, "#{prefix}#{name}".to_sym, options, &block)
                  else
                    target.send(association, "#{prefix}#{name}".to_sym, options)
                  end
                end
              end
            end
          end

          %w(belongs_to).each do |association|
            add_after_function do |target, prefix|
              begin
                x = instance_variable_get("@__#{association}_definitions")
                instance_variable_get("@__#{association}_definitions").each do |name, options|
                  key = options[:foreign_key]
                  target.new.send("#{key}")  #generate method
                  target.class_eval do
                    alias_method "#{prefix}#{key}", "#{key}"
                    alias_method "#{prefix}#{key}=", "#{key}="
                  end
                end
              end
            end
          end
        end
      end

      module ActiveRecordClassMethods
        delegate :apply_modules, :arel, :array_of_strings?, :build_arel, :build_joins,
          :build_select, :build_where, :create_with, :custom_join_sql, :eager_load,
          :extending, :from, :group, :having, :includes, :joins, :limit, :lock, :offset,
          :order, :preload, :readonly, :reorder, :reverse_order, :reverse_sql_order,
          :select, :where, :to => "@klass"

        def has_many(*args, &block)
          name = args.shift
          options = args.shift || {}
          options.merge!(:class_name => name.to_s.singularize.camelize) unless options.key?(:class_name)
          instance_variable_get("@__has_many_definitions") << [name, options, block]
        end

        def has_one(*args, &block)
          name = args.shift
          options = args.shift || {}
          options.merge!(:class_name => name.to_s.singularize.camelize) unless options.key?(:class_name)
          instance_variable_get("@__has_one_definitions") << [name, options, block]
        end

        def belongs_to(*args, &block)
          name = args.shift
          options = args.shift || {}
          options.merge!(:class_name => name.to_s.singularize.camelize) unless options.key?(:class_name)
          options.merge!(:foreign_key => "#{name.to_s.singularize.underscore}_id") unless options.key?(:foreign_key)
          instance_variable_get("@__belongs_to_definitions") << [name, options, block]
        end

        def scope(*args, &block)
          name = args.shift
          options = args.shift || {}
          instance_variable_get("@__scope_definitions") << [name, options, block]
        end
      end
    end
  end
end
