#! /usr/bin/env ruby

require 'io/console'

exit 1 if ARGV.length < 1

module Key
  CTRL_C = 3
  CTRL_Q = 17
  ESC = 27
  LEFT_BLANKET = 91
  ARROW_UP = 1000
  ARROW_DOWN = 1001
  ARROW_LEFT = 1002
  ARROW_RIGHT = 1003
  A = 65
  B = 66
  C = 67
  D = 68
end

Editor = Struct.new(
  :row,
  :filename,
  :cx,
  :cy,
  :status_line,
) do
  def insert(ch)
    row[cy].chars.insert(cx, ch.chr)
    self.cx += 1
  end

  def p(obj)
    self.status_line << obj.inspect
  end

  def refresh
    buff = "\e[?25l\e[H"
    row.each_with_index do |r, index|
      buff << r.chars
    end
    buff << "#{cy}:#{cx} - #{status_line}\n"
    buff << "\e[#{cy+1};#{cx}H\e[?25h"
    $stdout.print buff
    self.status_line.clear
  end

  def process_keypress
    $stdin.raw do |io|
      ch = io.readbyte
      case ch
      when Key::ESC
        case io.readbyte
        when Key::LEFT_BLANKET
          case io.readbyte
          when Key::A
            self.cy -= 1
          when Key::B
            self.cy += 1
          when Key::C
            self.cx += 1
          when Key::D
            self.cx -= 1
          end
        end
      when Key::CTRL_C, Key::CTRL_Q
        exit 0
      else
        insert(ch)
      end
    end
  end
end
Row = Struct.new(
  :chars,
)
E = Editor.new
E.row = []
E.filename = ARGV[0].dup
E.cx = 0
E.cy = 0
E.status_line = "status - line"

if File.exist?(E.filename)
  open(E.filename, 'r') do |f|
    while line = f.gets
      row = Row.new(line)
      E.row << row
    end
  end
else
  E.row << Row.new("This is rilo\n")
end

while true
  E.refresh
  E.process_keypress
end
