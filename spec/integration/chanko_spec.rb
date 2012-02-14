require 'spec_helper'

describe 'Invoker', :type => :integration do
  before do
    ext_mock("AcceptanceTest")
    AcceptanceTest.class_eval do
      scope(:view) do
        callback(:render) { render :partial => '/show' }
      end
    end
  end

  it 'invoke with view' do
    visit '/invoke/with_view'
    page.should have_content('render view file')
    page.should have_selector('div', :class => %w(extension ext_acceptance_test ext_acceptance_test-render))
  end
end
