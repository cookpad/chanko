module Chanko
  class Exception < StandardError
    class MissingActiveIfDefinition < Exception; end
    class MissingCallback < Exception; end
  end
end
