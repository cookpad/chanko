module SensitiveUnit
  include Chanko::Unit
  raise_error

  def self.ping
  end

  scope(:controller) do
    function(:outer_default) do
      invoke(:sensitive_unit, :inner_default) do
        SensitiveUnit.ping
        run_default
      end
    end

    function(:inner_default) do
      run_default
    end
  end
end
