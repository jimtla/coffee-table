app = (window ? exports).app ?= add_module: (name, module) -> app[name] = module()
_ = (window ? exports)._ ?= debounceR: ->
$ = (window ? exports).$ ?= ->
KeyboardEvent = (window ? exports).KeyboardEvent ?= {}

app.add_module 'keys', ->
    BS: '<BS>'
    CR: '<CR>'
    DOWN: '<DOWN>'
    ESC: '<ESC>'
    LEFT: '<LEFT>'
    RIGHT: '<RIGHT>'
    UP: '<UP>'
    ctrl: (key) ->
        key = key.toUpperCase()
        unless /^[^<]$/.test(key) or /^<(C-)?[A-Z]+>$/.test(key)
            throw new Error("bad key #{key}")
        return key if /^<C-[A-Z]+>$/.test key
        "<C-#{key.replace(/^</, '').replace(/>$/, '')}>"
app.add_module 'grab_focus', ->
    keydown_keycode_map = do ->
        map = {}
        mappings = [
            [KeyboardEvent.DOM_VK_BACK_SPACE, app.keys.BS]
            [KeyboardEvent.DOM_VK_RETURN, app.keys.CR]
            [KeyboardEvent.DOM_VK_ESCAPE, app.keys.ESC]
            [KeyboardEvent.DOM_VK_LEFT, app.keys.LEFT]
            [KeyboardEvent.DOM_VK_UP, app.keys.UP]
            [KeyboardEvent.DOM_VK_RIGHT, app.keys.RIGHT]
            [KeyboardEvent.DOM_VK_DOWN, app.keys.DOWN]
        ]
        for [k, v] in mappings
          map[k] = v
        map
    FIRST_CALL_FOR_NODE = 'app.grab_focus:first_call_for_node'
    (node, callback) ->
        node = $(node)
        unless callback? ^ node.data(FIRST_CALL_FOR_NODE)
            throw new Error '1st (and only 1st) call to grab_focus needs a callback'
        node.focus()
        if callback?
            $(node).data FIRST_CALL_FOR_NODE, true
            node.on 'keydown keypress', (e) ->
                not_yet_implemented = e.altKey or e.metaKey
                good_input =
                    keydown: keydown_keycode_map[e.keyCode]?
                    keypress: e.charCode isnt 0
                if not_yet_implemented or not good_input[e.type]
                    true
                else
                    key = keydown_keycode_map[e.keyCode] ? String.fromCharCode e.charCode
                    key = app.keys.ctrl key if e.ctrlKey
                    callback key

app.add_module 'editor', ->
    normalize_cursor = (state, {normalize_line, normalize_col} = {}) ->
        # Make sure the cursor is between 0 and EOL, and the line is in the buffer
        normalize_line ?= true
        normalize_col  ?= true

        # in insert mode we can go off the end of the line
        end_of_line =
            if state.mode == 'insert'
                0
            else
                -1

        new_line =
            if normalize_line
                Math.max 0, Math.min state.cursor.line, state.buffer.length + end_of_line
            else
                state.cursor.line

        current_line = state.buffer[new_line]
        new_column =
            if normalize_col
                Math.max 0, Math.min state.cursor.col, current_line.length + end_of_line
            else
                state.cursor.col

        make_state state,
            cursor:
                line: new_line
                col: new_column

    move_cursor = ({lines, cols}) -> (state, repeat_number) ->
        normalized_state =
            normalize_cursor state,
                normalize_line: lines != 0
                normalize_col : cols != 0

        moved_state = make_state normalized_state,
            cursor:
                line: normalized_state.cursor.line + lines * repeat_number
                col : normalized_state.cursor.col  + cols * repeat_number

        (normalize_cursor moved_state,
            normalize_line: lines != 0
            normalize_col : cols != 0).cursor

    goto_line = (line) -> (state) ->
        enter_mode('command') normalize_cursor make_state state, {cursor: {line}},
            normalize_line: true
            normalize_col: false

    move_cursor_end_of_file = (state) ->
        line: state.buffer.length - 1
        col:  state.cursor.col

    insert_string_at_cursor = ({string}) -> (state) ->
        normalized_state = normalize_cursor state
        new_buffer = _(state.buffer).clone()
        current_line = new_buffer[normalized_state.cursor.line]
        new_buffer[normalized_state.cursor.line] =
            current_line[...normalized_state.cursor.col] + string +
            current_line[normalized_state.cursor.col...]

        cursor:
            line: normalized_state.cursor.line
            col: normalized_state.cursor.col + string.length
        buffer: new_buffer
        mode: state.mode

    insert = (location) -> (state) ->
        cursor =
            if location == 'before'
                state.cursor
            else if location == 'after'
                line: state.cursor.line
                col: state.cursor.col + 1

        make_state state, {mode: 'insert', cursor}

    insert_line = (location) -> (state) ->
        line_number = state.cursor.line +
            if location == 'before'
                0
            else
                1
        new_buffer = _(state.buffer).clone()
        new_buffer[line_number...line_number] = ''

        make_state state,
            buffer: new_buffer
            cursor: {line: line_number, col: 0}
            mode: 'insert'

    enter_mode = (mode) -> (state) ->
        make_state state, {mode: mode, repeat_number: 0}


    break_line_at_cursor = (state) ->
        normalized_state = normalize_cursor state

        new_buffer = _(state.buffer).clone()
        line = normalized_state.cursor.line
        current_line = new_buffer[line]
        new_buffer[line] = current_line[...normalized_state.cursor.col]
        new_buffer[line..line] = [
            current_line[...normalized_state.cursor.col]
            current_line[normalized_state.cursor.col...]
        ]

        cursor:
            col: 0
            line: line + 1
        buffer: new_buffer
        mode: state.mode

    delete_current_line = (state) ->
        buffer = _.clone state.buffer
        line_number = state.cursor.line
        buffer[line_number..line_number] = []

        normalize_cursor (make_state state, {buffer, mode: 'command'}),
            normalize_col: false

    delete_chars_at_cursor = ({count}) -> (state) ->
        if count == 0
            state
        else
            normalized_state = normalize_cursor state

            new_buffer = _(state.buffer).clone()

            line = normalized_state.cursor.line
            col = normalized_state.cursor.col
            current_line = new_buffer[line]

            if count + col < 0
                remainder = count + col + 1
                previous_line = new_buffer[line - 1] ? ''
                new_buffer[line-1..line] = previous_line +
                    current_line[col...]

                delete_chars_at_cursor({count: remainder})(
                    make_state normalized_state,
                        cursor:
                            line: line - 1
                            col: previous_line.length
                        buffer: new_buffer
                    )

            else if current_line.length < count + col
                remainder = count - (current_line.length - col) - 1
                new_buffer[line..line+1] = current_line[...col] +
                    (new_buffer[line + 1] ? '')
                delete_chars_at_cursor({count: remainder})
                    cursor: {line, col}
                    buffer: new_buffer
                    mode: state.mode
            else
                to_delete_start = Math.min col + count, col
                to_delete_end   = Math.max col + count, col

                new_buffer[normalized_state.cursor.line] =
                    current_line[...to_delete_start] +
                    current_line[to_delete_end...]

                make_state normalized_state,
                    cursor:
                        col: to_delete_start
                    buffer: new_buffer

    open_exec = (content) -> (state) ->
        exec_container = $ '.exec-container'
        exec_container.show()
        exec = exec_container.find '.exec'
        exec.val content
        app.grab_focus exec
        state

    delete_to_cursor = (state, target_cursor) ->
        if state.cursor.line == target_cursor.line
            start = Math.min state.cursor.col, target_cursor.col
            end   = Math.max state.cursor.col, target_cursor.col
            buffer = _.clone state.buffer
            line = buffer[state.cursor.line]
            buffer[state.cursor.line] =
                line[0...start] + line[end...]

            make_state state,
                buffer: buffer
                cursor:
                    line: state.cursor.line
                    col: start
                mode: 'command'
        else
            start_line = Math.min state.cursor.line, target_cursor.line
            end_line   = Math.max state.cursor.line, target_cursor.line

            buffer = _.clone state.buffer
            buffer[start_line..end_line] = []
            make_state state,
                buffer: buffer
                cursor:
                    line: start_line
                    col: 0
                mode: 'command'

    change_to_cursor = (state, target_cursor) ->
        enter_mode('insert') delete_to_cursor state, target_cursor

    change_current_line = (state) ->
        buffer = _.clone state.buffer
        line_number = state.cursor.line
        buffer[line_number] = ""

        normalize_cursor (make_state state, {buffer, mode: 'insert'}),
            normalize_col: false

    # An action_group is a mapping from key codes to "actions", and a list
    # of included action_groups.
    action_groups =
        # A movement is a mapping from modifiers to scan codes to functions from a
        # state to a new cursor position.
        movement: {}
        repeat_number: {}
        command:
            keys: {}
            subgroups:
                movement: (state, cursor) ->
                    make_state state, {cursor}
                repeat_number: (o, state) -> state
        insert:
            keys: {}
            catchall: (state, repeat_number, actual_repeat_number, key) ->
                switch key
                    when app.keys.BS then (delete_chars_at_cursor {count: -1}) state
                    when app.keys.CR then break_line_at_cursor state
                    else (insert_string_at_cursor {string: key}) state
        delete:
            keys: {}
            subgroups:
                movement: delete_to_cursor
                repeat_number: (o, state) -> state
            catchall: enter_mode 'command'
        change:
            keys: {}
            subgroups:
                movement: change_to_cursor
                repeat_number: (o, state) -> state
            catchall: enter_mode 'command'

    action_of_key = (mode, key) ->
        action = action_groups[mode].keys?[key]
        if action?
            action
        else
            if action_groups[mode].subgroups?
                for subgroup, wrapper of action_groups[mode].subgroups
                    action = action_of_key subgroup, key
                    if action?
                        return (state, repeat_number, actual_repeat_number, key) ->
                            wrapper state, action state, repeat_number, actual_repeat_number, key
            action_groups[mode].catchall

    register_command = (mode, key, command) ->
        action_groups[mode] ?= {}
        action_groups[mode].keys ?= {}
        action_groups[mode].keys[key] = command

    register_command 'command', ':', open_exec ':'
    register_command 'command', 'i', insert 'before'
    register_command 'command', 'a', insert 'after'
    register_command 'command', 'o', insert_line 'after'
    register_command 'command', 'O', insert_line 'before'

    register_command 'command', 'd', enter_mode 'delete'
    register_command 'delete' , 'd', delete_current_line
    register_command 'command', 'c', enter_mode 'change'
    register_command 'change' , 'c', change_current_line
    register_command 'command', 'g', enter_mode 'goto'
    register_command 'goto'   , 'g', goto_line 0

    register_command 'movement', 'h', move_cursor {lines:  0, cols: -1}
    register_command 'movement', 'l', move_cursor {lines:  0, cols:  1}
    register_command 'movement', 'j', move_cursor {lines:  1, cols:  0}
    register_command 'movement', 'k', move_cursor {lines: -1, cols:  0}
    register_command 'movement', '<C-U>', move_cursor {lines: -20, cols: 0}
    register_command 'movement', '<C-D>', move_cursor {lines: 20, cols: 0}
    register_command 'movement', 'G', move_cursor_end_of_file

    register_command 'movement', app.keys.LEFT, move_cursor {lines:  0, cols: -1}
    register_command 'movement', app.keys.UP, move_cursor {lines: -1, cols:  0}
    register_command 'movement', app.keys.RIGHT, move_cursor {lines:  0, cols:  1}
    register_command 'movement', app.keys.DOWN, move_cursor {lines:  1, cols:   0}

    register_command 'insert' , '<ESC>', enter_mode 'command'

    push_repeat_number = (number) -> (state, o, repeat_number) ->
        make_state state,
            repeat_number: repeat_number * 10 + number

    for i in [0..9]
        register_command 'repeat_number', i, push_repeat_number i



    make_state = (old_state, changes = {}) ->
        cursor:
            line: changes.cursor?.line ? old_state.cursor.line
            col : changes.cursor?.col  ? old_state.cursor.col
        buffer: changes.buffer ? old_state.buffer
        mode: changes.mode ? old_state.mode
        repeat_number: changes.repeat_number ? old_state.repeat_number

    { render } = do -> # Rendering functions
        render_line = (line, line_number, cursor_col=null, cursor_mode) ->
            contents =
                if cursor_col?
                    _.escape(line[...cursor_col]) +
                    "<span class='cursor'><div class='the-cursor #{cursor_mode}'> </div></span>" +
                    _.escape line[cursor_col...]
                else
                    _.escape line
            "<div class='line'><span class='number'>#{line_number}</span><span class='contents'>#{contents}</span></div>"

        render = ({buffer, cursor, mode}) ->
            lines = for line, line_number in buffer
                if line_number == cursor.line
                    col = Math.min cursor.col, line.length +
                        if mode == 'insert' then 0 else -1
                    render_line line, line_number, col, mode
                else
                    render_line line, line_number

            lines.join ''

        { render }

    save = _.debounceR 1000, (state) ->
        $.ajax
            type: 'POST'
            data:
                content: state.buffer.join '\n'


    start_editing = (node, content) ->
        state =
            cursor:
                line: 0
                col:  0
            buffer: content.split '\n'
            mode: 'command'
            repeat_number: 0

        refresh = -> node.html render state
        do refresh

        scroll_to_cursor = ->
            padding = 50
            cursor_top = node.find('.cursor').offset().top
            scroll_top = $(window).scrollTop()
            window_height = $(window).height()

            if cursor_top - padding < scroll_top
                $(window).scrollTop cursor_top - padding
            else if cursor_top > scroll_top + window_height - padding
                $(window).scrollTop cursor_top + padding - window_height

        app.grab_focus node, (key) ->
            $('.last-keypress').text JSON.stringify key
            action = action_of_key state.mode, key
            if action?
                actual_repeat_number = state.repeat_number
                repeat_number =
                    if actual_repeat_number == 0
                        1
                    else
                        actual_repeat_number

                state = make_state state, { repeat_number: 0 }
                state = action state, repeat_number, actual_repeat_number, key
                save state
                do refresh
                do scroll_to_cursor
                false
            else
                true

        do -> # Handle exec window
            colon_cmd = (command, state) ->
                if command == parseInt(command).toString()
                    goto_line(parseInt command) state
                else
                    state

            execute = (expr, state) ->
                if expr[0] == ':'
                    colon_cmd expr[1...], state
                else
                    state

            exec_container = $ '.exec-container'
            exec = exec_container.find '.exec'
            close_exec = ->
                exec_container.hide()
                app.grab_focus node

            app.grab_focus exec, (key) ->
                switch (key)
                    when app.keys.CR
                        state = execute exec.val(), state
                        do refresh
                        do scroll_to_cursor
                        do close_exec
                    when app.keys.ESC
                        do close_exec


    { start_editing }


app.add_module 'init', ->
    $ ->
        ($ '.editor').each (idx, dom_node) ->
            node = $ dom_node
            contents = node.text()
            node.text ''

            app.editor.start_editing node, contents
        null
