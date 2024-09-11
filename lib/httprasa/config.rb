# lib/httprasa/config.rb

require 'json'
require 'pathname'
require_relative 'utils/encoding'
require_relative 'version'

module Httprasa
  ENV_XDG_CONFIG_HOME = 'XDG_CONFIG_HOME'
  ENV_HTTPRASA_CONFIG_DIR = 'HTTPRASA_CONFIG_DIR'
  DEFAULT_CONFIG_DIRNAME = 'httprasa'
  DEFAULT_RELATIVE_XDG_CONFIG_HOME = Pathname.new('.config')
  DEFAULT_RELATIVE_LEGACY_CONFIG_DIR = Pathname.new('.httprasa')
  DEFAULT_WINDOWS_CONFIG_DIR = Pathname.new(ENV['APPDATA']) / DEFAULT_CONFIG_DIRNAME if Gem.win_platform?

  def self.get_default_config_dir
    # 1. explicitly set through env
    env_config_dir = ENV[ENV_HTTPRASA_CONFIG_DIR]
    return Pathname.new(env_config_dir) if env_config_dir

    # 2. Windows
    return DEFAULT_WINDOWS_CONFIG_DIR if Gem.win_platform?

    home_dir = Pathname.new(Dir.home)

    # 3. legacy ~/.httprasa
    legacy_config_dir = home_dir / DEFAULT_RELATIVE_LEGACY_CONFIG_DIR
    return legacy_config_dir if legacy_config_dir.exist?

    # 4. XDG
    xdg_config_home_dir = ENV[ENV_XDG_CONFIG_HOME] || (home_dir / DEFAULT_RELATIVE_XDG_CONFIG_HOME)
    
    Pathname.new(xdg_config_home_dir) / DEFAULT_CONFIG_DIRNAME
  end

  DEFAULT_CONFIG_DIR = get_default_config_dir

  class ConfigFileError < StandardError; end

  def self.read_raw_config(config_type, path)
    JSON.parse(File.read(path, encoding: Encoding::UTF_8))
  rescue JSON::ParserError => e
    raise ConfigFileError, "invalid #{config_type} file: #{e} [#{path}]"
  rescue Errno::ENOENT
    nil
  rescue SystemCallError => e
    raise ConfigFileError, "cannot read #{config_type} file: #{e}"
  end

  class BaseConfigDict < Hash
    attr_reader :path
    attr_accessor :name, :helpurl, :about

    def initialize(path)
      super()
      @path = Pathname.new(path)
    end

    def ensure_directory
      path.dirname.mkpath
      path.dirname.chmod(0700)
    end

    def new?
      !path.exist?
    end

    def pre_process_data(data)
      data
    end

    def post_process_data(data)
      data
    end

    def load
      config_type = self.class.name.split('::').last.downcase
      data = Httprasa.read_raw_config(config_type, path)
      if data
        data = pre_process_data(data)
        update(data)
      end
    end

    def save(bump_version: false)
      self['__meta__'] ||= {}
      if bump_version || !self['__meta__'].key?('httprasa')
        self['__meta__']['httprasa'] = Httprasa::VERSION
      end
      self['__meta__']['help'] = helpurl if helpurl
      self['__meta__']['about'] = about if about

      ensure_directory

      json_string = JSON.pretty_generate(post_process_data(self))
      File.write(path, json_string + "\n", encoding: Encoding::UTF_8)
    end

    def version
      self.dig('__meta__', 'httprasa') || Httprasa::VERSION
    end
  end

  class Config < BaseConfigDict
    FILENAME = 'config.json'
    DEFAULTS = {
      'default_options' => []
    }.freeze

    def initialize(directory = DEFAULT_CONFIG_DIR)
    #TODO; FIXME;
      @directory = Pathname.new("httprasa")
      super(@directory / FILENAME)
      update(DEFAULTS)
    end

    def default_options
      self['default_options']
    end

    def configured_path(config_option, default)
      Pathname.new(self.fetch(config_option, @directory / default)).expand_path
    end

    def plugins_dir
      configured_path('plugins_dir', 'plugins')
    end

    def version_info_file
      configured_path('version_info_file', 'version_info.json')
    end

    def developer_mode
      self['developer_mode']
    end
  end
end