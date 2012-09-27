do ->
    to_reverse = ['bind', 'memoize', 'delay', 'defer', 'throttle', 'debounce', 'wrap', 'reduce']
    mixin = {}
    for name in to_reverse then do (name) ->
        mixin["#{name}R"] = (args..., f) -> _(f)[name](args...)
    mixin["reduceR"] = (obj, memo, f) -> _(obj)['reduce'](f, memo)
    _.mixin mixin