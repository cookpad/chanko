module Chanko
  module Test
    module Mock
      def mock_unit(class_name, _scope=nil, pair = {}, options={})
        obj = Class.new(::Object)
        ::Object.const_set(class_name, obj)
        const = Object.const_get(class_name)
        self.classes << const
        const.class_eval do
          include Chanko::Unit
          if disable = options.delete(:disable)
            active_if { false }
          else
            active_if { true }
          end

          if _scope
            scope(_scope) do
              pair.each do |key, hash|
                unless hash.kind_of?(Hash)
                  function(key) { instance_variable_set("@#{key}", hash) }
                  next
                end
                value = hash.delete(:value)

                function(key, hash) do
                  if value.kind_of?(Proc)
                    instance_eval(&value)
                  else
                    instance_variable_set("@#{key}", value)
                  end
                end
              end
            end
          end
        end
        const
      end
      alias_method :ext_mock, :mock_unit

      mattr_accessor :classes
      self.classes = []
      @enables = Chanko::Tools.nested_hash(1)
      class<<self
        def reset!
          while klass = self.classes.shift
            Chanko::Loader.deregister(klass)
            ::Object.send(:remove_const, klass.name)
          end
          @enables = Chanko::Tools.nested_hash(1)
        end

        #TODO move to other file
        def enabled?(context, unit, options={})
          return nil unless unit
          user = options[:user] || context.instance_variable_get("@login_user") || context.instance_variable_get("@current_user")
          all = nil
          return @enables[symbolize(unit)][all] unless user

          unless @enables[symbolize(unit)][user.id].nil?
            return @enables[symbolize(unit)][user.id]
          else
            return @enables[symbolize(unit)][all]
          end
        end

        def enable(unit, user_id, options)
          user_id = user_id.id if user_id.is_a?(User)
          Chanko::Loader.load_unit(unit)
          @enables[symbolize(unit)][user_id] = true
        end

        def disable(unit, user_id, options)
          user_id = user_id.id if user_id.is_a?(User)
          Chanko::Loader.load_unit(unit)
          @enables[symbolize(unit)][user_id] = false
        end

        def symbolize(name)
          case name
          when String
            name.underscore.to_sym
          when Symbol
            symbolize(name.to_s)
          else
            symbolize(name.name)
          end
        end
      end
    end
  end
end

