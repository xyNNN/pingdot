// Zeichnet das App-Icon als 1024er-PNG. Aufruf: swift make-icon.swift <ziel.png>
// (make-icon.sh macht daraus AppIcon.icns.)
import AppKit

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

// Dunkle, abgerundete Kachel im macOS-Raster (824 px auf 1024er-Fläche)
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 186, yRadius: 186)
NSGradient(starting: rgb(38, 43, 54), ending: rgb(13, 15, 20))!.draw(in: tilePath, angle: -90)

let center = NSPoint(x: 512, y: 512)
let green = rgb(52, 211, 102)

func circle(_ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
}

// Ring, in denselben Proportionen wie das Menüleisten-Symbol
let ring = circle(280)
ring.lineWidth = 58
green.withAlphaComponent(0.6).setStroke()
ring.stroke()

// Der Punkt, mit leichtem Schein und Verlauf
let glow = NSShadow()
glow.shadowColor = green.withAlphaComponent(0.7)
glow.shadowBlurRadius = 70
NSGraphicsContext.saveGraphicsState()
glow.set()
green.setFill()
circle(135).fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: rgb(120, 240, 150), ending: rgb(34, 180, 80))!.draw(in: circle(135), angle: -90)

NSGraphicsContext.current?.flushGraphics()
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
