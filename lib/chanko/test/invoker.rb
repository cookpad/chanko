module Chanko
  module Test
    class Invoker
      include Chanko::Invoker
      include Chanko::MethodProxy
    end
  end
end
