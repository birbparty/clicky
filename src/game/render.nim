import boxy, pixie, vmath, chroma, std/os, std/tables

type RenderCtx* = object
  typeface*: Typeface

const
  CoinFrames* = 8
  CoinFrameW  = 128
  CoinFrameH  = 128

# Tracks the last text content rendered per atlas key to skip redundant
# rasterization and GPU uploads when text is unchanged.
var textContent = initTable[string, string]()
var textDrawPos = initTable[string, Vec2]()  # cached positions for centered text

proc initRender*(bxy: Boxy): RenderCtx =
  let assetDir = getAppDir() / "assets"
  let typeface = readTypeface(assetDir / "IBMPlexMono-Bold.ttf")
  let sheet = readImage(assetDir / "coin_sheet.png")
  for i in 0 ..< CoinFrames:
    bxy.addImage("coin" & $i, sheet.subImage(i * CoinFrameW, 0, CoinFrameW, CoinFrameH))
  result = RenderCtx(typeface: typeface)

proc drawText*(ctx: RenderCtx, bxy: Boxy, key: string,
               text: string, size: float32, paint: Color,
               pos: Vec2) =
  if textContent.getOrDefault(key) == text:
    bxy.drawImage(key, pos)
    return
  var font = newFont(ctx.typeface)
  font.size = size
  font.paint = paint
  let arrangement = typeset(@[newSpan(text, font)], bounds = vec2(2000, 200))
  let bounds = arrangement.computeBounds(mat3()).snapToPixels()
  if bounds.w < 1 or bounds.h < 1: return
  let img = newImage(bounds.w.int, bounds.h.int)
  img.fillText(arrangement, translate(-bounds.xy))
  bxy.addImage(key, img)
  textContent[key] = text
  bxy.drawImage(key, pos)

proc drawCenteredText*(ctx: RenderCtx, bxy: Boxy, key: string,
                       text: string, size: float32, paint: Color,
                       containerX, containerW, y: float32) =
  if textContent.getOrDefault(key) == text and key in textDrawPos:
    bxy.drawImage(key, textDrawPos[key])
    return
  var font = newFont(ctx.typeface)
  font.size = size
  font.paint = paint
  let arrangement = typeset(@[newSpan(text, font)], bounds = vec2(containerW, 200))
  let bounds = arrangement.computeBounds(mat3()).snapToPixels()
  if bounds.w < 1 or bounds.h < 1: return
  let x = containerX + (containerW - bounds.w) / 2
  let img = newImage(bounds.w.int, bounds.h.int)
  img.fillText(arrangement, translate(-bounds.xy))
  bxy.addImage(key, img)
  textContent[key] = text
  textDrawPos[key] = vec2(x, y)
  bxy.drawImage(key, vec2(x, y))
