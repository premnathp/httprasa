require 'base64'
require 'json'
require 'mime/types'
require 'tempfile'
require 'uri'

module Httprasa
  module Utils
    COOKIE_SPLIT_REGEX = /,\s(?=[^;]+=[^;]+)/

    class JsonDictPreservingDuplicateKeys < Hash
      def initialize(items)
        @items = items
        ensure_items_used
      end

      def items
        @items
      end

      private

      def ensure_items_used
        self['__hack__'] = '__hack__' if @items.any?
      end
    end

    def self.load_json_preserve_order_and_dupe_keys(s)
      JSON.parse(s, object_class: JsonDictPreservingDuplicateKeys)
    end

    def self.repr_dict(d)
      require 'pp'
      PP.pp(d, '')
    end

    def self.humanize_bytes(n, precision = 2)
      abbrevs = [
        [1 << 50, 'PB'],
        [1 << 40, 'TB'],
        [1 << 30, 'GB'],
        [1 << 20, 'MB'],
        [1 << 10, 'kB'],
        [1, 'B']
      ]

      return '1 B' if n == 1

      factor, suffix = abbrevs.find { |f, _| n >= f }
      "#{(n.to_f / factor).round(precision)} #{suffix}"
    end

    def self.get_content_type(filename)
      MIME::Types.type_for(filename).first&.content_type
    end

    def self.split_cookies(cookies)
      return [] if cookies.nil? || cookies.empty?
      cookies.split(COOKIE_SPLIT_REGEX)
    end

    def self.get_expired_cookies(cookies, now = nil)
      now ||= Time.now.to_f

      is_expired = ->(expires) { !expires.nil? && expires <= now }

      parse_ns_headers(split_cookies(cookies)).map do |attrs|
        cookie = Hash[attrs[1..-1]]
        cookie['name'] = attrs[0][0]
        cookie
      end.tap do |parsed_cookies|
        max_age_to_expires(cookies: parsed_cookies, now: now)
      end.select do |cookie|
        is_expired.call(cookie['expires'])
      end.map do |cookie|
        { 'name' => cookie['name'], 'path' => cookie['path'] || '/' }
      end
    end

    def self.parse_content_type_header(header)
      tokens = header.split(';')
      content_type = tokens[0].strip
      params = tokens[1..-1]
      params_dict = {}
      items_to_strip = "\"' "

      params.each do |param|
        param = param.strip
        next if param.empty?

        key, value = param, true
        index_of_equals = param.index('=')
        if index_of_equals
          key = param[0...index_of_equals].strip.tr(items_to_strip, '')
          value = param[(index_of_equals + 1)..-1].strip.tr(items_to_strip, '')
        end
        params_dict[key.downcase] = value
      end

      [content_type, params_dict]
    end

    def self.split_iterable(iterable, &key)
      iterable.partition(&key)
    end

    def self.unwrap_context(exc)
      return exc unless exc.respond_to?(:cause) && exc.cause.is_a?(Exception)
      unwrap_context(exc.cause)
    end

    def self.url_as_host(url)
      URI(url).host.split('@').last
    end

    class LockFileError < StandardError; end

    def self.open_with_lockfile(file, *args)
      file_id = Base64.strict_encode64(File.expand_path(file))
      target_file = File.join(Dir.tmpdir, file_id)

      begin
        File.open(target_file, File::WRONLY | File::CREAT | File::EXCL)
      rescue Errno::EEXIST
        raise LockFileError, "Can't modify a locked file."
      end

      begin
        File.open(file, *args) do |stream|
          yield stream
        end
      ensure
        File.unlink(target_file)
      end
    end

    def self.is_version_greater(version_1, version_2)
      Gem::Version.new(version_1) > Gem::Version.new(version_2)
    end

    private

    def self.parse_ns_headers(headers)
      # This is a simplified version. You might need to implement a more robust parser
      headers.map do |header|
        header.split(';').map { |part| part.strip.split('=', 2) }
      end
    end

    def self.max_age_to_expires(cookies:, now:)
      cookies.each do |cookie|
        next if cookie.key?('expires')
        max_age = cookie['max-age']
        if max_age && max_age =~ /^\d+$/
          cookie['expires'] = now + max_age.to_f
        end
      end
    end
  end
end