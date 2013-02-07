app = require('../assets/js/app').app
assert = require 'assert'

describe 'app', ->
    describe 'keys.ctrl', ->
        it 'leaves the input alone if it is already ctrl', ->
          assert.equal '<C-C>', app.keys.ctrl '<C-C>'
          assert.equal '<C-BS>', app.keys.ctrl '<C-BS>'
        it 'adds ctrl to "simple" keys', ->
          assert.equal '<C-C>', app.keys.ctrl 'C'
          assert.equal '<C-C>', app.keys.ctrl 'c'
        it 'adds ctrl to "complex" keys', ->
          assert.equal '<C-BS>', app.keys.ctrl '<bs>'
          assert.equal '<C-ESC>', app.keys.ctrl '<esc>'