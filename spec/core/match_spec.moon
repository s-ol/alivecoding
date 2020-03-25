import val, evt from require 'core.base.match'
import Result, ValueStream, EventStream from require 'core'

mk_val = (type, const) ->
  value = ValueStream type
  with Result :value
    .side_inputs = { 'fake' } unless const

mk_evt = (type, const) ->
  value = EventStream type
  with Result :value
    .side_inputs = { 'fake' } unless const

describe 'val and evt', ->
  describe 'type-less shorthand', ->
    it 'matches metatype', ->
      str = mk_val 'str'
      num = mk_val 'num'
      assert.is.equal str, val!\match { str }
      assert.is.equal num, val!\match { num }
      assert.has.error -> evt!\match { str }
      assert.has.error -> evt!\match { num }

      str = mk_evt 'str'
      num = mk_evt 'num'
      assert.is.equal str, evt!\match { str }
      assert.is.equal num, evt!\match { num }
      assert.has.error -> val!\match { str }
      assert.has.error -> val!\match { num }

    it 'is in recall mode', ->
      value = val!
      event = evt!
      two_equal_values = value + value
      two_equal_events = event + event

      str1 = mk_val 'str'
      str2 = mk_val 'str'
      num = mk_val 'num'
      assert.is.same { str1, str2 }, two_equal_values\match { str1, str2 }
      assert.is.same { str2, str1 }, two_equal_values\match { str2, str1 }
      assert.is.same { num, num }, two_equal_values\match { num, num }
      assert.has.error -> two_equal_values\match { str1, num }
      assert.has.error -> two_equal_values\match { num, str2 }
      assert.has.error -> two_equal_events\match { str1, str2 }

      str1 = mk_evt 'str'
      str2 = mk_evt 'str'
      num = mk_evt 'num'
      assert.is.same { str1, str2 }, two_equal_events\match { str1, str2 }
      assert.is.same { str2, str1 }, two_equal_events\match { str2, str1 }
      assert.is.same { num, num }, two_equal_events\match { num, num }
      assert.has.error -> two_equal_events\match { str1, num }
      assert.has.error -> two_equal_events\match { num, str2 }
      assert.has.error -> two_equal_values\match { str1, str2 }

  describe 'typed shorthand', ->
    it 'matches by metatype', ->
      str = mk_val 'str'
      num = mk_val 'num'
      assert.is.equal str, val.str\match { str }
      assert.is.equal num, val.num\match { num }
      assert.has.error -> evt.str\match { str }
      assert.has.error -> evt.num\match { num }

      str = mk_evt 'str'
      num = mk_evt 'num'
      assert.is.equal str, evt.str\match { str }
      assert.is.equal num, evt.num\match { num }
      assert.has.error -> val.str\match { str }
      assert.has.error -> val.num\match { num }

    it 'matches by type', ->
      str = mk_val 'str'
      num = mk_val 'num'
      assert.is.equal str, val.str\match { str }
      assert.is.equal num, val.num\match { num }
      assert.has.error -> val.num\match { str }
      assert.has.error -> val.str\match { num }

      str = mk_evt 'str'
      num = mk_evt 'num'
      assert.is.equal str, evt.str\match { str }
      assert.is.equal num, evt.num\match { num }
      assert.has.error -> evt.num\match { str }
      assert.has.error -> evt.str\match { num }

describe 'choice', ->
  str = mk_val 'str'
  num = mk_val 'num'
  bool = mk_val 'bool'
  choice = val.str / val.num

  it 'matches either type', ->
    assert.is.equal str, choice\match { str }
    assert.is.equal num, choice\match { num }
    assert.has.error -> choice\match { bool }

  it 'can recall the choice', ->
    same = choice!
    assert.is.equal num, same\match { num }

    same = same + same
    assert.is.same { str, str }, same\match { str, str }
    assert.is.same { num, num }, same\match { num, num }
    assert.has.error -> same\match { str, num }
    assert.has.error -> same\match { num, str }
    assert.has.error -> same\match { bool, bool }

  it 'makes inner types recall', ->
    same = (val! / evt!)!
    same = same + same
    assert.is.same { str, str }, same\match { str, str }
    assert.is.same { num, num }, same\match { num, num }
    assert.is.same { bool, bool }, same\match { bool, bool }
    assert.has.error -> same\match { str, num }
    assert.has.error -> same\match { num, str }

describe 'sequence', ->
  str = mk_val 'str'
  num = mk_val 'num'
  bool = mk_val 'bool'
  seq = val.str + val.num + val.bool

  it 'matches all types in order', ->
    assert.is.same { str, num, bool }, seq\match { str, num, bool }

  it 'can assign non-numeric keys', ->
    named = seq\named 'str', 'num', 'bool'
    assert.is.same { :str, :num, :bool }, named\match { str, num, bool }
    assert.is.same { str, num, bool }, seq\match { str, num, bool }

  it 'fails if too little arguments', ->
    assert.has.error -> seq\match { str, num }

  it 'fails if too many arguments', ->
    assert.has.error -> seq\match { str, num, bool, bool }

  it 'can handle optional children', ->
    opt = -val.str + val.num
    assert.is.same { str, num }, opt\match { str, num }
    assert.is.same { nil, num }, opt\match { num }
    assert.has.error -> opt\match { str, str, num }
    assert.has.error -> opt\match { str, num, num }

  it 'can handle repeat children', ->
    rep = val.str + val.num*2
    assert.is.same { str, {num} }, rep\match { str, num }
    assert.is.same { str, {num,num} }, rep\match { str, num, num }
    assert.has.error -> rep\match { str }
    assert.has.error -> rep\match { str, num, num, num }

describe 'repeat', ->
  str = mk_val 'str'
  num = mk_val 'num'

  times = (n, arg) -> return for i=1,n do arg

  it '*x is [1,x[', ->
    rep = val.str*3
    assert.has.error -> rep\match (times 0, str)
    assert.is.same (times 1, str), rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.is.same (times 3, str), rep\match (times 3, str)
    assert.has.error -> rep\match (times 4, str)
    assert.has.error -> rep\match (times 3, num)

  it '*0 is [1,[', ->
    rep = val.str*0
    assert.has.error -> rep\match (times 0, str)
    assert.is.same (times 1, str), rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.is.same (times 20, str), rep\match (times 20, str)
    assert.has.error -> rep\match (times 3, num)

  it '^x is [0,x[', ->
    rep = val.str^3
    assert.is.same {}, rep\match {}
    assert.is.same (times 1, str), rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.is.same (times 3, str), rep\match (times 3, str)
    assert.has.error -> rep\match (times 4, str)
    assert.has.error -> rep\match (times 3, num)

  it '^0 is [0,[', ->
    rep = val.str^0
    assert.is.same {}, rep\match {}
    assert.is.same (times 1, str), rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.is.same (times 20, str), rep\match (times 20, str)
    assert.has.error -> rep\match (times 3, num)

  it ':rep(min, max) does anything else', ->
    rep = val.str\rep 2, 2
    assert.has.error -> rep\match {}
    assert.has.error -> rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.has.error -> rep\match (times 3, str)
    assert.has.error -> rep\match (times 2, num)

describe 'complex nesting', ->
  it 'just works', ->
    bang = mk_evt 'bang'
    str = mk_val 'str'
    num = mk_val 'num'

    pattern = -evt.bang + val.num*4 + (val.str + (val.num / val.str))\named('key', 'val')^0
    assert.is.same { bang, { num, num }, {} }, pattern\match { bang, num, num }
    assert.is.same { nil, { num }, { { key: str, val: num }, { key: str, val: str } } },
                   pattern\match { num, str, num, str, str }
    assert.has.error -> pattern\match { num, str }
    assert.has.error -> pattern\match { bang, num, num, num, num, num, num }
    assert.has.error -> pattern\match { bang, bang, num }
    assert.has.error -> pattern\match { num, str, num, str }
    assert.has.error -> pattern\match { num, str, num, str, mk_val 'bool' }