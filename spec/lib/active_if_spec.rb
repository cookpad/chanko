# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Chanko" do
  shared_examples_for 'active if' do
    before do
      no_raise_chanko_exception
      Chanko::ActiveIf.define(:return_true) { true }
      Chanko::ActiveIf.define(:return_false) { false }
    end

    it 'should true' do
      active_if = Chanko::ActiveIf.new(:return_true)
      active_if.should be_active(nil)
    end

    it 'should false' do
      active_if = Chanko::ActiveIf.new(:return_false)
      active_if.enabled?(self).should == false
    end

    it 'should fetch definition object' do
      Chanko::ActiveIf.fetch(:return_true).call.should be_true
      Chanko::ActiveIf.fetch(:return_false).call.should be_false
    end

    it 'should return always_false when a non-definition is fetched' do
       Chanko::ActiveIf.fetch(:missing).call.should == false
    end

    context 'with option :raise' do
      it 'raises error when tried to fetch missing stuff' do
        expect { Chanko::ActiveIf.fetch(:missing, true) }.to raise_error(Chanko::Exception::MissingActiveIfDefinition)
        expect { Chanko::ActiveIf.fetch(:return_true, true) }.not_to raise_error(Chanko::Exception::MissingActiveIfDefinition)
      end

      it 'raises error when missing stuff included' do
        expect { Chanko::ActiveIf.new(:missing, :raise => true) }.to raise_error(Chanko::Exception::MissingActiveIfDefinition)
        expect { Chanko::ActiveIf.new(:return_true, :raise => true) }.not_to raise_error(Chanko::Exception::MissingActiveIfDefinition)
      end
    end

    it 'should false if one of definitions is false' do
      Chanko::ActiveIf.new(:return_true, :return_false).enabled?(self).should == false
      Chanko::ActiveIf.new(:return_false, :return_true).enabled?(self).should == false
    end


    it 'should true if one of definitions is false' do
      Chanko::ActiveIf.new(Chanko::ActiveIf::Any.new(:return_true, :return_false)).enabled?(self).should == true
      Chanko::ActiveIf.new(Chanko::ActiveIf::Any.new(:return_false, :return_true)).enabled?(self).should == true
      Chanko::ActiveIf.new(Chanko::ActiveIf::Any.new(:return_false, :return_false)).enabled?(self).should == false
      Chanko::ActiveIf.new(Chanko::ActiveIf::Any.new(:return_false, :return_true), :return_false).enabled?(self).should == false
      Chanko::ActiveIf.new(:return_true, Chanko::ActiveIf::Any.new(:return_false, :return_true)).enabled?(self).should == true
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'active if'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'active if'
  end
end
