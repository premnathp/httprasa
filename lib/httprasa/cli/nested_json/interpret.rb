# frozen_string_literal: true

require_relative 'parse'
require_relative 'errors'
require_relative 'tokens'

module NestedJSON
  module Interpret
    module_function

    JSON_TYPE_MAPPING = {
      Hash => 'object',
      Array => 'array',
      Integer => 'number',
      Float => 'number',
      String => 'string'
    }.freeze

    def interpret_nested_json(pairs)
      context = nil
      pairs.each do |key, value|
        context = interpret(context, key, value)
      end
      wrap_with_dict(context)
    end

    def interpret(context, key, value)
      cursor = context
      paths = Parse.parse(key).to_a
      paths << Path.new(PathAction::SET, accessor: value)

      def type_check(index, path, expected_type)
        return if cursor.is_a?(expected_type)

        pseudo_token = if path.tokens.any?
                         Token.new(
                           TokenKind::PSEUDO,
                           '',
                           path.tokens.first.start,
                           path.tokens.last.end
                         )
                       end

        cursor_type = JSON_TYPE_MAPPING.fetch(cursor.class, cursor.class.name)
        required_type = JSON_TYPE_MAPPING[expected_type]
        message = "Cannot perform '#{PathAction.to_string(path.kind)}' based access on "
        message += "'#{paths[0...index].map(&:reconstruct).join}'"
        message += " which has a type of '#{cursor_type}' but this operation"
        message += " requires a type of '#{required_type}'."

        raise NestedJSONSyntaxError.new(key, pseudo_token, message, message_kind: 'Type')
      end

      def object_for(kind)
        case kind
        when PathAction::KEY then {}
        when PathAction::INDEX, PathAction::APPEND then []
        else
          Parse.assert_cant_happen
        end
      end

      paths.each_cons(2) do |path, next_path|
        if cursor.nil?
          context = cursor = object_for(path.kind)
        end

        case path.kind
        when PathAction::KEY
          type_check(paths.index(path), path, Hash)
          if next_path.kind == PathAction::SET
            cursor[path.accessor] = next_path.accessor
            break
          end
          cursor[path.accessor] ||= object_for(next_path.kind)
          cursor = cursor[path.accessor]
        when PathAction::INDEX
          type_check(paths.index(path), path, Array)
          if path.accessor.negative?
            raise NestedJSONSyntaxError.new(
              key,
              path.tokens[1],
              'Negative indexes are not supported.',
              message_kind: 'Value'
            )
          end
          cursor.fill(nil, cursor.size...path.accessor + 1)
          if next_path.kind == PathAction::SET
            cursor[path.accessor] = next_path.accessor
            break
          end
          cursor[path.accessor] ||= object_for(next_path.kind)
          cursor = cursor[path.accessor]
        when PathAction::APPEND
          type_check(paths.index(path), path, Array)
          if next_path.kind == PathAction::SET
            cursor << next_path.accessor
            break
          end
          cursor << object_for(next_path.kind)
          cursor = cursor.last
        else
          Parse.assert_cant_happen
        end
      end

      context
    end

    def wrap_with_dict(context)
      case context
      when nil then {}
      when Array then { EMPTY_STRING => NestedJSONArray.new(context) }
      when Hash then context
      else
        raise ArgumentError, "Unexpected context type: #{context.class}"
      end
    end

    def unwrap_top_level_list_if_needed(data)
      if data.size == 1
        key, value = data.first
        if value.is_a?(NestedJSONArray) && key == EMPTY_STRING
          return value
        end
      end
      data
    end
  end
end