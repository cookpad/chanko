module Chanko
  module Test
    load_klasses = %w(macro invoker mock)
    load_klasses.each do |klass|
      autoload klass.classify, "chanko/test/#{klass}"
    end
  end
end
