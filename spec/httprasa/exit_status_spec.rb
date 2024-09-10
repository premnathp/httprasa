# spec/httprasa/exit_status_spec.rb

require 'spec_helper'
require 'httprasa/exit_status'

RSpec.describe Httprasa::ExitStatus do
  describe 'constants' do
    it 'defines SUCCESS as 0' do
      expect(Httprasa::ExitStatus::SUCCESS).to eq(0)
    end

    it 'defines ERROR as 1' do
      expect(Httprasa::ExitStatus::ERROR).to eq(1)
    end

    it 'defines ERROR_CTRL_C as 130' do
      expect(Httprasa::ExitStatus::ERROR_CTRL_C).to eq(130)
    end
  end

  describe '.value_to_name' do
    it 'returns the name of a known exit status' do
      expect(Httprasa::ExitStatus.value_to_name(0)).to eq(:SUCCESS)
    end

    it 'returns nil for an unknown exit status' do
      expect(Httprasa::ExitStatus.value_to_name(999)).to be_nil
    end
  end
end