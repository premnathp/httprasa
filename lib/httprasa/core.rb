# lib/httprasa/core.rb

require 'optparse'
require 'socket'
require 'httparty'
require_relative 'environment'
require_relative 'exit_status'
#require_relative 'output/writer'
#require_relative 'internal/update_warnings'
#require_relative 'internal/daemon_runner'

module Httprasa
  module Core
    def self.raw_main(parser, main_program, args = ARGV, env = Environment.new, use_default_options = true)
      program_name, *args = args
      env.program_name = File.basename(program_name)
      args = decode_raw_args(args, env.stdin_encoding)

      if daemon_mode?(args)
        return run_daemon_task(env, args)
      end

      # TODO: Implement plugin manager
      # plugin_manager.load_installed_plugins(env.config.plugins_dir)

      if use_default_options && env.config.default_options
        args = env.config.default_options + args
      end

      include_debug_info = args.include?('--debug')
      include_traceback = include_debug_info || args.include?('--traceback')

      exit_status = ExitStatus::SUCCESS

      begin
        parsed_args = parser.parse(args)
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
        env.stderr.puts(e.message)
        exit_status = ExitStatus::ERROR
      rescue Interrupt
        env.stderr.puts
        exit_status = ExitStatus::ERROR_CTRL_C
      rescue SystemExit => e
        exit_status = e.status != 0 ? ExitStatus::ERROR : ExitStatus::SUCCESS
      else
        check_updates(env)
        begin
          exit_status = main_program.call(parsed_args, env)
        rescue Interrupt
          env.stderr.puts
          exit_status = ExitStatus::ERROR_CTRL_C
        rescue SystemExit => e
          exit_status = e.status != 0 ? ExitStatus::ERROR : ExitStatus::SUCCESS
        rescue HTTParty::ResponseError => e
          exit_status = ExitStatus::ERROR
          env.log_error("HTTP Error: #{e.message}")
        rescue SocketError => e
          exit_status = ExitStatus::ERROR
          env.log_error("Connection Error: #{e.message}")
        rescue => e
          exit_status = ExitStatus::ERROR
          env.log_error("#{e.class}: #{e.message}")
          env.log_error(e.backtrace.join("\n")) if include_traceback
        end
      end

      exit_status
    end

    def self.main(args = ARGV, env = Environment.new)
      # TODO: Implement CLI parser
      parser = OptionParser.new
      raw_main(parser, method(:program), args, env)
    end

    def self.program(args, env)
      # TODO: Implement main program logic
      ExitStatus::SUCCESS
    end

    def self.print_debug_info(env)
      env.stderr.puts [
        "Httprasa #{Httprasa::VERSION}",
        "HTTParty #{HTTParty::VERSION}",
        "Ruby #{RUBY_VERSION} #{RUBY_PLATFORM}",
        "#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION}",
        "#{RUBY_DESCRIPTION}",
      ]
      env.stderr.puts
      env.stderr.puts env.inspect
      env.stderr.puts
      # TODO: Implement plugin manager
      # env.stderr.puts plugin_manager.inspect
      env.stderr.puts
    end

    def self.decode_raw_args(args, stdin_encoding)
      args.map do |arg|
        arg.force_encoding(stdin_encoding)
        unless arg.valid_encoding?
          arg.force_encoding('ASCII-8BIT').encode('UTF-8', invalid: :replace, undef: :replace)
        end
        arg
      end
    end

    def self.check_updates(env)
        current_version = Gem::Version.new(Httprasa::VERSION)
        
        begin
          uri = URI(RELEASES_URL)
          response = Net::HTTP.get(uri)
          latest_release = JSON.parse(response)
          latest_version = Gem::Version.new(latest_release['tag_name'].gsub(/^v/, ''))
  
          if latest_version > current_version
            puts "A new version of Httprasa is available: #{latest_version}"
            puts "You can update by running: gem update httprasa"
            ExitStatus::SUCCESS
          else
            puts "You're running the latest version of Httprasa (#{current_version})"
            ExitStatus::SUCCESS
          end
        rescue StandardError => e
          warn "Failed to check for updates: #{e.message}"
          ExitStatus::ERROR
        end
    end
  end
end