# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Chanko" do
  shared_examples_for 'callback' do
    before { raise_chanko_exception }
    let(:controller) do
      ApplicationController.new.tap do |controller|
        controller.request = ActionController::TestRequest.new
        controller.response = ActionController::TestResponse.new
      end
    end

    let(:view) do
      ActionView::Base.new.tap {|view| view.output_buffer = '' }
    end

    context 'controller' do
      before do
        ext_mock("RenderTest")
      end

      it 'render text' do
        callback = Chanko::Callback.new(:hello, RenderTest) do
          render :text => 'hello'
        end
        callback.invoke!(controller).should == 'hello'
        Array.wrap(controller.response_body).first.should == 'hello'
      end

      it 'render inline' do
        callback = Chanko::Callback.new(:hello, RenderTest) do
          render :inline => "<%= 'hello' -%>"
        end
        callback.invoke!(controller).should == 'hello'
        Array.wrap(controller.response_body).first.should == 'hello'
      end
    end

    context 'view' do
      let(:callback) do
        Chanko::Callback.new(:render, RenderTest) { render :text => 'hello' }
      end

      before do
        ext_mock("RenderTest")
        @_default_view_type = Chanko.config.default_view_type
      end

      after do
        Chanko.config.default_view_type = @_default_view_type
      end

      it 'should render as plain' do
        expect = 'hello'
        callback.invoke!(view, :type => :plain).should == expect
        view.output_buffer.should == ''
      end

      it 'should render as inline' do
        expect = '<span class="extension ext_render_test ext_render_test-render">hello</span>'
        callback.invoke!(view, :type => :inline).should == expect
        view.output_buffer.should == ''
      end

      it 'should render as block' do
        expect = '<div class="extension ext_render_test ext_render_test-render">hello</div>'
        callback.invoke!(view, :type => :block).should == expect
        view.output_buffer.should == ''
      end

      it 'should render as default' do
        Chanko.config.default_view_type = :block
        expect = '<div class="extension ext_render_test ext_render_test-render">hello</div>'
        callback.invoke!(view).should == expect
        Chanko.config.default_view_type = :plain
        expect = 'hello'
        callback.invoke!(view).should == expect
      end

      it 'should return as string if block is not given' do
        expect = '<div class="extension ext_render_test ext_render_test-render">hello</div>'
        callback.invoke!(view).should == expect
        view.output_buffer.should == ''
      end

      it 'should return as string if block is given' do
        expect = '<div class="extension ext_render_test ext_render_test-render">hello</div>'
        callback.invoke!(view) {}.should == expect
        view.output_buffer.should == ''
      end

      context 'default' do
        let(:default_callback) { Chanko::Callback.default { '<div>hoge</div>' } }

        before do
          Chanko.config.default_view_type = :plain
        end

        subject { Chanko::Callback.default { '<div>hoge</div>' } }

        it 'default_callback unit is default unit' do
          default_callback.ext.should == Chanko::Unit::Default
        end

        it 'should escape' do
          default_callback.invoke!(view, :capture => true).should == ERB::Util.html_escape('<div>hoge</div>')
        end
      end
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_behaves_like 'callback'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_behaves_like 'callback'
  end
end


