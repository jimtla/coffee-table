app.add_module 'editor', ->
    KEYS =
        o:
            8 : ['delete_chars_at_cursor', {count: -1}]
            13: ['break_line_at_cursor']
            37: ['move_cursor', {lines:  0, cols: -1}]
            38: ['move_cursor', {lines: -1, cols:  0}]
            39: ['move_cursor', {lines:  0, cols:  1}]
            40: ['move_cursor', {lines:  1, cols:  0}]

    modifiers_to_string = (modifiers) ->
        'o' + (for key in ['ctrl', 'alt', 'meta', 'shift']
            if modifiers[key]
                key[0]
            else
                ''
        ).join ''

    action_of_key = (scan_code, modifiers) ->
        modifier_string = modifiers_to_string modifiers

        [action_name, args] = KEYS[modifier_string]?[scan_code] ? []
        action = actions[action_name]
        [action, args]


    map_characters = (offset, modifiers, characters) ->
        modifier_string = modifiers_to_string modifiers
        KEYS[modifier_string] ?= {}
        for c, i in characters
            KEYS[modifier_string][offset + i] =
                ['insert_string_at_cursor', {string: c}]

    map_characters 32, {}, " "
    map_characters 48, {}, "0123456789"
    map_characters 65, {}, "abcdefghijklmnopqrstuvwxyz"
    map_characters 96, {}, "0123456789*+-./"
    map_characters 186, {}, ";=,-./`"
    map_characters 219, {}, "[\\]'"

    map_characters 32, {shift: true}, " "
    map_characters 48, {shift: true}, ")!@#$%^&*("
    map_characters 65, {shift: true}, "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    map_characters 96, {shift: true}, "0123456789*+-./"
    map_characters 186, {shift: true}, ":+<_>?~"
    map_characters 219, {shift: true}, "{|}\""

    move_cursor = (state, line, col) ->
        cursor:
            line: state.cursor.line + line
            col:  state.cursor.col  + col
        buffer: state.buffer

    normalize_cursor = (state) ->
        # Make sure the cursor is between 0 and EOL
        old_column = state.cursor.col
        current_line = state.buffer[state.cursor.line] ? ''
        new_column =
            Math.min (Math.max 0, old_column), current_line.length

        cursor:
            line: state.cursor.line
            col: new_column
        buffer: state.buffer


    actions =
        move_cursor: ({lines, cols}, state) ->
            normalized_state =
                if cols != 0
                    normalize_cursor state
                else
                    state

            move_cursor normalized_state,  lines, cols

        insert_string_at_cursor: ({string}, state) ->
            normalized_state = normalize_cursor state
            new_buffer = _(state.buffer).clone()
            current_line = new_buffer[normalized_state.cursor.line]
            new_buffer[normalized_state.cursor.line] =
                current_line[...normalized_state.cursor.col] + string +
                current_line[normalized_state.cursor.col...]

            cursor:
                line: normalized_state.cursor.line
                col: normalized_state.cursor.col + 1
            buffer: new_buffer

        delete_chars_at_cursor: ({count}, state) ->
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

                    actions.delete_chars_at_cursor {count: remainder},
                        cursor:
                            line: line - 1
                            col: previous_line.length
                        buffer: new_buffer

                else if current_line.length < count + col
                    remainder = count - (current_line.length - col) - 1
                    new_buffer[line..line+1] = current_line[...col] +
                        (new_buffer[line + 1] ? '')
                    actions.delete_chars_at_cursor {count: remainder},
                        cursor: {line, col}
                        buffer: new_buffer
                else
                    to_delete_start = Math.min col + count, col
                    to_delete_end   = Math.max col + count, col

                    new_buffer[normalized_state.cursor.line] =
                        current_line[...to_delete_start] +
                        current_line[to_delete_end...]

                    cursor:
                        col: to_delete_start
                        line: normalized_state.cursor.line
                    buffer: new_buffer

        break_line_at_cursor: (o, state) ->
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

    { render } = do -> # Rendering functions
        render_line = (line, line_number, cursor_col=null) ->
            contents =
                if cursor_col?
                    line[...cursor_col] +
                    "<span class='cursor'><div class='the-cursor'></div></span>" +
                    line[cursor_col...]
                else
                    line
            "<div class='line'><span class='number'>#{line_number}</span><span class='contents'>#{contents}</span></div>"

        render = ({buffer, cursor}) ->
            lines = for line, line_number in buffer
                if line_number == cursor.line
                    render_line line, line_number, cursor.col
                else
                    render_line line, line_number

            lines.join ''

        { render }

    save = _.debounceR 1000, (state) ->
        console.log state.buffer.join '\n'
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

        refresh = -> node.html render state
        do refresh

        ($ window).on 'keydown', (e) ->
            $('.last-keypress').text e.which
            [action, args] = action_of_key e.which,
                alt: e.altKey
                ctrl: e.ctrlKey
                meta: e.metaKey
                shift: e.shiftKey

            if action?
                state = action args, state
                save state
                refresh()
                false
            else
                true

    { start_editing }


app.add_module 'init', ->
    $ ->
        ($ '.editor').each (idx, dom_node) ->
            node = $ dom_node
            contents = node.text()
            node.text ''

            app.editor.start_editing node, contents
        null
