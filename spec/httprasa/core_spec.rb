# spec/httprasa/core_spec.rb

require 'spec_helper'
require 'httprasa/core'

RSpec.describe Httprasa::Core do
  describe '.main' do
    it 'returns a successful exit status' do
      expect(Httprasa::Core.main).to eq(Httprasa::ExitStatus::SUCCESS)
    end

    it 'outputs the version and a greeting' do
      expect { Httprasa::Core.main }.to output(
        "Httprasa version #{Httprasa::VERSION}\nHello from Httprasa!\n"
      ).to_stdout
    end
  end
end