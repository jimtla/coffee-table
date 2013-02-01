keys =
  GT: '>'
  LT: '<'
  CR: '\n'
  ESC: '<ESC>'
  LEFT: '<LEFT>'
  RIGHT: '<RIGHT>'
  BS: '<BS>'
  UP: '<UP>'
  DOWN: '<DOWN>'

exports[k] = v for k, v of keys

exports.tokenize = (s) ->
  ts = []
  i = 0
  pushTo = (j) ->
    ts.push c for c in s.substring i, j
    i = j
  while i < s.length
    lt = s.indexOf this.LT, i
    lt = s.length if lt is -1
    pushTo lt
    if i < s.length
      gt = s.indexOf this.GT, i + 1
      if gt is -1
        pushTo s.length
      else
        key = (s.substring lt + 1, gt).toUpperCase()
        if keys[key]?
          ts.push keys[key]
          i = gt + 1
        else
          pushTo lt + 1
  ts
