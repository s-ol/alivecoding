----
-- fltk4lua Copilot GUI.
--
-- @classmod FLTKCopilot
import Logger, version from require 'alv'
import parse_args, Copilot from require 'alv.copilot.base'
import sleep from require 'system'
fl = require 'fltk4lua'

class FLTKLogger extends Logger
  new: (level, @eval, @run) =>
    super level

  set_time: (time) =>
    @output = switch time
      when 'eval' then @eval
      when 'run' then @run
      else error "invalid time '#{time}'"
 
  put: (message) =>
    @output.browser\add message
    if true or @output.sticky.value
      @output.browser.bottomline = @output.browser.nitems

class FLTKCopilot extends Copilot
  new: (arg) =>
    @args = parse_args arg

    @window = with fl.Window { 400, 220, "alv copilot", xclass: 'alv' }
      \size_range 400, 220, nil, nil, 20, 20

    @menubar = with fl.Menu_Bar 0, 0, 400, 20
      \add "&File/About",        nil,  @\about, nil, fl.MENU_DIVIDER
      \add "&File/&Open script", '^o', -> @open!
      \add "&File/&Quit",        '^q', -> @window\hide!
      @pause = \add "Run (^P)",  '^p', @\pause, nil, fl.MENU_TOGGLE
      \add "Help",               nil, -> fl.open_uri version.web

    tile = fl.Tile 5, 40, 390, 160
    @window.resizable = tile
    resize_box = fl.Box { 5, 60, 390, 120, labeltype: fl.NO_LABEL }
    tile.resizable = resize_box

    @eval_out = do
      browser = fl.Browser {
        5, 40, 390, 80, "eval",
        box: fl.GTK_DOWN_BOX, align: fl.ALIGN_TOP_RIGHT
      }
      -- sticky = fl.Check_Button 5, 20, 80, 20, 'sticky'
      -- sticky\set!
      :browser, :sticky

    @run_out = do
      browser = fl.Browser {
        5, 120, 390, 80, "run",
        box: fl.GTK_DOWN_BOX, align: fl.ALIGN_BOTTOM_RIGHT
      }
      -- sticky = fl.Check_Button 5, 200, 80, 20, 'sticky'
      -- sticky\set!
      :browser, :sticky

    tile\end_group!
    @window\end_group!

    @update_status!
    super @args[1]

  about: =>
    fl.alert "alive #{version.tag} fltkCopilot.

visit #{version.web} for more information."

  open: (file) =>
    file or= fl.file_chooser "Open Script", '*.alv', 'script.alv'

    if file
      @paused = false
      super file
      @update_status!

  pause: =>
    @paused = not @paused
    @update_status!

  update_status: =>
    state = fl.MENU_TOGGLE
    if not @paused
      state += fl.MENU_VALUE
    @menubar\menuitem_setp @pause, 'flags', state

    if @paused
      "Paused."
    else
      "Running."

  run: =>
    FLTKLogger\init @args.log, @eval_out, @run_out
    @window\show!

    run = true
    while run
      run = if @paused
        fl.check 1
      else
        @tick!
        sleep 1 / 1000
        fl.check!

{
  :FLTKCopilot
}
