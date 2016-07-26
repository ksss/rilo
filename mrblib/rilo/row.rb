module Rilo
  Row = Struct.new(
    :chars,
    :hl
  ) do
    def initialize(*)
      super
      high_light_by_chars
    end

    def high_light_by_chars
      self.hl = []
      in_string = false
      chars.each_char do |ch|
        self.hl << if in_string
          if in_string == ch
            in_string = false
          end
          HighLight::STRING
        elsif ch == "'" || ch == '"'
          in_string = ch
          HighLight::STRING
        else
          HighLight::NONE
        end
      end
    end

    def color(index)
      case hl[index]
      when HighLight::STRING then 35
      else 37
      end
    end
  end
end
