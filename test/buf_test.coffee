assert = require 'assert'
buf = require '../src/buf'

describe 'buf', ->

  b = null
  beforeEach -> b = buf.create()

  type = (s) -> b.type s
  contents = (s) -> assert.equal s, b.contents()
  cursor = (l, c) -> assert.deepEqual [l, c], b.cursor()

  normal = 'NORMAL'
  insert = 'INSERT'
  mode = (m) -> assert.equal m, b.mode()

  it 'starts out empty in normal mode', ->
    contents ''
    mode normal

  it 'lets you type stuff', ->
    type 'iHello world!'
    mode insert
    contents 'Hello world!'

  it 'understands diamond notation', ->
    type 'i:help <><ESC>   a for details<ESC>'
    contents ':help <> for details'
    mode normal

  it 'has a cursor', ->
    cursor 0, 0
    type 'iHello'
    cursor 0, 5
    type '<cr>world!'
    cursor 1, 6
    contents 'Hello\nworld!'
    type '<esc>'
    cursor 1, 5

  it 'lets you move the cursor side to side', ->
    type 'icoffee<cr>table<esc>hhh'
    mode normal
    cursor 1, 1
    type 'lible tre'
    mode insert
    contents 'coffee\ntable treble'
    cursor 1, 9
    type '<esc>'
    mode normal
    cursor 1, 8

  it 'correctly handles newlines and insert/append near boundaries', ->
    type 'i<esc>'
    cursor 0, 0
    type 'i<cr>'
    contents '\n'
    type '<esc>a'
    cursor 1, 0
    type 'hello'
    cursor 1, 5
    type '<esc>a'
    cursor 1, 5
    type '<esc>i'
    cursor 1, 4
    type '<esc>'
    cursor 1, 3
    type '<esc>a'
    cursor 1, 4

  it 'correctly handles h/l near boundaries', ->
    type 'lllll'
    cursor 0, 0
    type 'hhhhh'
    cursor 0, 0
    type 'ihello<esc>lllll'
    cursor 0, 4
    type 'hhhhhhhh'
    cursor 0, 0

  it 'can delete characters with `x`', ->
    type 'istevie<cr>wonder<esc>xx'
    contents 'stevie\nwond'
    type 'hhxx'
    contents 'stevie\nwd'
    type 'xx'
    contents 'stevie\n'
    type 'xxxx'
    contents 'stevie\n'

  it 'can handle multicharacter commands such as `gg`', ->
    type 'ihi<esc>'
    cursor 0, 1
    type 'gg'
    cursor 0, 0
    type 'ihello\nworld<esc>ggz}l'
    cursor 0, 1
    type 'z}gg'
    cursor 0, 0

  it 'can delete movements with `d <movement>`', ->
    type 'iheLlo<esc>hhdh'
    cursor 0, 1
    contents 'hLlo'
    type 'lld'
    contents 'hLlo'
    type 'ldl'
    contents 'hL'
    type 'hdh'
    contents 'hL'
    type 'dl'
    contents 'L'

# TODO(ryandm): test newline inserted in the middle of a line
# TODO(ryandm): extract the buffer proper, a line/col view of a file
