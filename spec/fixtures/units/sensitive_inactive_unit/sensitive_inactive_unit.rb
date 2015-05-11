module SensitiveInactiveUnit
  include Chanko::Unit
  active_if { false }

  scope(:controller) do
    function(:outer) {}
    function(:innner) {}
  end
end
