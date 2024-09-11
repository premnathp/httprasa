# spec/httprasa/core_spec.rb

require 'spec_helper'
require 'httprasa/core'
require 'httprasa/environment'
require 'httprasa/exit_status'

RSpec.describe Httprasa::Core do
  let(:env) { Httprasa::Environment.new }
   let(:parser) { Httprasa::CLI::Definition.parser }

  describe '.raw_main' do
    it 'returns a successful exit status for valid input' do
    main_program = ->(args, env) { Httprasa::ExitStatus::SUCCESS }
    # parser = Httprasa::CLI::Definition.parser
      args = ['httprasa', 'example.com']

      result = described_class.raw_main(parser, main_program, args, env)
      expect(result).to eq(Httprasa::ExitStatus::SUCCESS)
    end

    it 'handles interrupts' do
      parser = OptionParser.new
      main_program = ->(args, env) { raise Interrupt }
      args = ['httprasa', 'example.com']

      result = described_class.raw_main(parser, main_program, args, env)
      expect(result).to eq(Httprasa::ExitStatus::ERROR_CTRL_C)
    end

    it 'handles HTTP errors' do
      parser = OptionParser.new
      main_program = ->(args, env) { raise HTTParty::ResponseError.new('404 Not Found') }
      args = ['httprasa', 'example.com']

      result = described_class.raw_main(parser, main_program, args, env)
      expect(result).to eq(Httprasa::ExitStatus::ERROR)
    end
  end

  describe '.decode_raw_args' do
    it 'decodes byte strings to UTF-8' do
      args = ['test', "test".encode('ASCII-8BIT')]
      result = described_class.decode_raw_args(args, 'utf-8')
      expect(result).to all(be_a(String))
      expect(result).to all(have_attributes(encoding: Encoding::UTF_8))
    end
  end
end