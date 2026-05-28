import raylib
import std/strformat
import ./ui_helpers

const
  WindowW*: int32 = 800
  WindowH*: int32 = 600

  TitleY:    int32 = 30
  CurrencyY: int32 = 90
  PassiveY:  int32 = 140

  ClickCostInit:   int32 = 10
  PassiveCostInit: int32 = 25

  ClickButton    = Rectangle(x: 80,  y: 220, width: 240, height: 240)
  ClickUpgrade   = Rectangle(x: 400, y: 220, width: 320, height: 110)
  PassiveUpgrade = Rectangle(x: 400, y: 350, width: 320, height: 110)

  CoinFrames:     int32   = 8
  CoinFrameW:    float32 = 128.0
  CoinFrameH:    float32 = 128.0
  CoinFrameTime: float64 = 0.06
  CoinSheetPath          = "assets/coin_sheet.png"

  CoinDest = Rectangle(x: 125, y: 232, width: 150, height: 150)

type
  Game = object
    currency:    int64
    clickPower:  int32
    passiveRate: int32
    clickCost:   int32
    passiveCost: int32
    accumulator: float64
    coin:        Texture2D
    animPlaying: bool
    animFrame:   int32
    animTimer:   float64

func nextCost(c: int32): int32 =
  (c * 3) div 2

proc initGame(): Game =
  result = Game(
    clickPower:  1,
    clickCost:   ClickCostInit,
    passiveCost: PassiveCostInit,
    coin:        loadTexture(CoinSheetPath),
  )

proc update(g: var Game; dt: float32) =
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

  let mouse = getMousePosition()
  if isMouseButtonPressed(MouseButton.Left):
    if checkCollisionPointRec(mouse, ClickButton):
      g.animPlaying = true
      g.animFrame = 0
      g.animTimer = 0.0
    elif checkCollisionPointRec(mouse, ClickUpgrade) and
         g.currency >= int64(g.clickCost):
      g.currency -= int64(g.clickCost)
      g.clickPower += 1
      g.clickCost = nextCost(g.clickCost)
    elif checkCollisionPointRec(mouse, PassiveUpgrade) and
         g.currency >= int64(g.passiveCost):
      g.currency -= int64(g.passiveCost)
      g.passiveRate += 1
      g.passiveCost = nextCost(g.passiveCost)

proc draw(g: Game) =
  beginDrawing()
  clearBackground(RayWhite)

  drawCenteredText("Idle Clicker",
                   0'i32, WindowW, TitleY, FontTitle, DarkGray)

  drawCenteredText(&"Currency: {g.currency}",
                   0'i32, WindowW, CurrencyY, FontLarge, Black)

  drawCenteredText(&"+{g.passiveRate}/sec",
                   0'i32, WindowW, PassiveY, FontMedium, DarkGreen)

  drawRectangle(
    int32(ClickButton.x), int32(ClickButton.y),
    int32(ClickButton.width), int32(ClickButton.height),
    Green)
  drawRectangleLines(ClickButton, 3.0'f32, DarkGreen)
  let coinSrc = Rectangle(
    x: float32(g.animFrame) * CoinFrameW, y: 0,
    width: CoinFrameW, height: CoinFrameH)
  drawTexture(g.coin, coinSrc, CoinDest, Vector2(x: 0, y: 0), 0.0'f32, White)
  block:
    let topY = 388'i32
    let cx  = int32(ClickButton.x)
    let cw  = int32(ClickButton.width)
    drawCenteredText("CLICK",            cx, cw, topY,              FontTitle, Black)
    drawCenteredText(&"(+{g.clickPower})", cx, cw, topY + FontTitle, FontLarge, Black)

  let clickAffordable = g.currency >= int64(g.clickCost)
  drawUpgradeButton(
    ClickUpgrade,
    "Click Power",
    &"Level: {g.clickPower}",
    "+1 per click",
    &"Cost: {g.clickCost}",
    clickAffordable)

  let passiveAffordable = g.currency >= int64(g.passiveCost)
  drawUpgradeButton(
    PassiveUpgrade,
    "Passive Income",
    &"Level: {g.passiveRate}",
    "+1 per second",
    &"Cost: {g.passiveCost}",
    passiveAffordable)

  endDrawing()

proc run*() =
  var g = initGame()
  while not windowShouldClose():
    g.update(getFrameTime())
    g.draw()
