# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Chanko" do
  shared_examples_for 'function' do
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

    describe 'with Exception to pass-through' do
      class ExceptionToPassThroughed < Exception; end
      class ExceptionToNotPassThroughed < Exception; end

      before(:all) do
        @config_save = Chanko.config.exceptions_to_pass_through.dup
        Chanko.config.exceptions_to_pass_through = [ExceptionToPassThroughed]
      end

      before do
        no_raise_chanko_exception
        mock_unit("RenderTest")
      end

      it "doesn't raise the exception when it's not in the list" do
        function = Chanko::Function.new(:hello, RenderTest) do
          raise ExceptionToNotPassThroughed
        end

        expect { function.invoke!(controller) }.to_not raise_error
      end

      it "raises the exception when it's in the list" do
        function = Chanko::Function.new(:hello, RenderTest) do
          raise ExceptionToPassThroughed
        end

        expect { function.invoke!(controller) }.to raise_error(ExceptionToPassThroughed)
      end


      after(:all)  {  Chanko.config.exceptions_to_pass_through= @config_save }
    end

    context 'controller' do
      before do
        mock_unit("RenderTest")
      end

      it 'render text' do
        function = Chanko::Function.new(:hello, RenderTest) do
          render :text => 'hello'
        end
        function.invoke!(controller).should == 'hello'
        Array.wrap(controller.response_body).first.should == 'hello'
      end

      it 'render inline' do
        function = Chanko::Function.new(:hello, RenderTest) do
          render :inline => "<%= 'hello' -%>"
        end
        function.invoke!(controller).should == 'hello'
        Array.wrap(controller.response_body).first.should == 'hello'
      end
    end

    context 'view' do
      let(:function) do
        Chanko::Function.new(:render, RenderTest) { render :text => 'hello' }
      end

      before do
        mock_unit("RenderTest")
        @_default_view_type = Chanko.config.default_view_type
      end

      after do
        Chanko.config.default_view_type = @_default_view_type
      end

      it 'should render as plain' do
        expect = 'hello'
        function.invoke!(view, :type => :plain).should == expect
        view.output_buffer.should == ''
      end

      it 'should render as inline' do
        expect = '<span class="unit unit__render_test unit__render_test__render">hello</span>'
        function.invoke!(view, :type => :inline).should == expect
        view.output_buffer.should == ''
      end

      it 'should render as block' do
        expect = '<div class="unit unit__render_test unit__render_test__render">hello</div>'
        function.invoke!(view, :type => :block).should == expect
        view.output_buffer.should == ''
      end

      it 'should render as default' do
        Chanko.config.default_view_type = :block
        expect = '<div class="unit unit__render_test unit__render_test__render">hello</div>'
        function.invoke!(view).should == expect
        Chanko.config.default_view_type = :plain
        expect = 'hello'
        function.invoke!(view).should == expect
      end

      it 'should return as string if block is not given' do
        expect = '<div class="unit unit__render_test unit__render_test__render">hello</div>'
        function.invoke!(view).should == expect
        view.output_buffer.should == ''
      end

      it 'should return as string if block is given' do
        expect = '<div class="unit unit__render_test unit__render_test__render">hello</div>'
        function.invoke!(view) {}.should == expect
        view.output_buffer.should == ''
      end

      context 'default' do
        let(:default_function) { Chanko::Function.default { '<div>hoge</div>' } }

        before do
          Chanko.config.default_view_type = :block
        end

        subject { Chanko::Function.default { '<div>hoge</div>' } }

        it 'default_function unit is default unit' do
          default_function.unit.should == Chanko::Unit::Default
        end

        it 'should escape' do
          default_function.invoke!(view, :capture => true).should ==  ERB::Util.html_escape('<div>hoge</div>')
        end
      end

      context 'compatible' do
        before do
          Chanko.config.compatible_css_class = true
        end

        after do
          Chanko.config.compatible_css_class = false
        end

        it 'render compatible class name' do
          expect = '<div class="extension ext_render_test ext_render_test-render">hello</div>'
          function.invoke!(view, :type => :block).should == expect
          view.output_buffer.should == ''
        end
      end
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_behaves_like 'function'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_behaves_like 'function'
  end
end


