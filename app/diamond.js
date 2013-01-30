// Generated by CoffeeScript 1.4.0
var k, keys, v;

keys = {
  GT: '>',
  LT: '<',
  CR: '\n',
  ESC: '<ESC>'
};

for (k in keys) {
  v = keys[k];
  exports[k] = v;
}

exports.tokenize = function(s) {
  var gt, i, key, lt, pushTo, ts;
  ts = [];
  i = 0;
  pushTo = function(j) {
    var c, _i, _len, _ref;
    _ref = s.substring(i, j);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      c = _ref[_i];
      ts.push(c);
    }
    return i = j;
  };
  while (i < s.length) {
    lt = s.indexOf(this.LT, i);
    if (lt === -1) {
      lt = s.length;
    }
    pushTo(lt);
    if (i < s.length) {
      gt = s.indexOf(this.GT, i + 1);
      if (gt === -1) {
        pushTo(s.length);
      } else {
        key = (s.substring(lt + 1, gt)).toUpperCase();
        if (keys[key] != null) {
          ts.push(keys[key]);
          i = gt + 1;
        } else {
          pushTo(lt + 1);
        }
      }
    }
  }
  return ts;
};
