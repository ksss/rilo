module Rilo
  module HighLight
    NONE = 0
    STRING = 1
  end

  Editor = Struct.new(
    :row,
    :filename,
    :cx,
    :cy,
    :rowoff,
    :coloff,
    :status_line,
    :screenrows,
    :screencols,
    :dirty,
  ) do
    def run(argv)
      if argv.length < 1
        puts "rilo filename"
        raise Exit
      end
      self.filename = argv[0].dup
      if File.exist?(filename)
        File.open(filename, 'r') do |f|
          while line = f.gets
            line.chomp!
            row << Row.new(line)
          end
        end
      else
        row << Row.new("")
      end

      $stdin.raw do |_io|
        loop do
          refresh
          process_keypress
        end
      end
    rescue Rilo::Exit
    rescue => e
      puts "rilo's bug:"
      puts "#{e.class}: #{e.message}"
      e.backtrace.each { |i| puts i }
    end

    def insert(ch)
      r = row[filerow]
      if r
        r.chars.insert(cx, ch.chr)
      else
        row[filerow] = Row.new(ch.chr)
      end
      self.dirty = true
      self.cx += 1
    end

    def del_char
      r = filerow >= numrows ? nil : row[filerow]
      return if r.nil? || (filecol.zero? && filerow.zero?)
      if filecol == 0
        upper_chars = row[filerow - 1].chars
        upper_len = upper_chars.length
        upper_chars << row[filerow].chars
        row.delete_at(filerow)
        if cy == 0
          self.coloff -= 1
        else
          self.cy -= 1
        end
        self.cx = upper_len
        if cx >= screencols
          shift = screencols - cx + 1
          self.cx -= shift
          self.coloff += shift
        end
      else
        row[filerow].chars[filecol - 1] = ''
        if cx.zero? && coloff
          self.coloff -= 1
        else
          self.cx -= 1
        end
      end
    end

    def refresh
      buff = "\x1b[?25l\x1b[H"
      screenrows.times do |i|
        r = row[rowoff + i]
        if r
          current_color = -1
          rowstr = r.chars[coloff, screencols]
          if rowstr
            rowstr.each_char.with_index do |ch, index|
              color = r.color(coloff + index)
              if color != current_color
                buff << "\x1b[#{color}m"
                current_color = color
              end
              buff << ch
            end
          end
        else
          buff << "~"
        end
        buff << "\x1b[39m\x1b[0K\r\n"
      end
      if dirty
        status_line << "(modified)"
      end
      buff << "\x1b[0K\x1b[7mrilo #{filerow + 1}/#{row.length + 1} - #{status_line}\x1b[0m\r\n" # loooooooooooooooooooooooooooooong
      buff << "\x1b[0K#{rowoff}+#{cy}+#{screenrows}:#{coloff}+#{cx}+#{screencols}\x1b[#{cy + 1};#{cx + 1}H\x1b[?25h"
      $stdout.syswrite buff
      status_line.clear
    end

    def save
      open(filename, 'w+') do |f|
        f.write "#{row.map(&:chars).join("\n")}\n"
      end
      self.dirty = false
      status_line << "saved"
    end

    def new_line
      r = row[filerow]
      if r
        chars = row[filerow].chars
        rest = chars.slice!(filecol..-1)
        row.insert(filerow + 1, Row.new(rest))
      else
        row << Row.new("")
      end
      self.cy += 1
      self.cx = 0
      self.dirty = true
    end

    def cursol_move(ch)
      r = filerow >= numrows ? nil : row[filerow]
      case ch
      when Key::ARROW_UP
        if cy == 0
          self.rowoff -= 1 if 0 < rowoff
        else
          self.cy -= 1
        end
      when Key::ARROW_DOWN
        if filerow < numrows
          if cy == screenrows - 1
            self.rowoff += 1
          else
            self.cy += 1
          end
        end
      when Key::ARROW_RIGHT
        if r
          if filecol < r.chars.length
            if cx == screencols - 1
              self.coloff += 1
            else
              self.cx += 1
            end
          else
            self.cx = 0
            self.coloff = 0
            if cy == screenrows - 1
              self.rowoff += 1
            else
              self.cy += 1
            end
          end
        end
      when Key::ARROW_LEFT
        if cx == 0
          if coloff > 0
            self.coloff -= 1
          else
            if filerow > 0
              self.cy -= 1
              self.cx = row[filerow] ? row[filerow].chars.length : 0
              if cx > screencols - 1
                self.coloff = cx - screencols + 1
                self.cx = screencols - 1
              end
            end
          end
        else
          self.cx -= 1
        end
      end
      if row[filerow] && filecol > row[filerow].chars.length
        self.cx = row[filerow].chars.length
      end
    end

    def process_keypress
      ch = $stdin.getc.ord
      case ch
      when Key::ESC
        case $stdin.getc.ord
        when Key::LEFT_BLANKET
          case $stdin.getc.ord
          when Key::A then cursol_move(Key::ARROW_UP)
          when Key::B then cursol_move(Key::ARROW_DOWN)
          when Key::C then cursol_move(Key::ARROW_RIGHT)
          when Key::D then cursol_move(Key::ARROW_LEFT)
          end
        end
      when Key::BACKSPACE
        del_char
      when Key::CTRL_S
        save
      when Key::CTRL_C, Key::CTRL_Q
        raise Exit
      when Key::RETURN
        new_line
      else
        insert(ch)
      end
    end

    def filerow
      rowoff + cy
    end

    def filecol
      coloff + cx
    end

    def numrows
      row.length
    end
  end
end
