assert = require 'assert'
diamond = require '../src/diamond'

describe 'diamond notation (:help <>)', ->
  it 'escapes ESC and LT', ->
    ts = diamond.tokenize "<> hello <ESC> < <lt> wo<Esc>rl<esc>d <huh> <"
    assert.deepEqual [
      "<", ">", " ", "h", "e", "l", "l", "o", " ", diamond.ESC, " ",
      "<", " ", "<", " ", "w", "o", diamond.ESC, "r", "l", diamond.ESC,
      "d", " ", "<", "h", "u", "h", ">", " ", "<",
    ], ts
