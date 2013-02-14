module.exports = (app) ->
    path = require 'path'
    fs = require 'fs'
    app.get '/' , (req, res) ->
        res.render 'index', {action: 'Do Something!'}

    WORKING_DIRECTORY = path.resolve process.env.CT_EDITABLE_ROOT ? './'

    make_absolute = (file) ->
        target = path.join WORKING_DIRECTORY, file
        if target[0...WORKING_DIRECTORY.length] == WORKING_DIRECTORY
            target
        else
            null

    app.get /^\/edit\/(.*)/ , (req, res) ->
        file = req.params[0]
        target = make_absolute file
        if target?
            readFile = -> fs.readFile target, (err, contents) ->
                base_path = "/edit/#{file}".replace /\/[^\/]*$/, '/'
                if err
                    if err.code == 'ENOENT' # File not found
                        res.render 'edit', {base_path, file, contents: ''}
                    else
                        res.send 400, err
                else
                    res.render 'edit', {base_path, file, contents}
            fs.stat target, (err, stat) ->
                if not err and stat.isDirectory()
                    fs.readdir target, (err, files) ->
                        if err
                            readFile()
                        else
                            base_path = "/edit/#{file}/".replace /\/\//g, "/"
                            res.render 'folder', {target, base_path, files}
                else
                    readFile()
        else
            res.send 400, 'Invalid File'

    app.post /^\/edit\/(.+)/ , (req, res) ->
        file = req.params[0]
        target = make_absolute file
        console.log req.body
        if target?
            fs.writeFile target, req.body.content, (err) ->
                if err
                    res.send 400, err
                else
                    res.send {okay: true}
        else
            res.send 400, 'Invalid File'


