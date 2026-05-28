import raylib
import ./game/run

proc main() =
  initWindow(WindowW, WindowH, "Idle Clicker")
  setTargetFps(60)
  run()
  closeWindow()

when isMainModule:
  main()
