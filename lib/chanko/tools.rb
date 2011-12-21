module Chanko
  module Tools
    module_function
    def nested_hash(number=1)
      if number > 0
        Hash.new { |h,v| h[v] = Chanko::Tools.nested_hash(number - 1 ) }
      else
        Hash.new
      end
    end
  end
end
