// Generated by CoffeeScript 1.4.0
var app, assets, express, port, stylus, url, _, _ref, _ref1;

express = require('express');

stylus = require('stylus');

assets = require('connect-assets');

_ = require('underscore');

url = require('url');

app = express();

app.use(assets());

app.use(express.bodyParser());

app.use(express["static"](process.cwd() + '/public'));

app.set('view engine', 'jade');

(require('./edit'))(app);

port = (_ref = (_ref1 = process.env.PORT) != null ? _ref1 : process.env.VMC_APP_PORT) != null ? _ref : 3000;

app.listen(port, function() {
  return console.log("Listening on " + port + "\nPress CTRL-C to stop server.");
});
