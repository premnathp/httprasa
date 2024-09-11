# frozen_string_literal: true

require_relative 'errors'
require_relative 'tokens'

module NestedJSON
  module Parse
    module_function

    def parse(source)
      Enumerator.new do |yielder|
        tokens = tokenize(source).to_a
        cursor = 0

        def can_advance(cursor, tokens)
          cursor < tokens.length
        end

        def expect(cursor, tokens, *kinds)
          raise ArgumentError, 'No kinds specified' if kinds.empty?

          if can_advance(cursor, tokens)
            token = tokens[cursor]
            cursor += 1
            return [token, cursor] if kinds.include?(token.kind)
          end

          token = if tokens.any?
                    last_token = tokens.last
                    Token.new(last_token.kind, last_token.value, last_token.end, last_token.end + 1)
                  end

          suffix = kinds.length == 1 ? TokenKind.to_name(kinds.first) : kinds[0...-1].map { |k| TokenKind.to_name(k) }.join(', ') + " or #{TokenKind.to_name(kinds.last)}"
          message = "Expecting #{suffix}"
          raise NestedJSONSyntaxError.new(source, token, message)
        end

        def parse_root(cursor, tokens)
          return Path.new(PathAction::KEY, accessor: EMPTY_STRING, is_root: true) unless can_advance(cursor, tokens)

          path_tokens = []
          token, cursor = expect(cursor, tokens, *LITERAL_TOKENS, TokenKind::LEFT_BRACKET)
          path_tokens << token

          case token.kind
          when *LITERAL_TOKENS
            action = PathAction::KEY
            value = token.value.to_s
          when TokenKind::LEFT_BRACKET
            token, cursor = expect(cursor, tokens, TokenKind::NUMBER, TokenKind::RIGHT_BRACKET)
            path_tokens << token
            case token.kind
            when TokenKind::NUMBER
              action = PathAction::INDEX
              value = token.value
              token, cursor = expect(cursor, tokens, TokenKind::RIGHT_BRACKET)
              path_tokens << token
            when TokenKind::RIGHT_BRACKET
              action = PathAction::APPEND
              value = nil
            else
              assert_cant_happen
            end
          else
            assert_cant_happen
          end

          [Path.new(action, accessor: value, tokens: path_tokens, is_root: true), cursor]
        end

        root_path, cursor = parse_root(cursor, tokens)
        yielder << root_path

        while can_advance(cursor, tokens)
          path_tokens = []
          token, cursor = expect(cursor, tokens, TokenKind::LEFT_BRACKET)
          path_tokens << token

          token, cursor = expect(cursor, tokens, TokenKind::TEXT, TokenKind::NUMBER, TokenKind::RIGHT_BRACKET)
          path_tokens << token

          path = case token.kind
                 when TokenKind::RIGHT_BRACKET
                   Path.new(PathAction::APPEND, tokens: path_tokens)
                 when TokenKind::TEXT
                   path = Path.new(PathAction::KEY, accessor: token.value, tokens: path_tokens)
                   token, cursor = expect(cursor, tokens, TokenKind::RIGHT_BRACKET)
                   path_tokens << token
                   path
                 when TokenKind::NUMBER
                   path = Path.new(PathAction::INDEX, accessor: token.value, tokens: path_tokens)
                   token, cursor = expect(cursor, tokens, TokenKind::RIGHT_BRACKET)
                   path_tokens << token
                   path
                 else
                   assert_cant_happen
                 end

          yielder << path
        end
      end
    end

    def tokenize(source)
      Enumerator.new do |yielder|
        cursor = 0
        backslashes = 0
        buffer = []

        def send_buffer(buffer, backslashes, cursor, yielder)
          return if buffer.empty?

          value = buffer.join
          kind = TokenKind::TEXT

          unless backslashes > 0
            [
              ->(v) { Integer(v) },
              ->(v) { check_escaped_int(v) }
            ].each do |variation|
              begin
                value = variation.call(value)
                kind = TokenKind::NUMBER
                break
              rescue ArgumentError
                next
              end
            end
          end

          yielder << Token.new(kind, value, cursor - (buffer.length + backslashes), cursor)
          buffer.clear
          backslashes = 0
        end

        while cursor < source.length
          char = source[cursor]
          if OPERATORS.key?(char)
            send_buffer(buffer, backslashes, cursor, yielder)
            yielder << Token.new(OPERATORS[char], char, cursor, cursor + 1)
          elsif char == BACKSLASH && cursor < source.length - 1
            if SPECIAL_CHARS.include?(source[cursor + 1])
              backslashes += 1
            else
              buffer << char
            end
            buffer << source[cursor + 1]
            cursor += 1
          else
            buffer << char
          end
          cursor += 1
        end

        send_buffer(buffer, backslashes, cursor, yielder)
      end
    end

    def check_escaped_int(value)
      raise ArgumentError, 'Not an escaped int' unless value.start_with?(BACKSLASH)

      begin
        Integer(value[1..-1])
      rescue ArgumentError
        raise ArgumentError, 'Not an escaped int'
      end
      value[1..-1]
    end

    def assert_cant_happen
      raise StandardError, 'Unexpected value'
    end
  end
end