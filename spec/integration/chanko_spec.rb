require 'spec_helper'

describe 'Invoker', :type => :integration do
  before do
    ext_mock("AcceptanceTest")
    AcceptanceTest.class_eval do
      scope(:controller) do
        callback(:text) { render :text => 'hello'}
      end

      scope(:view) do
        callback(:render) { render :partial => '/show' }
      end
    end
  end

  it 'invoke with view' do
    visit '/invoke/with_view'
    (response || page).body.should have_content('render view file')
    (response || page).body.should match(/extension ext_acceptance_test ext_acceptance_test-render/)
  end

  it 'invoke by ext_action' do
    visit '/invoke/text'
    (response || page).body.should have_content('hello')
  end
end
