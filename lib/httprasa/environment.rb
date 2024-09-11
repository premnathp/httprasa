# lib/httprasa/environment.rb

require 'ostruct'
require 'pathname'
require_relative 'config'
require_relative 'utils/encoding'
require_relative 'ui/palette'

module Httprasa
  class LogLevel < String
    INFO = new('info')
    WARNING = new('warning')
    ERROR = new('error')
  end

  LOG_LEVEL_COLORS = {
    LogLevel::INFO => Httprasa::UI::PieColor::PINK,
    LogLevel::WARNING => Httprasa::UI::PieColor::ORANGE,
    LogLevel::ERROR => Httprasa::UI::PieColor::RED
  }.freeze

  LOG_LEVEL_DISPLAY_THRESHOLDS = {
    LogLevel::INFO => 1,
    LogLevel::WARNING => 2,
    LogLevel::ERROR => Float::INFINITY
  }.freeze

  class Environment
    attr_accessor :args, :config_dir, :stdin, :stdin_isatty, :stdin_encoding,
                  :stdout, :stdout_isatty, :stdout_encoding, :stderr, :stderr_isatty,
                  :colors, :program_name, :show_displays, :quiet

    def initialize(devnull: nil, **kwargs)
      @args = OpenStruct.new
      @is_windows = RUBY_PLATFORM =~ /mswin|mingw|cygwin/
      @config_dir = Pathname.new(DEFAULT_CONFIG_DIR)
      @stdin = $stdin
      @stdin_isatty = @stdin.isatty
      @stdin_encoding = nil
      @stdout = $stdout
      @stdout_isatty = @stdout.isatty
      @stdout_encoding = nil
      @stderr = $stderr
      @stderr_isatty = @stderr.isatty
      @colors = 256
      @program_name = 'httprasa'
      @show_displays = true

      unless @is_windows
        # TODO: Implement curses equivalent for Ruby
      else
        # TODO: Implement colorama equivalent for Ruby
      end

      kwargs.each do |key, value|
        instance_variable_set("@#{key}", value) if respond_to?(key)
      end

      @_orig_stderr = @stderr
      @_devnull = devnull

      @stdin_encoding ||= @stdin&.external_encoding || Encoding::UTF_8
      @stdout_encoding ||= @stdout.external_encoding || Encoding::UTF_8

      @quiet = kwargs.fetch(:quiet, 0)
    end

    def to_s
      Utils.repr_dict(instance_variables.each_with_object({}) do |var, hash|
        key = var.to_s.delete('@')
        value = instance_variable_get(var)
        hash[key] = value unless key.start_with?('_')
      end)
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end

    def config
      @_config ||= begin
        config = Config.new(directory: @config_dir)
        unless config.new?
          begin
            config.load
          rescue ConfigFileError => e
            log_error(e.message, level: LogLevel::WARNING)
          end
        end
        config
      end
    end

    def devnull
      @_devnull ||= File.open(File::NULL, 'w+')
    end

    def as_silent
      original_stdout = @stdout
      original_stderr = @stderr
      @stdout = devnull
      @stderr = devnull
      yield
    ensure
      @stdout = original_stdout
      @stderr = original_stderr
    end

    def log_error(msg, level: LogLevel::ERROR)
      stderr = @stdout_isatty && @quiet >= LOG_LEVEL_DISPLAY_THRESHOLDS[level] ? @stderr : @_orig_stderr
      rich_console = make_rich_console(file: stderr, force_terminal: stderr.isatty)
      rich_console.puts(
        "\n#{@program_name}: #{level}: #{msg}\n\n",
        style: LOG_LEVEL_COLORS[level]
      )
    end

    def apply_warnings_filter
      Warning.ignore(:all) if @quiet >= LOG_LEVEL_DISPLAY_THRESHOLDS[LogLevel::WARNING]
    end

    private

    def make_rich_console(file:, force_terminal:)
      # TODO: Implement Rich console equivalent for Ruby
      # For now, we'll use a simple console output
      OpenStruct.new(
        puts: ->(msg, style: nil) { file.puts(msg) }
      )
    end
  end
end