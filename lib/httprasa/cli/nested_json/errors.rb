# frozen_string_literal: true

require_relative 'tokens'

module NestedJSON
  class NestedJSONSyntaxError < StandardError
    attr_reader :source, :token, :message, :message_kind

    def initialize(source, token, message, message_kind: 'Syntax')
      @source = source
      @token = token
      @message = message
      @message_kind = message_kind
      super(message)
    end

    def to_s
      lines = ["HTTPie #{@message_kind} Error: #{@message}"]
      if @token
        lines << @source
        lines << ' ' * @token.start + HIGHLIGHTER * (@token.end - @token.start)
      end
      lines.join("\n")
    end
  end
end