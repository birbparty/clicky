import raylib

const
  FontTitle*:  int32 = 36
  FontLarge*:  int32 = 28
  FontMedium*: int32 = 20
  FontSmall*:  int32 = 18

proc drawCenteredText*(text: string;
                      containerX, containerW, y, fontSize: int32;
                      color: Color) =
  let w = measureText(text, fontSize)
  let x = containerX + (containerW - w) div 2
  drawText(text, x, y, fontSize, color)

proc drawUpgradeButton*(
    rec: Rectangle;
    title, levelLine, effectLine, costLine: string;
    affordable: bool) =
  let fill = if affordable: SkyBlue else: LightGray
  drawRectangle(
    int32(rec.x), int32(rec.y),
    int32(rec.width), int32(rec.height),
    fill)
  drawRectangleLines(rec, 2.0'f32, DarkGray)

  let x = int32(rec.x) + 12'i32
  var y = int32(rec.y) + 4'i32
  drawText(title,      x, y, FontMedium, Black);    y += FontMedium + 4
  drawText(levelLine,  x, y, FontSmall,  DarkGray); y += FontSmall  + 4
  drawText(effectLine, x, y, FontSmall,  DarkGray); y += FontSmall  + 4
  let costColor = if affordable: Black else: Red
  drawText(costLine,   x, y, FontSmall,  costColor)
