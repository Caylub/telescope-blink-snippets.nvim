-- vim: ft=lua

std = "luajit"

globals = {
  "vim",
}

read_globals = {
  "describe",
  "it",
  "before_each",
  "after_each",
  "assert",
  "pending",
}

ignore = {
  "212", -- unused argument
}

max_line_length = 120
