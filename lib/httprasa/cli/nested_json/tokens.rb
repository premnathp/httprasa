# frozen_string_literal: true

module NestedJSON
  EMPTY_STRING = ''
  HIGHLIGHTER = '^'
  OPEN_BRACKET = '['
  CLOSE_BRACKET = ']'
  BACKSLASH = '\\'

  class TokenKind
    TEXT = :text
    NUMBER = :number
    LEFT_BRACKET = :left_bracket
    RIGHT_BRACKET = :right_bracket
    PSEUDO = :pseudo  # Not a real token, use when representing location only

    def self.to_name(kind)
      OPERATORS.key(kind)&.inspect || "a #{kind}"
    end
  end

  OPERATORS = {
    OPEN_BRACKET => TokenKind::LEFT_BRACKET,
    CLOSE_BRACKET => TokenKind::RIGHT_BRACKET
  }.freeze

  SPECIAL_CHARS = (OPERATORS.keys + [BACKSLASH]).freeze
  LITERAL_TOKENS = [TokenKind::TEXT, TokenKind::NUMBER].freeze

  Token = Struct.new(:kind, :value, :start, :end)

  class PathAction
    KEY = :key
    INDEX = :index
    APPEND = :append
    SET = :set  # Pseudo action, used by the interpreter

    def self.to_string(action)
      action.to_s
    end
  end

  class Path
    attr_reader :kind, :accessor, :tokens, :is_root

    def initialize(kind, accessor: nil, tokens: [], is_root: false)
      @kind = kind
      @accessor = accessor
      @tokens = tokens
      @is_root = is_root
    end

    def reconstruct
      case kind
      when PathAction::KEY
        is_root ? accessor.to_s : "#{OPEN_BRACKET}#{accessor}#{CLOSE_BRACKET}"
      when PathAction::INDEX
        "#{OPEN_BRACKET}#{accessor}#{CLOSE_BRACKET}"
      when PathAction::APPEND
        "#{OPEN_BRACKET}#{CLOSE_BRACKET}"
      end
    end
  end

  class NestedJSONArray < Array
    # Denotes a top-level JSON array.
  end
end