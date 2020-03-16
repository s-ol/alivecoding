----
-- Update scheduling policy for `Op` arguments.
--
-- @classmod Input
import Value from require 'core.value'
import Result from require 'core.result'

local ColdInput, ValueInput, EventInput, IOInput

class Input
--- Input interface.
--
-- Methods that have to be implemented by `Input` implementations.
-- @section interface

  --- create a new Input.
  --
  -- `value` is either a `Value` or a `Result` instance and should be
  -- unwrapped and assigned to `stream`.
  --
  -- @classmethod
  -- @tparam Value|Result value
  new: (value) =>
    assert value, "nil passed to Input: #{value}"
    @stream = switch value.__class
      when Result
        assert value.value, "Input from result without value!"
      when Value
        value
      else
        error "Input from unknown value: #{value}"

  --- copy state from old instance (optional).
  --
  -- called by `Op:setup` with another `Input` instance or `nil` once this instance is
  -- registered. Must prepare this instance for `dirty`.
  --
  -- May enter a 'setup state' that is exited using `finish_setup`.
  --
  -- @tparam ?Input prev previous `Input` intance or nil
  setup: (prev) =>

  --- whether this input requires processing (optional).
  --
  -- must return a boolean indicating whether `Op`s that refer to this instance
  -- should be notified (via `Op:tick`). If not overwritten, delegates to
  -- `stream`:@{Value:dirty|dirty}.
  --
  -- @treturn bool whether processing is necessary
  dirty: => @stream\dirty!

  --- leave setup state (optional).
  --
  -- called after the `Op` has completed (or skipped) its first `Op:tick` after
  -- `Op:setup`. Must prepare this instance for dataflow operation.
  finish_setup: =>

  --- unwrap to Lua value (optional).
  --
  -- @treturn any the raw Lua value
  unwrap: => @stream\unwrap!

  --- return the type name of this `Input` (optional).
  type: => @stream.type

  --- the current value
  --
  -- @tfield Value stream

--- members
-- @section members

  --- alias for `unwrap`.
  __call: => @stream\unwrap!

  __tostring: => "#{@@__name}:#{@stream}"
  __inherited: (cls) =>
    cls.__base.__call = @__call
    cls.__base.__tostring = @__tostring

--- static functions
-- @section static

  --- Create a `cold` `Input`.
  --
  -- Never marked dirty. Use this for input streams that are only read when
  -- another `Input` is dirty.
  --
  -- @tparam Value|Result value
  @cold: (value) -> ColdInput value

  --- Create a `value` `Input`.
  --
  -- Marked dirty for the eval-tick if old and new `Value` differ. This is the
  -- most common `Input` strategy. Should be used whenever a
  -- value denotes state.
  --
  -- @tparam Value|Result value
  @value: (value) -> ValueInput value

  --- Create an `event` `Input`.
  --
  -- Only marked dirty if the `Value` itself is dirty. Should be used whenever
  -- an `Input` denotes a momentary event or impulse.
  --
  -- @tparam Value|Result value
  @event: (value) -> EventInput value

  --- Create an `IO` `Input`.
  --
  -- Marked dirty only when an `IO` is dirty. Must be used only for `Value`s
  -- which @{Value:unwrap|unwrap} to `IO` instances.
  --
  -- @tparam Value|Result value
  @io: (value) -> IOInput value

class ColdInput extends Input
  dirty: => false

class ValueInput extends Input
  setup: (old) => @dirty_setup = not old or @stream != old.stream
  finish_setup: => @dirty_setup = nil
  dirty: =>
    return @dirty_setup if @dirty_setup != nil
    @stream\dirty!

class EventInput extends Input

class IOInput extends Input
  impure: true
  dirty: => @stream\unwrap!\dirty!

{
  :Input
}