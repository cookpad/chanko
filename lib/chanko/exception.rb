module Chanko
  class Exception < StandardError
    class MissingActiveIfDefinition < Exception; end
    class MissingFunction < Exception; end
  end
end
