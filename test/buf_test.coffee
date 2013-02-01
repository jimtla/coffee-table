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

  it 'understands <BS>, A, 0/$, o/O, <UP>, <DOWN>', ->
    type 'ihello<bs><bs>'
    contents 'hel'
    cursor 0, 3
    type 'ium<esc>i<bs>'
    contents 'helim'
    type 'u<esc>A!'
    contents 'helium!'
    type '<bs><esc>hhi'
    cursor 0, 3
    type '<esc>oargon<esc>'
    contents 'helium\nargon'
    cursor 1, 4
    type 'A~~~'
    cursor 1, 8
    type '<UP>'
    cursor 0, 6
    type '<DOWN>'
    cursor 1, 8
    type '<UP><LEFT><DOWN>'
    cursor 1, 5
    type '<esc>0i~~~<esc>'
    contents 'helium\n~~~argon~~~'
    type 'Oneon'
    contents 'helium\nneon\n~~~argon~~~'
    cursor 1, 4
    type '<down><esc>'
    cursor 2, 3
    type '$'
    cursor 2, 10

  it 'understands dj, dk, dgg', ->
    type 'ihello<cr>world<cr>wide<cr>web<esc>'
    contents 'hello\nworld\nwide\nweb'
    type 'kkj'
    cursor 2, 2
    type 'dji, '
    contents 'hello\n, world'
    cursor 1, 2
    type '<bs><bs><esc>Ocruel<esc>'
    contents 'hello\ncruel\nworld'
    cursor 1, 4
    type 'dk'
    contents 'world'
    cursor 0, 0
    type 'ohow are you<cr>goodbye<cr><esc>kkl'
    cursor 1, 1
    type 'dgx'
    contents 'world\nhow are you\ngoodbye\n'
    cursor 1, 1
    type 'dgg'
    contents 'goodbye\n'
    cursor 0, 0

  it 'understands G, dG, d0, d$', ->
    type 'ihello<cr>world<cr>goodbye<cr>cruel<cr>world<esc>kk'
    cursor 2, 4
    type 'd$'
    contents 'hello\nworld\ngood\ncruel\nworld'
    cursor 2, 3
    type 'G'
    cursor 4, 0
    type 'kkl'
    cursor 2, 1
    type 'ld0'
    contents 'hello\nworld\nod\ncruel\nworld'
    type 'dG'
    contents 'hello\nworld'
