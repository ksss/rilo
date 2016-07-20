module Rilo
  Exit = Class.new(StandardError)
end

def __main__(argv)
  e = Rilo::Editor.new
  e.row = []
  e.cx = 0
  e.cy = 0
  e.rowoff = 0
  e.coloff = 0
  e.status_line = "status - line"
  rows, cols = $stdin.winsize
  e.screenrows = rows
  e.screencols = cols
  e.screenrows -= 2 # status bar
  e.run(argv)
end
