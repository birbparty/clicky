import windy, boxy, vmath, bumpy, chroma, std/strformat, std/times
import ./render
import ./ui_helpers

const
  WindowW*: int32 = 800
  WindowH*: int32 = 600

  TitleY    = 30.0'f32
  CurrencyY = 90.0'f32
  PassiveY  = 140.0'f32

  ClickCostInit:   int32 = 10
  PassiveCostInit: int32 = 25

  CoinFrames    = 8
  CoinFrameTime = 0.06'f64

type
  Game = object
    currency:    int64
    clickPower:  int32
    passiveRate: int32
    clickCost:   int32
    passiveCost: int32
    accumulator: float64
    animPlaying: bool
    animFrame:   int32
    animTimer:   float64
    ctx:         RenderCtx

let ClickButton    = rect(vec2(80,  220), vec2(240, 240))
let ClickUpgrade   = rect(vec2(400, 220), vec2(320, 110))
let PassiveUpgrade = rect(vec2(400, 350), vec2(320, 110))
let CoinDest       = rect(vec2(125, 232), vec2(150, 150))

func nextCost(c: int32): int32 =
  (c * 3) div 2

proc initGame(bxy: Boxy): Game =
  result = Game(
    clickPower:  1,
    clickCost:   ClickCostInit,
    passiveCost: PassiveCostInit,
    ctx:         initRender(bxy),
  )

proc update(g: var Game, dt: float32, window: Window) =
  g.accumulator += float64(dt) * float64(g.passiveRate)
  while g.accumulator >= 1.0:
    g.currency += 1
    g.accumulator -= 1.0

  if g.animPlaying:
    g.animTimer += float64(dt)
    while g.animTimer >= CoinFrameTime:
      g.animTimer -= CoinFrameTime
      g.animFrame += 1
      if g.animFrame >= CoinFrames:
        g.animFrame = CoinFrames - 1
        g.animPlaying = false
        g.currency += int64(g.clickPower)
        break

  if window.buttonPressed[MouseLeft]:
    let mouse = window.mousePos.vec2
    if ClickButton.overlaps(mouse):
      g.animPlaying = true
      g.animFrame = 0
      g.animTimer = 0.0
    elif ClickUpgrade.overlaps(mouse) and g.currency >= int64(g.clickCost):
      g.currency -= int64(g.clickCost)
      g.clickPower += 1
      g.clickCost = nextCost(g.clickCost)
    elif PassiveUpgrade.overlaps(mouse) and g.currency >= int64(g.passiveCost):
      g.currency -= int64(g.passiveCost)
      g.passiveRate += 1
      g.passiveCost = nextCost(g.passiveCost)

proc draw(g: Game, bxy: Boxy) =
  let W = float32(WindowW)
  let H = float32(WindowH)
  let black   = color(0, 0, 0, 1)
  let dkgray  = color(0.31, 0.31, 0.31, 1)
  let green   = color(0.0, 0.76, 0.38, 1.0)
  let dkgreen = color(0.0, 0.46, 0.22, 1.0)
  let dkgrn2  = color(0.0, 0.28, 0.13, 1.0)

  # Fixed logical size — NOT window.size (returns physical pixels on Retina)
  bxy.beginFrame(ivec2(WindowW, WindowH))

  bxy.drawRect(rect(vec2(0, 0), vec2(W, H)), color(0.98, 0.98, 0.98, 1.0))

  g.ctx.drawCenteredText(bxy, "title",    "Idle Clicker",           FontTitle,  dkgray, 0, W, TitleY)
  g.ctx.drawCenteredText(bxy, "currency", &"Currency: {g.currency}", FontLarge,  black,  0, W, CurrencyY)
  g.ctx.drawCenteredText(bxy, "passive",  &"+{g.passiveRate}/sec",   FontMedium, dkgreen,0, W, PassiveY)

  bxy.drawRect(ClickButton, green)
  let thick = 3.0'f32
  bxy.drawRect(rect(ClickButton.xy,                                  vec2(ClickButton.w, thick)), dkgrn2)
  bxy.drawRect(rect(ClickButton.xy + vec2(0, ClickButton.h - thick), vec2(ClickButton.w, thick)), dkgrn2)
  bxy.drawRect(rect(ClickButton.xy,                                  vec2(thick, ClickButton.h)), dkgrn2)
  bxy.drawRect(rect(ClickButton.xy + vec2(ClickButton.w - thick, 0), vec2(thick, ClickButton.h)), dkgrn2)

  bxy.drawImage("coin" & $g.animFrame, rect = CoinDest)

  let cx  = ClickButton.x
  let cw  = ClickButton.w
  let topY = 388.0'f32
  g.ctx.drawCenteredText(bxy, "click_lbl", "CLICK",              FontTitle, black, cx, cw, topY)
  g.ctx.drawCenteredText(bxy, "click_pwr", &"(+{g.clickPower})", FontLarge, black, cx, cw, topY + FontTitle)

  g.ctx.drawUpgradeButton(bxy, ClickUpgrade,
    "Click Power", &"Level: {g.clickPower}", "+1 per click", &"Cost: {g.clickCost}",
    g.currency >= int64(g.clickCost), "cu_")

  g.ctx.drawUpgradeButton(bxy, PassiveUpgrade,
    "Passive Income", &"Level: {g.passiveRate}", "+1 per second", &"Cost: {g.passiveCost}",
    g.currency >= int64(g.passiveCost), "pu_")

  bxy.endFrame()

proc run*(window: Window, bxy: Boxy) =
  var g = initGame(bxy)
  var prevTime = epochTime()

  window.onFrame = proc() =
    let now = epochTime()
    let dt  = float32(now - prevTime)
    prevTime = now
    g.update(dt, window)
    g.draw(bxy)
    window.swapBuffers()

  while not window.closeRequested:
    pollEvents()
