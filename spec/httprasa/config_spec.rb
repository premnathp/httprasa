require 'spec_helper'
require 'httprasa/config'
require 'tmpdir'

RSpec.describe Httprasa::Config do
  let(:httpbin) { 'https://httpbin.org' }  # We'll need to mock this or use VCR

  describe '.get_default_config_dir' do
    let(:home_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(home_dir)
    end

    it 'uses HTTPRASA_CONFIG_DIR if set' do
      custom_dir = File.join(home_dir, 'custom_config')
      ClimateControl.modify HTTPRASA_CONFIG_DIR: custom_dir do
        expect(Httprasa.get_default_config_dir.to_s).to eq(custom_dir)
      end
    end

    unless Gem.win_platform?
      it 'uses XDG_CONFIG_HOME if set' do
        xdg_config_home = File.join(home_dir, 'xdg_config_home')
        ClimateControl.modify(
          HOME: home_dir,
          XDG_CONFIG_HOME: xdg_config_home,
          HTTPRASA_CONFIG_DIR: nil
        ) do
          expected_dir = File.join(xdg_config_home, Httprasa::DEFAULT_CONFIG_DIRNAME)
          expect(Httprasa.get_default_config_dir.to_s).to eq(expected_dir)
        end
      end

      it 'uses default XDG path if XDG_CONFIG_HOME not set' do
        ClimateControl.modify(HOME: home_dir, XDG_CONFIG_HOME: nil, HTTPRASA_CONFIG_DIR: nil) do
          expected_dir = File.join(home_dir, '.config', Httprasa::DEFAULT_CONFIG_DIRNAME)
          expect(Httprasa.get_default_config_dir.to_s).to eq(expected_dir)
        end
      end

      it 'uses legacy config dir if it exists' do
        legacy_dir = File.join(home_dir, '.httprasa')
        FileUtils.mkdir_p(legacy_dir)
        ClimateControl.modify(HOME: home_dir, XDG_CONFIG_HOME: nil, HTTPRASA_CONFIG_DIR: nil) do
          expect(Httprasa.get_default_config_dir.to_s).to eq(legacy_dir)
        end
      end
    end

    if Gem.win_platform?
      it 'uses the default Windows config dir' do
        ClimateControl.modify(HTTPRASA_CONFIG_DIR: nil) do
          expect(Httprasa.get_default_config_dir).to eq(Httprasa::DEFAULT_WINDOWS_CONFIG_DIR)
        end
      end
    end
  end

  describe '#default_options' do
    let(:config) { Httprasa::Config.new(Dir.mktmpdir) }

    it 'uses default options' do
      config['default_options'] = ['--form']
      config.save
      # We need to implement the actual HTTP request here or mock it
      # expect(response.json['form']).to eq({'foo' => 'bar'})
    end

    it 'allows overwriting default options' do
      config['default_options'] = ['--form']
      config.save
      # We need to implement the actual HTTP request here or mock it
      # expect(response.json['json']).to eq({'foo' => 'bar'})
    end
  end

  describe 'config file handling' do
    let(:config_dir) { Dir.mktmpdir }
    let(:config_file) { File.join(config_dir, Httprasa::Config::FILENAME) }
    let(:config) { Httprasa::Config.new(config_dir) }

    after do
      FileUtils.remove_entry(config_dir)
    end

    it 'warns about invalid config file' do
      File.write(config_file, '{invalid json}')
      # We need to capture stderr and check for warning messages
      # expect(stderr).to include('warning')
      # expect(stderr).to include('invalid config file')
    end

    unless Gem.win_platform?
      it 'warns about inaccessible config file' do
        FileUtils.touch(config_file)
        File.chmod(0000, config_file)
        # We need to capture stderr and check for warning messages
        # expect(stderr).to include('warning')
        # expect(stderr).to include('cannot read config file')
      end
    end
  end
end