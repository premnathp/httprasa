# lib/httprasa/ui/palette.rb

module Httprasa
    module UI
      PYGMENTS_BRIGHT_BLACK = 'ansibrightblack'
      AUTO_STYLE = 'auto'  # Follows terminal ANSI color styles
  
      module Styles
        PIE = :pie
        ANSI = :ansi
      end
  
      class PieStyle < String
        UNIVERSAL = new('pie')
        DARK = new('pie-dark')
        LIGHT = new('pie-light')
      end
  
      PIE_STYLE_TO_SHADE = {
        PieStyle::DARK => '500',
        PieStyle::UNIVERSAL => '600',
        PieStyle::LIGHT => '700'
      }
      SHADE_TO_PIE_STYLE = PIE_STYLE_TO_SHADE.invert
  
      class ColorString < String
        def |(other)
          if other.is_a?(String)
            ColorString.new(self + ' ' + other)
          elsif other.is_a?(GenericColor)
            StyledGenericColor.new(other, styles: self.split)
          elsif other.is_a?(StyledGenericColor)
            other.styles.concat(self.split)
            other
          else
            raise NotImplementedError
          end
        end
      end
  
      class PieColor < ColorString
        PRIMARY = new('primary')
        SECONDARY = new('secondary')
        WHITE = new('white')
        BLACK = new('black')
        GREY = new('grey')
        AQUA = new('aqua')
        PURPLE = new('purple')
        ORANGE = new('orange')
        RED = new('red')
        BLUE = new('blue')
        PINK = new('pink')
        GREEN = new('green')
        YELLOW = new('yellow')
      end
  
      class GenericColor
        COLORS = {
          WHITE: { Styles::PIE => PieColor::WHITE, Styles::ANSI => 'white' },
          BLACK: { Styles::PIE => PieColor::BLACK, Styles::ANSI => 'black' },
          GREEN: { Styles::PIE => PieColor::GREEN, Styles::ANSI => 'green' },
          ORANGE: { Styles::PIE => PieColor::ORANGE, Styles::ANSI => 'yellow' },
          YELLOW: { Styles::PIE => PieColor::YELLOW, Styles::ANSI => 'bright_yellow' },
          BLUE: { Styles::PIE => PieColor::BLUE, Styles::ANSI => 'blue' },
          PINK: { Styles::PIE => PieColor::PINK, Styles::ANSI => 'bright_magenta' },
          PURPLE: { Styles::PIE => PieColor::PURPLE, Styles::ANSI => 'magenta' },
          RED: { Styles::PIE => PieColor::RED, Styles::ANSI => 'red' },
          AQUA: { Styles::PIE => PieColor::AQUA, Styles::ANSI => 'cyan' },
          GREY: { Styles::PIE => PieColor::GREY, Styles::ANSI => 'bright_black' }
        }
  
        COLORS.each do |color, value|
          define_singleton_method(color.downcase) { new(color) }
        end
  
        attr_reader :color
  
        def initialize(color)
          @color = color
        end
  
        def apply_style(style, style_name: nil)
          exposed_color = COLORS[@color][style]
          if style == Styles::PIE
            raise ArgumentError, "style_name is required for PIE style" if style_name.nil?
            shade = PIE_STYLE_TO_SHADE[PieStyle.new(style_name)]
            UI.get_color(exposed_color, shade)
          else
            exposed_color
          end
        end
      end
  
      class StyledGenericColor
        attr_reader :color, :styles
  
        def initialize(color, styles: [])
          @color = color
          @styles = styles
        end
      end
  
      COLOR_PALETTE = {
        PieColor::WHITE => '#ffffff',
        PieColor::BLACK => '#000000',
        PieColor::GREY => {
          '700' => '#444444',
          '600' => '#666666',
          '500' => '#888888'
        },
        PieColor::AQUA => {
          '700' => '#008080',
          '600' => '#00a0a0',
          '500' => '#00c0c0'
        },
        PieColor::PURPLE => {
          '700' => '#800080',
          '600' => '#a000a0',
          '500' => '#c000c0'
        },
        PieColor::ORANGE => {
          '700' => '#ff8000',
          '600' => '#ffa000',
          '500' => '#ffc000'
        },
        PieColor::RED => {
          '700' => '#800000',
          '600' => '#a00000',
          '500' => '#c00000'
        },
        PieColor::BLUE => {
          '700' => '#000080',
          '600' => '#0000a0',
          '500' => '#0000c0'
        },
        PieColor::PINK => {
          '700' => '#ff69b4',
          '600' => '#ff89d4',
          '500' => '#ffa9f4'
        },
        PieColor::GREEN => {
          '700' => '#008000',
          '600' => '#00a000',
          '500' => '#00c000'
        },
        PieColor::YELLOW => {
          '700' => '#808000',
          '600' => '#a0a000',
          '500' => '#c0c000'
        }
      }
  
      COLOR_PALETTE.merge!(
        PieColor::PRIMARY => {
          '700' => COLOR_PALETTE[PieColor::BLACK],
          '600' => PYGMENTS_BRIGHT_BLACK,
          '500' => COLOR_PALETTE[PieColor::WHITE]
        },
        PieColor::SECONDARY => {
          '700' => '#37523C',
          '600' => '#6c6969',
          '500' => '#6c6969'
        }
      )
  
      def self.boldify(color)
        "bold #{color}"
      end
  
      def self.get_color(color, shade, palette: COLOR_PALETTE)
        color = color.to_s
        return nil unless palette.key?(color)
        color_code = palette[color]
        color_code.is_a?(Hash) && color_code.key?(shade) ? color_code[shade] : color_code
      end
  
      STYLE = {
        PieColor::WHITE => boldify(get_color(PieColor::WHITE, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL])),
        PieColor::BLACK => boldify(get_color(PieColor::BLACK, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL])),
        PieColor::GREY => get_color(PieColor::GREY, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::AQUA => get_color(PieColor::AQUA, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::PURPLE => get_color(PieColor::PURPLE, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::ORANGE => get_color(PieColor::ORANGE, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::RED => get_color(PieColor::RED, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::BLUE => get_color(PieColor::BLUE, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::PINK => get_color(PieColor::PINK, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::GREEN => get_color(PieColor::GREEN, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::YELLOW => get_color(PieColor::YELLOW, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::PRIMARY => get_color(PieColor::PRIMARY, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL]),
        PieColor::SECONDARY => get_color(PieColor::SECONDARY, PIE_STYLE_TO_SHADE[PieStyle::UNIVERSAL])
      }.freeze
    end
end