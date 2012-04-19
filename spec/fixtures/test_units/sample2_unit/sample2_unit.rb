module Sample2Unit
  include Chanko::Unit

  scope(:view) do
    function(:samename) do
      render(:partial => "/same_partial")
    end
  end

  async_view do
    def html
      render_partial("/same_partial")
    end
  end
end
