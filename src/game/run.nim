import windy, boxy, vmath, bumpy, chroma, std/strformat, std/times
import ./render
import ./ui_helpers

const
  WindowW*: int32 = 800
  WindowH*: int32 = 600

  TitleY    = 30.0'f32
  CurrencyY = 90.0'f32
  PassiveY  = 140.0'f32

  ClickCostInit:   int64 = 10
  PassiveCostInit: int64 = 25

  CoinFrameTime = 0.06'f64

type
  Game = object
    currency:    int64
    clickPower:  int32
    passiveRate: int32
    clickCost:   int64
    passiveCost: int64
    accumulator: float64
    animPlaying: bool
    animFrame:   int32
    animTimer:   float64
    ctx:         RenderCtx

let ClickButton    = rect(vec2(80,  220), vec2(240, 240))
let ClickUpgrade   = rect(vec2(400, 220), vec2(320, 110))
let PassiveUpgrade = rect(vec2(400, 350), vec2(320, 110))
let CoinDest       = rect(vec2(ClickButton.x + (ClickButton.w - 150) / 2,
                               ClickButton.y + 12), vec2(150, 150))
let ClickLabelY    = CoinDest.y + CoinDest.h + 6

func nextCost(c: int64): int64 =
  (c * 3) div 2

# Returns (uniform scale, letterbox offset) for the current window size.
# Both draw and update must use this so the transforms stay in lockstep.
proc worldScale(winSize: IVec2): tuple[s: float32, offset: Vec2] =
  let sx = winSize.x.float32 / WindowW.float32
  let sy = winSize.y.float32 / WindowH.float32
  let s  = min(sx, sy)
  let offset = (winSize.vec2 - vec2(float32(WindowW), float32(WindowH)) * s) / 2
  (s, offset)

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
        break

  if window.size.x > 0 and window.size.y > 0 and window.buttonPressed[MouseLeft]:
    let (s, offset) = worldScale(window.size)
    let mouse = (window.mousePos.vec2 - offset) / s
    if ClickButton.overlaps(mouse):
      g.currency += int64(g.clickPower)
      g.animPlaying = true
      g.animFrame = 0
      g.animTimer = 0.0
    elif ClickUpgrade.overlaps(mouse) and g.currency >= g.clickCost:
      g.currency -= g.clickCost
      g.clickPower += 1
      g.clickCost = nextCost(g.clickCost)
    elif PassiveUpgrade.overlaps(mouse) and g.currency >= g.passiveCost:
      g.currency -= g.passiveCost
      g.passiveRate += 1
      g.passiveCost = nextCost(g.passiveCost)

proc draw(g: Game, bxy: Boxy, window: Window) =
  if window.size.x == 0 or window.size.y == 0: return
  let (s, offset) = worldScale(window.size)
  let W = float32(WindowW)
  let H = float32(WindowH)
  let black   = color(0, 0, 0, 1)
  let dkgray  = color(0.31, 0.31, 0.31, 1)
  let green   = color(0.0, 0.76, 0.38, 1.0)
  let dkgreen = color(0.0, 0.46, 0.22, 1.0)
  let dkgrn2  = color(0.0, 0.28, 0.13, 1.0)

  bxy.beginFrame(window.size)
  # Fill letterbox bars (visible when aspect ratio differs from 4:3)
  bxy.drawRect(rect(vec2(0, 0), window.size.vec2), black)
  bxy.saveTransform()
  bxy.applyTransform(translate(offset) * scale(vec2(s, s)))

  bxy.drawRect(rect(vec2(0, 0), vec2(W, H)), color(0.98, 0.98, 0.98, 1.0))

  g.ctx.drawCenteredText(bxy, "title",    "Idle Clicker",           FontTitle,  dkgray, 0, W, TitleY)
  g.ctx.drawCenteredText(bxy, "currency", &"Currency: {g.currency}", FontLarge,  black,  0, W, CurrencyY)
  g.ctx.drawCenteredText(bxy, "passive",  &"+{g.passiveRate}/sec",   FontMedium, dkgreen,0, W, PassiveY)

  bxy.drawRect(ClickButton, green)
  drawBorder(bxy, ClickButton, 3.0, dkgrn2)

  bxy.drawImage("coin" & $g.animFrame, rect = CoinDest)

  let cx = ClickButton.x
  let cw = ClickButton.w
  g.ctx.drawCenteredText(bxy, "click_lbl", "CLICK",              FontTitle, black, cx, cw, ClickLabelY)
  g.ctx.drawCenteredText(bxy, "click_pwr", &"(+{g.clickPower})", FontLarge, black, cx, cw, ClickLabelY + FontTitle)

  g.ctx.drawUpgradeButton(bxy, ClickUpgrade,
    "Click Power", &"Level: {g.clickPower}", "+1 per click", &"Cost: {g.clickCost}",
    g.currency >= g.clickCost, "cu_")

  g.ctx.drawUpgradeButton(bxy, PassiveUpgrade,
    "Passive Income", &"Level: {g.passiveRate}", "+1 per second", &"Cost: {g.passiveCost}",
    g.currency >= g.passiveCost, "pu_")

  bxy.restoreTransform()
  bxy.endFrame()

proc run*(window: Window, bxy: Boxy) =
  var g = initGame(bxy)
  var prevTime = epochTime()

  window.onFrame = proc() =
    let now = epochTime()
    let dt  = float32(min(now - prevTime, 0.1))  # clamp guards against pause/sleep spikes
    prevTime = now
    g.update(dt, window)
    g.draw(bxy, window)
    window.swapBuffers()

  while not window.closeRequested:
    pollEvents()
