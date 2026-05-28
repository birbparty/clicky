import windy, boxy, opengl
import ./game/run

proc main() =
  let window = newWindow("Idle Clicker", ivec2(WindowW, WindowH))
  window.makeContextCurrent()
  loadExtensions()
  let bxy = newBoxy()
  run(window, bxy)

when isMainModule:
  main()
