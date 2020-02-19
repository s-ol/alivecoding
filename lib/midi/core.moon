import RtMidiIn, RtMidiOut, RtMidi from require 'luartmidi'
import band, bor, lshift, rshift from require 'bit32'
import Op, Registry from require 'core'

MIDI = {
  [0x9]: 'note-on'
  [0x8]: 'note-off'

  [0xa]: 'after-key'
  [0xd]: 'after-channel'

  [0xb]: 'control-change'
  [0xe]: 'pitch-bend'
  [0xc]: 'program-change'
}

rMIDI = {v,k for k,v in pairs MIDI}

find_port = (Klass, name) ->
  with Klass RtMidi.Api.UNIX_JACK
    id = nil
    for port=1, \getportcount!
      if name == \getportname port
        id = port
        break

    \openport id

class MidiPort
  new: (@inp, @out) =>

  dirty: =>
    @updated == Registry.active!.tick

  tick: =>
    if @inp
      @messages = while true
        delta, bytes = @inp\getmessage!
        break unless delta

        { status, a, b } = bytes
        chan = band status, 0xf
        status = MIDI[rshift status, 4]
        { :status, :chan, :a, :b }

      if @messages
        @updated = Registry.active!.tick

  receive: =>
    assert @inp, "#{@} is not an input port"
    return unless @messages
    coroutine.wrap ->
      for msg in *@messages
        coroutine.yield msg

  send: (status, chan, a, b) =>
    assert @out, "#{@} is not an output port"
    if 'string' == type 'status'
      status = bor (lshift rMIDI[status], 4), chan
    @out\sendmessage status, a, b

class input extends Op
  @doc: "(midi/input name) - create a MIDI input port"

  new: =>
    super 'midi/port'
    @impulses = { Registry.active!.kr }

  setup: (params) =>
    super params
    @assert_types 'str'

  tick: (first) =>
    { name } = @inputs
    if first or name\dirty!
      @out\set MidiPort find_port RtMidiIn, name\unwrap!

    @out\unwrap!\tick!

class output extends Op
  @doc: "(midi/output name) - create a MIDI output port"

  new: =>
    super 'midi/port'

  setup: (params) =>
    super params
    @assert_types 'str'

  tick: (first) =>
    { name } = @inputs
    if first or name\dirty!
      @out\set MidiPort nil, find_port RtMidiOut, name\unwrap!

class inout extends Op
  @doc: "(midi/inout inname outname) - create a bidirectional MIDI port"

  new: =>
    super 'midi/port'
    @impulses = { Registry.active!.kr }

  setup: (params) =>
    super params
    @assert_types 'str', 'str'

  tick: (first) =>
    { inp, out } = @inputs

    if first or inp\dirty! or out\dirty!
      inp, out = inp\unwrap!, out\unwrap!
      @out\set MidiPort (find_port RtMidiIn, inp), (find_port RtMidiOut, out)

    @out\unwrap!\tick!

apply_range = (range, val) ->
  if range.type == 'str'
    switch range\unwrap!
      when 'raw' then val
      when 'uni' then val / 128
      when 'bip' then val / 64 - 1
      when 'rad' then val / 64 * math.pi
      else
        error "unknown range #{@range}"
  elseif range.type == 'num'
    val / 128 * range\unwrap!
  else
    error "range has to be a string or number"

{
  :input
  :output
  :inout
  :apply_range
}
