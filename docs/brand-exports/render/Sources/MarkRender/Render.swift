import SwiftUI
import ImageIO
import UniformTypeIdentifiers

// Visual bounds of the mark inside its 200-unit design canvas.
// With the sill: sill spans x 14…186, frame top starts at y 22, sill bottom y 184.
private let contentWithSill = CGRect(x: 14, y: 22, width: 172, height: 162)
// Without the sill: outer frame only, x 22…178, y 22…178.
private let contentNoSill = CGRect(x: 22, y: 22, width: 156, height: 156)

private let canvasUnit: CGFloat = 200

@MainActor
private func writePNG(_ view: some View, size: CGFloat, to url: URL, opaque: Bool = false) throws {
    let renderer = ImageRenderer(content: view.frame(width: size, height: size))
    renderer.scale = 1
    renderer.isOpaque = opaque
    guard var cg = renderer.cgImage else {
        throw Failure("ImageRenderer produced no image for \(url.lastPathComponent)")
    }
    // App Store icons must ship with no alpha channel at all; isOpaque alone
    // still leaves a (fully-opaque) alpha channel on the CGImage, so redraw
    // into a bitmap context that has none.
    if opaque {
        guard let ctx = CGContext(data: nil,
                                  width: cg.width,
                                  height: cg.height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw Failure("could not create opaque context for \(url.lastPathComponent)")
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        guard let flattened = ctx.makeImage() else {
            throw Failure("could not flatten \(url.lastPathComponent)")
        }
        cg = flattened
    }
    guard let dest = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else {
        throw Failure("could not create PNG destination at \(url.path)")
    }
    CGImageDestinationAddImage(dest, cg, nil)
    guard CGImageDestinationFinalize(dest) else {
        throw Failure("could not finalize \(url.path)")
    }
    print("wrote \(url.lastPathComponent)  \(cg.width)×\(cg.height)")
}

private struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ d: String) { description = d }
}

/// The mark on its bare 200-unit canvas, scaled to `size`.
private func plainMark(size: CGFloat, showSill: Bool) -> some View {
    CatWindowMark(size: size, showSill: showSill)
}

/// App-icon composition: opaque cream field, mark scaled to `inset` of the
/// canvas width and optically centred on its real visual bounds (the raw
/// canvas has asymmetric padding, so centring the 200-unit box would sit low).
private func iconComposition(size: CGFloat,
                             showSill: Bool = true,
                             inset: CGFloat = 0.66,
                             background: Color,
                             frame: Color = .coral,
                             glass: Color = .cream) -> some View {
    let bounds = showSill ? contentWithSill : contentNoSill
    // Scale so the content's width occupies `inset` of the icon.
    let markSize = size * inset * (canvasUnit / bounds.width)
    let s = markSize / canvasUnit
    let contentW = bounds.width * s
    let contentH = bounds.height * s
    let dx = (size - contentW) / 2 - bounds.minX * s
    let dy = (size - contentH) / 2 - bounds.minY * s

    return ZStack(alignment: .topLeading) {
        background
        CatWindowMark(size: markSize,
                      showSill: showSill,
                      frameColor: frame,
                      glassColor: glass)
            .offset(x: dx, y: dy)
    }
    .frame(width: size, height: size, alignment: .topLeading)
    .clipped()
}

@main
struct Main {
    @MainActor
    static func main() {
        let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1
                         ? CommandLine.arguments[1]
                         : FileManager.default.currentDirectoryPath)
        do {
            try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

            // 1. The mark alone, transparent background, on its native canvas.
            for size in [1024, 512, 256, 128] as [CGFloat] {
                try writePNG(plainMark(size: size, showSill: true),
                             size: size,
                             to: outDir.appendingPathComponent("cat-window-mark-\(Int(size)).png"))
            }

            // 2. Sill-less variant (what the app uses at small sizes).
            try writePNG(plainMark(size: 1024, showSill: false),
                         size: 1024,
                         to: outDir.appendingPathComponent("cat-window-mark-nosill-1024.png"))

            // 3. On the brand cream surface, transparent-free, for slide decks etc.
            try writePNG(
                ZStack { Color.cream; CatWindowMark(size: 1024, showSill: true) },
                size: 1024,
                to: outDir.appendingPathComponent("cat-window-mark-cream-1024.png"),
                opaque: true)

            // 4. App Store icon candidates, per docs/app-icon-specs.md: background
            //    must be Cream Soft or Coral. Flattened to no alpha channel.
            try writePNG(iconComposition(size: 1024, background: .creamSoft),
                         size: 1024,
                         to: outDir.appendingPathComponent("AppIcon-creamsoft-1024.png"),
                         opaque: true)

            // On a coral field the coral frame would vanish, so the frame flips to
            // Cream Soft and the glass to Cream to keep the mullions readable.
            try writePNG(iconComposition(size: 1024,
                                         background: .coral,
                                         frame: .creamSoft,
                                         glass: .cream),
                         size: 1024,
                         to: outDir.appendingPathComponent("AppIcon-coral-1024.png"),
                         opaque: true)
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n".utf8))
            exit(1)
        }
    }
}
