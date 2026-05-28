import boxy, pixie, vmath, chroma

type RenderCtx* = object
  typeface*: Typeface

const
  CoinFrames = 8
  CoinFrameW = 128
  CoinFrameH = 128

proc initRender*(bxy: Boxy): RenderCtx =
  let typeface = readTypeface("assets/IBMPlexMono-Bold.ttf")
  let sheet = readImage("assets/coin_sheet.png")
  for i in 0 ..< CoinFrames:
    bxy.addImage("coin" & $i, sheet.subImage(i * CoinFrameW, 0, CoinFrameW, CoinFrameH))
  result = RenderCtx(typeface: typeface)

proc drawText*(ctx: RenderCtx, bxy: Boxy, key: string,
               text: string, size: float32, paint: Color,
               pos: Vec2) =
  var font = newFont(ctx.typeface)
  font.size = size
  font.paint = paint
  let arrangement = typeset(@[newSpan(text, font)], bounds = vec2(2000, 200))
  let bounds = arrangement.computeBounds(mat3()).snapToPixels()
  if bounds.w < 1 or bounds.h < 1: return
  let img = newImage(bounds.w.int, bounds.h.int)
  img.fillText(arrangement, translate(-bounds.xy))
  bxy.addImage(key, img)
  bxy.drawImage(key, pos)

proc drawCenteredText*(ctx: RenderCtx, bxy: Boxy, key: string,
                       text: string, size: float32, paint: Color,
                       containerX, containerW, y: float32) =
  var font = newFont(ctx.typeface)
  font.size = size
  font.paint = paint
  let arrangement = typeset(@[newSpan(text, font)], bounds = vec2(containerW, 200))
  let bounds = arrangement.computeBounds(mat3()).snapToPixels()
  let x = containerX + (containerW - bounds.w) / 2
  if bounds.w < 1 or bounds.h < 1: return
  let img = newImage(bounds.w.int, bounds.h.int)
  img.fillText(arrangement, translate(-bounds.xy))
  bxy.addImage(key, img)
  bxy.drawImage(key, vec2(x, y))
