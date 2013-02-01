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
      # TODO: really just fixes column
      [line, col] = fixed_cursor()
      f()
    id
      insert_char: (c) ->
        if c is diamond.BS
          after_fixing_cursor ->
            unless col is 0
              lines[line].splice col - 1, 1
              col--
        else if c is diamond.LEFT
          after_fixing_cursor -> col--
        else if c is diamond.RIGHT
          after_fixing_cursor -> col++
        else if c is diamond.UP
          line-- if line > 0
        else if c is diamond.DOWN
          line++ if line < lines.length - 1
        else if c is diamond.CR
          after_fixing_cursor ->
            new_line = lines[line].splice col, lines[line].length - col
            lines.splice ++line, 0, new_line
            col = 0
        else
          after_fixing_cursor ->
            lines[line].splice ++col - 1, 0, c
      cursor: fixed_cursor
      set_cursor: (l, c) -> [line, col] = [l, c]
      move_cursor_to_end_of_line: -> after_fixing_cursor ->
        col = lines[line].length - 1 + col_max_adjustment
      move_cursor_to_beginning_of_line: -> after_fixing_cursor ->
        col = 0
      allow_cursor_eol: (allow) ->
        col_max_adjustment = if allow then 1 else 0
      to_string: -> (l.join '' for l in lines).join '\n'
      delete_at_cursor: ([dl, dc]) -> after_fixing_cursor ->
        if dl isnt null
          return if line + dl < 0
          return if line + dl > lines.length
          [line, dl] = [line + dl, Math.abs dl] if dl < 0
          lines.splice line, dl + 1
          line = Math.min line, lines.length - 1
          col = 0
        else
          return if col + dc < 0
          return if col + dc > lines[line].length + col_max_adjustment
          [col, dc] = [col + dc, Math.abs dc] if dc < 0
          lines[line].splice col, dc

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
  omap_is_prefix_ = (keys) ->
    bindings_.is_prefix bindings_.concat(['omap_'], keys)

  modes_.onchange (old_mode, new_mode) ->
    if old_mode is modes_.INSERT and new_mode is modes_.NORMAL
      contents_.insert_char diamond.LEFT
    contents_.allow_cursor_eol new_mode is modes_.INSERT
  [type_unshift_, type_, with_movement_] = do ->
    HANDLED = 'pending:handled'
    IS_PREFIX = 'pending:not_handled_but_is_prefix'
    UNHANDLED = 'pending:unhandled_and_is_not_prefix'
    to_type = []
    prefix = []
    pending = []
    already_typing = false
    type = (keys) ->
      to_type.push k for k in diamond.tokenize keys
      return if already_typing
      already_typing = true
      while to_type.length > 0
        prefix.push to_type.shift()
        not_known_prefix = not modes_.current().is_prefix prefix
        cob = modes_.current().map prefix
        for p in pending
          p_result = p()
          if p_result is HANDLED
            prefix = []
            pending = []
            cob = null
            break
          else if p_result is IS_PREFIX
            not_known_prefix = false
        if cob? and cob() isnt false
          not_known_prefix = false
          prefix = []
          pending = []
        if prefix.length isnt 0 and modes_.current().NAME is modes_.INSERT
          assert.equal 1, prefix.length
          contents_.insert_char prefix.shift()
          not_known_prefix = false
        if not_known_prefix
          prefix = []
          pending = []
      already_typing = false
    type_unshift = (keys) ->
      to_type = diamond.tokenize(keys).concat to_type
      type ''
    with_movement = (cob) ->
      pending_length = prefix.length
      pending_queue_length = pending.length
      pending.push ->
        remainder = prefix.slice pending_length
        movement_cob = omap_ remainder
        if movement_cob?
          cob movement_cob()
          HANDLED
        else if omap_is_prefix_ remainder
          IS_PREFIX
        else
          UNHANDLED
      false
    [type_unshift, type, with_movement]

  do ->
    nmap = (keys, cob) ->
      if typeof cob is 'string'
        cob = do (cob) -> -> type_unshift_ cob
      modes_.nmap keys, cob
    imap = modes_.imap
    {set_cursor, insert_char, delete_at_cursor} = contents_
    omap = omap_

    nmap 'a', 'i<right>'
    nmap 'A', '$a'
    nmap '$', -> contents_.move_cursor_to_end_of_line()
    nmap '0', -> contents_.move_cursor_to_beginning_of_line()
    nmap 'o', 'A<cr>'
    nmap 'O', '0i<cr><up>'
    nmap 'h', -> insert_char diamond.LEFT
    omap 'h', -> [null, -1]
    nmap 'l', -> insert_char diamond.RIGHT
    omap 'l', -> [null, +1]
    nmap 'j', -> insert_char diamond.DOWN
    omap 'j', -> [+1, 0]
    nmap 'k', -> insert_char diamond.UP
    omap 'k', -> [-1, 0]
    nmap 'x', 'dl'
    nmap 'gg', -> set_cursor 0, 0
    omap 'gg', -> [-contents_.cursor()[0], 0]
    nmap 'd', -> with_movement_ (m) -> delete_at_cursor m

  contents: contents_.to_string
  mode: -> modes_.current().NAME
  cursor: contents_.cursor
  type: type_
