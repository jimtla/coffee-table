module.exports = (app) ->

    app.get '/' , (req, res) ->
        res.render 'index', {action: 'Do Something!'}

    app.get '/action/:action' , (req, res) ->
        res.render 'index', {action: req.params.action}

    app.get '/hello', (req, res) ->
        res.send 'Hello Node'

    app.get '/hello/:name', (req, res) ->
        res.send "Hello #{req.params.name}"
