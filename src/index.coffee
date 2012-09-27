express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'
_ = require 'underscore'
url = require 'url'

app = express()

# Add Connect Assets
app.use assets()

# Parse post requests
app.use express.bodyParser()

# Set the public folder as static assets
app.use express.static(process.cwd() + '/public')

# Set View Engine
app.set 'view engine', 'jade'

(require './edit') app

# Start Server
port = process.env.PORT ? process.env.VMC_APP_PORT ? 3000
app.listen port, -> console.log "Listening on #{port}\nPress CTRL-C to stop server."