import boxy, vmath, bumpy, chroma
import ./render

const
  FontTitle*:  float32 = 36
  FontLarge*:  float32 = 28
  FontMedium*: float32 = 20
  FontSmall*:  float32 = 18

proc drawBorder(bxy: Boxy, rec: Rect, thick: float32, c: Color) =
  bxy.drawRect(rect(rec.xy,                          vec2(rec.w, thick)), c)
  bxy.drawRect(rect(rec.xy + vec2(0, rec.h - thick), vec2(rec.w, thick)), c)
  bxy.drawRect(rect(rec.xy,                          vec2(thick, rec.h)), c)
  bxy.drawRect(rect(rec.xy + vec2(rec.w - thick, 0), vec2(thick, rec.h)), c)

proc drawUpgradeButton*(ctx: RenderCtx, bxy: Boxy,
    rec: Rect;
    title, levelLine, effectLine, costLine: string;
    affordable: bool;
    keyPrefix: string) =
  let fill = if affordable: color(0.40, 0.75, 1.0, 1.0)
             else:          color(0.78, 0.78, 0.78, 1.0)
  bxy.drawRect(rec, fill)
  drawBorder(bxy, rec, 2.0, color(0.31, 0.31, 0.31, 1.0))

  let black   = color(0, 0, 0, 1)
  let dkgray  = color(0.31, 0.31, 0.31, 1)
  let costClr = if affordable: black else: color(1, 0, 0, 1)
  var y = rec.y + 4
  let x = rec.x + 12
  ctx.drawText(bxy, keyPrefix & "t", title,      FontMedium, black,  vec2(x, y)); y += FontMedium + 4
  ctx.drawText(bxy, keyPrefix & "l", levelLine,  FontSmall,  dkgray, vec2(x, y)); y += FontSmall  + 4
  ctx.drawText(bxy, keyPrefix & "e", effectLine, FontSmall,  dkgray, vec2(x, y)); y += FontSmall  + 4
  ctx.drawText(bxy, keyPrefix & "c", costLine,   FontSmall,  costClr,vec2(x, y))
