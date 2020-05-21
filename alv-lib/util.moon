import Constant, Op, Input, T, val, evt from require 'alv.base'

all_same = (list) ->
  for v in *list[2,]
    if v != list[1]
      return false

  list[1]

switch_ = Constant.meta
  meta:
    name: 'switch'
    summary: "Switch between multiple inputs."
    examples: { '(switch i v1 v2…)' }
    description: "
- when `i` is `true`, the first value is reproduced.
- when `i` is `false`, the second value is reproduced.
- when `i` is a `num`, it is [math/floor][]ed and the matching argument
  (indexed starting from 0) is reproduced."

  value: class extends Op
    val_or_evt = (val! / evt!)!
    pattern = (val.num / val.bool) + val_or_evt*0
    setup: (inputs) =>
      { i, values } = pattern\match inputs

      @out = if values[1].result.metatype ~= '!'
        values[1]\type!\mk_sig!
      else
        values[1]\type!\mk_evt!

      super
        i: Input.hot i
        values: [Input.hot v for v in *values]

    tick: =>
      { :i, :values } = @inputs
      active = switch i!
        when true
          values[1]
        when false
          values[2]
        else
          i = 1 + (math.floor i!) % #values
          values[i]

      @out\set active and active!

edge = Constant.meta
  meta:
    name: 'edge'
    summary: "Convert rising edges to bangs."
    examples: { '(edge bool)' }

  value: class extends Op
    setup: (inputs) =>
      @out or= T.bang\mk_evt!
      value = val.bool\match inputs
      super value: Input.hot value

    tick: =>
      now = @inputs.value!
      if now and not @state
        @out\set true
      @state = now

{
  'switch': switch_
  :edge
}
