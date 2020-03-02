import Value, Op, ValueInput, EventInput, IOInput, match from require 'core'
import apply_range from require 'lib.midi.core'
import bor, lshift from require 'bit32'

unpack or= table.unpack
color = (r, g) -> bor 12, r, (lshift g, 4)

class cc_seq extends Op
  @doc: "(launctl/cc-seq port i start chan [steps [range]]) - CC-Sequencer

returns the value for the i-th step steps (buttons starting from start).
steps defaults to 8.

range can be one of:
- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- 'deg' [ 0 - 360[
- (num) [ 0 - num["

  new: =>
    super 'num'
    @steps = {}

  setup: (inputs) =>
    { port, i, start,
      chan, steps, range } = match 'midi/port num num num num? any?', inputs

    super
      port:  IOInput port
      i:     ValueInput i
      start: ValueInput start
      chan:  ValueInput chan
      steps: ValueInput steps or Value.num 8
      range: ValueInput range or Value.str 'uni'

    if not @out\unwrap!
      @out\set apply_range @inputs.range, 0

  tick: =>
    { :port, :i, :start, :chan, :steps, :range } = @inputs

    if steps\dirty!
      while steps! > #@steps
        table.insert @steps, 0
      while steps! < #@steps
        table.remove @steps

    curr_i = i! % #@steps
    if port\dirty!
      changed = false
      for msg in port!\receive!
        if msg.status == 'control-change' and msg.chan == chan!
          rel_i = msg.a - start!
          if rel_i >= 0 and rel_i < #@steps
            @steps[rel_i+1] = msg.b
            changed = rel_i == curr_i
      @out\set apply_range range, @steps[curr_i+1] if changed
    else
      @out\set apply_range range, @steps[curr_i+1]

class gate_seq extends Op
  @doc: "(launctl/gate-seq port i start chan [steps]) - Gate-Sequencer

returns true or false for the i-th step steps (buttons starting from start).
steps defaults to 8."

  new: =>
    super 'bool', false
    @steps = {}

  setup: (inputs) =>
    { port, i, start, chan, steps } = match 'midi/port num num num num?', inputs

    super
      port:  IOInput port
      i:     ValueInput i
      start: ValueInput start
      chan:  ValueInput chan
      steps: ValueInput steps or Value.num 8

  light = (set, active) ->
    set = if set then 'S' else ' '
    active = if active then 'A' else ' '
    color switch set .. active
      when '  ' then 0, 0
      when ' A' then 1, 1
      when 'S ' then 1, 0
      when 'SA' then 3, 1

  display: (i, active) =>
    { :port, :start, :chan } = @unwrap_all!
    port\send 'note-on', chan, (start + i), light @steps[i+1], active

  tick: =>
    { :port, :i, :start, :chan, :steps } = @inputs

    if steps\dirty!
      while steps! > #@steps
        table.insert @steps, false
      while steps! < #@steps
        table.remove @steps

    curr_i = i! % #@steps

    if port\dirty!
      for msg in port!\receive!
        if msg.status == 'note-on' and msg.chan == chan!
          rel_i = msg.a - start!
          if rel_i >= 0 and rel_i < #@steps
            @steps[rel_i+1] = not @steps[rel_i+1]
            @display rel_i, rel_i == curr_i

    if i\dirty!
      prev_i = (curr_i - 1) % #@steps

      @display curr_i, true
      @display prev_i, false

      @out\set @steps[curr_i+1]

{
  'gate-seq': gate_seq
  'cc-seq': cc_seq
}