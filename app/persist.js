// Generated by CoffeeScript 1.4.0
var get, redis, redis_db, redis_password, redis_url, set, url, _ref, _ref1;

url = require('url');

redis_url = url.parse((_ref = process.env.REDISTOGO_URL) != null ? _ref : 'redis://localhost:6300');

redis = (require('redis')).createClient(redis_url.port, redis_url.hostname);

if (redis_url.auth) {
  _ref1 = redis_url.auth.split(':'), redis_db = _ref1[0], redis_password = _ref1[1];
  redis.auth(redis_password);
}

set = function(key, value, callback) {
  return redis.set(key, value, callback);
};

get = function(key, callback) {
  return redis.get(key, function(err, res) {
    if (err != null) {
      return callback(err);
    } else {
      return callback(null, res);
    }
  });
};

module.exports = {
  set: set,
  get: get,
  redis: redis
};
