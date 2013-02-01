assert = require 'assert'
diamond = require './diamond'
id = (x) -> x

exports.create = ->

  contents_ = do ->
    lines = [[]]
    line = col = col_max_adjustment = 0
    fixed_cursor = ->
      corral = (n, min, max) -> Math.max(min, Math.min(max, n))
      l = corral line, 0, lines.length - 1
      c = corral col, 0, lines[line].length - 1 + col_max_adjustment
      [l, c]
    after_fixing_cursor = (f) ->
      [line, col] = fixed_cursor()
      f()
    id
      insert_char: (c) -> after_fixing_cursor ->
        lines[line].splice ++col - 1, 0, c
        if c is diamond.CR
          lines.splice ++line, 0, []
          col = 0
      cursor: fixed_cursor
      displace_col: (dc) -> after_fixing_cursor -> col += dc
      set_cursor: (l, c) -> [line, col] = [l, c]
      allow_cursor_eol: (allow) ->
        col_max_adjustment = if allow then 1 else 0
      to_string: -> (l.join '' for l in lines).join ''
      x: -> after_fixing_cursor -> lines[line].splice col, 1

  bindings_ = do ->
    tree = {}
    concat: (keys, more_keys) ->
      t = (k) -> if typeof k is 'string' then k = diamond.tokenize k else k
      t(keys).concat t more_keys
    map: (keys, cob = null, t = tree) ->
      if keys.length is 0
        COB_KEY = 'map_:COB_KEY'
        return if cob? then t[COB_KEY] = cob else t[COB_KEY] ? null
      [k, keys] = [keys[0], keys.slice 1]
      if cob? then bindings_.map keys, cob, t[k] ?= {}
      else if t[k]? then bindings_.map keys, cob, t[k]
      else null
    is_prefix: (keys, t = tree) ->
      if keys.length is 0
        return t?
      [k, keys] = [keys[0], keys.slice 1]
      t[k]? and bindings_.is_prefix keys, t[k]

  modes_ = do ->
    create_mode = (name) -> do ->
      MODE_KEY = "modes_:#{name}"
      NAME: name
      map: (keys, cob = null) ->
        bindings_.map bindings_.concat([MODE_KEY], keys), cob
      is_prefix: (keys) ->
        bindings_.is_prefix [MODE_KEY].concat(keys)
    nmode = create_mode 'NORMAL'
    imode = create_mode 'INSERT'
    [current_mode, onchange_cobs] = [nmode, []]
    set_mode = (new_mode) ->
      old_mode = modes_.current()
      current_mode = new_mode
      cob old_mode.NAME, new_mode.NAME for cob in onchange_cobs
    nmode.map 'i', -> set_mode imode
    imode.map '<esc>', -> set_mode nmode
    id
      NORMAL: 'NORMAL'
      INSERT: 'INSERT'
      nmap: nmode.map
      imap: imode.map
      current: -> current_mode
      onchange: (cob) -> onchange_cobs.push cob

  omap_ = (keys, cob) ->
    bindings_.map bindings_.concat(['omap_'], keys), cob
  do ->
    omap_ 'h', -> -1

  modes_.onchange (old_mode, new_mode) ->
    if old_mode is modes_.INSERT and new_mode is modes_.NORMAL
      contents_.displace_col -1
    contents_.allow_cursor_eol new_mode is modes_.INSERT
  type_ = do ->
    # TODO: should queue
    prefix = []
    (keys) ->
      for k in diamond.tokenize keys
        prefix.push k
        not_known_prefix = not modes_.current().is_prefix prefix
        cob = modes_.current().map prefix
        if cob?
          prefix = []
          cob()
          not_known_prefix = false
        if prefix.length isnt 0 and modes_.current().NAME is modes_.INSERT
          assert.equal 1, prefix.length
          contents_.insert_char prefix.shift()
          not_known_prefix = false
        if not_known_prefix
          prefix = []
  do ->
    {nmap, imap} = modes_
    {displace_col, set_cursor, insert_char, x} = contents_
    nmap 'a', -> type_ 'i<right>'
    nmap 'h', -> displace_col -1
    nmap 'l', -> displace_col +1
    nmap 'x', -> x()
    nmap 'gg', -> set_cursor 0, 0
    imap '<right>', -> displace_col +1

  contents: contents_.to_string
  mode: -> modes_.current().NAME
  cursor: contents_.cursor
  type: type_
