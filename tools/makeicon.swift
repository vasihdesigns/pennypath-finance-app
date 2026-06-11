// Generates the 1024×1024 app icon: three friendly pill "bars" growing upward
// in the app's palette — red (spending), gold (goals), green (net worth) — on white.
// Run: swift tools/makeicon.swift <output.png>

import AppKit

let size = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("Could not create context")
}

// White background
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// CoreGraphics origin is bottom-left, which suits upward bars nicely.
func bar(x: CGFloat, height: CGFloat, color: CGColor) {
    let width: CGFloat = 190
    let baseY: CGFloat = 200
    let rect = CGRect(x: x, y: baseY, width: width, height: height)
    let path = CGPath(roundedRect: rect, cornerWidth: width / 2, cornerHeight: width / 2, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(color)
    ctx.fillPath()
}

let red = CGColor(red: 0.941, green: 0.267, blue: 0.220, alpha: 1)
let gold = CGColor(red: 0.722, green: 0.525, blue: 0.043, alpha: 1)
let green = CGColor(red: 0.020, green: 0.588, blue: 0.412, alpha: 1)

bar(x: 170, height: 330, color: red)
bar(x: 417, height: 510, color: gold)
bar(x: 664, height: 690, color: green)

guard let image = ctx.makeImage() else { fatalError("Could not render image") }
let rep = NSBitmapImageRep(cgImage: image)
guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("Could not encode PNG") }
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
try! data.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath)")
