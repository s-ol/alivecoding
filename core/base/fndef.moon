----
-- `alive` user-function definition (`fndef`).
--
-- When called, expands to its body with params bound to the fn arguments (see
-- `invoke.fn_invoke`).
--
-- @classmod FnDef

class FnDef
  --- create a new instance
  --
  -- @tparam {Value,...} params (`\quote`d) naming the function parameters
  -- @tparam AST body (`\quote`d) expression the function evaluates to
  -- @tparam Scope scope the lexical scope the function was defined in (closure)
  new: (@params, @body, @scope) =>

  __tostring: =>
    "(fn (#{table.concat [p\stringify! for p in *@params], ' '}) ...)"

{
  :FnDef
}
