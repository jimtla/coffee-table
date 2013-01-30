diamond = require './diamond'

exports.create = ->

  mode_ = 'n'
  lines_ = [[]]
  line_ = 0
  col_ = 0

  cobTree_ = {}
  map_ = (mode, c, cob) ->
    cobTree_[mode] ?= {}
    cobTree_[mode][c] ?= {}
    cobTree_[mode][c].cobs ?= []
    cobTree_[mode][c].cobs.push cob
  defaultCobs_ =
    i: (c) ->
      newline = c is diamond.CR
      line_ = if newline then line_ + 1 else line_
      col_ = if newline then 0 else col_ + 1
      lines_[line_] ?= []
      lines_[line_].splice col_ - 1, 0, c unless newline
  defaultCobs_[k] = [v] for k, v of defaultCobs_

  normalizeCursor_ = (r, c) ->
    lmin = 0
    lmax = lines_.length - 1
    line = Math.min(lmax, Math.max(lmin, r))
    cmin = 0
    cmax = (lines_[line] ? []).join('').length
    cmax-- if cmax isnt 0
    cmax++ if mode_ is 'i' and cmax isnt 0
    col = Math.min(cmax, Math.max(cmin, c))
    [line, col]
  setCursor_ = (r, c) ->
    [line_, col_] = normalizeCursor_ r, c

  moveMap_ = {}
  moveMap_['h'] = -> normalizeCursor_ line_, col_ - 1
  moveMap_['l'] = -> normalizeCursor_ line_, col_ + 1
  for k, v of moveMap_
    map_ 'n', k, do (k, v) -> ->
      [r, c] = v()
      setCursor_ r, c

  buf =
    nmap: (c, cob) -> map_ 'n', c, cob
    imap: (c, cob) -> map_ 'i', c, cob
    contents: -> (line.join '' for line in lines_).join '\n'
    mode: -> mode_
    cursor: -> [line_, col_]
    type: (chars) ->
      for c in diamond.tokenize chars
        for f in cobTree_[mode_]?[c]?.cobs ? defaultCobs_[mode_] ? []
          f(c)

  buf.nmap 'i', ->
    mode_ = 'i'
  buf.nmap 'a', ->
    mode_ = 'i'
    setCursor_ line_, col_ + 1
  buf.nmap 'x', ->
    lines_[line_].splice col_, 1
    setCursor_ line_, col_

  buf.imap diamond.ESC, ->
    mode_ = 'n'
    setCursor_ line_, col_ - 1

  buf
