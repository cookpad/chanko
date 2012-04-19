module TestingUnit
  include Chanko::Unit
  active_if do |context, unit, options|
    true
  end

  scope("Example::UnitController") do
    function(:hello) do
      render "/testing_hello"
    end
  end

  scope(:view) do
    function(:partial_hello) do
      render :partial => "/partial_hello"
    end
  end

  helpers do
    def testing_hello
      "testing hello"
    end
  end
end
