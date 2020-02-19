import Result, Value from require 'core.value'

class Scope
  new: (@node, @parent) =>
    @values = {}

  set_raw: (key, val) =>
    value = Value.wrap val, key
    @values[key] = Result :value

  set: (key, val) =>
    L\trace "setting #{key} = #{val} in #{@}"
    assert val.__class == Result, "expected #{key}=#{val} to be Result"
    @values[key] = val

  get: (key, prefix='') =>
    L\debug "checking for #{key} in #{@}"
    if val = @values[key]
      L\trace "found #{val} in #{@}"
      return val

    start, rest = key\match '^(.-)/(.+)'

    if not start
      return @parent and L\push -> @parent\get key

    child = @get start
    assert child and child.value.type == 'scope', "#{start} is not a scope (looking for #{key})"
    child.value\unwrap!\get rest, "#{prefix}#{start}/"

  use: (other) =>
    L\trace "using defs from #{other} in #{@}"
    for k, v in pairs other.values
      @values[k] = v

  from_table: (tbl) ->
    with Scope!
      for k, v in pairs tbl
        \set_raw k, v

  __tostring: =>
    buf = "<Scope"
    buf ..= "@#{@node}" if @node

    depth = -1
    parent = @parent
    while parent
      depth += 1
      parent = parent.parent
    buf ..= " ^#{depth}" if depth != 0

    keys = [key for key in pairs @values]
    if #keys > 5
      keys = [key for key in *keys[,5]]
      keys[6] = '...'
    buf ..= " [#{table.concat keys, ', '}]"

    buf ..= ">"
    buf

:Scope
