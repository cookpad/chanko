module InactiveUnit
  include Chanko::Unit

  active_if { false }

  scope(:view) do
    function(:inactive) do
      "inactive"
    end
  end
end
