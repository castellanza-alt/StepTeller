import SwiftUI
import CoreText

// MARK: - 390 pt canvas

/// Draws `content` on a 390 pt wide canvas (handoff coordinates) and scales it to the available
/// width. `height` is the canvas height in handoff points.
struct MangaCanvas<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        let s = width / Manga.frameWidth
        content()
            .frame(width: Manga.frameWidth, height: height, alignment: .topLeading)
            .scaleEffect(s, anchor: .topLeading)
            .frame(width: width, height: height * s, alignment: .topLeading)
    }
}

extension View {
    /// Places the view with its top-left corner at (x, y) on the canvas (like CSS `left/top`).
    /// `offset` does not affect layout: every child stays independent of the others.
    func at(_ x: CGFloat, _ y: CGFloat) -> some View {
        fixedSize()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(x: x, y: y)
    }
}

/// Absolute-coordinates container: children are placed with `.at(x, y)`.
struct Board<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack(alignment: .topLeading) { content() }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - CSS transforms

/// `transform: rotate(r) skewX(k) scaleX(sx)` around `anchor` (the CSS `transform-origin`).
/// Does not change the footprint, as in CSS.
struct MangaTransform: GeometryEffect {
    var rotation: Double
    var skew: Double
    var scaleX: CGFloat = 1
    var anchor: UnitPoint = .center

    func effectValue(size: CGSize) -> ProjectionTransform {
        let ax = size.width * anchor.x, ay = size.height * anchor.y
        let t = CGAffineTransform(translationX: -ax, y: -ay)
            .concatenating(CGAffineTransform(scaleX: scaleX, y: 1))
            .concatenating(CGAffineTransform(a: 1, b: 0, c: tan(skew * .pi / 180), d: 1, tx: 0, ty: 0))
            .concatenating(CGAffineTransform(rotationAngle: rotation * .pi / 180))
            .concatenating(CGAffineTransform(translationX: ax, y: ay))
        return ProjectionTransform(t)
    }
}

extension View {
    func manga(rotate: Double = 0, skew: Double = 0, scaleX: CGFloat = 1, anchor: UnitPoint = .center) -> some View {
        modifier(MangaTransform(rotation: rotate, skew: skew, scaleX: scaleX, anchor: anchor))
    }
}

// MARK: - Text

/// Anton text with `font: size/lineHeight` and `letter-spacing` in em, as in CSS: the line is
/// `size × lineHeight` tall and the text is centered vertically (half leading).
/// With `minScale` the text shrinks down to that scale if it does not fit the offered width
/// (longer translations); if it fits it stays identical.
struct AntonText: View {
    let text: String
    let size: CGFloat
    var lineHeight: CGFloat = 1
    var tracking: CGFloat = 0
    var color: Color? = nil
    var minScale: CGFloat? = nil

    init(_ text: String, _ size: CGFloat, lineHeight: CGFloat = 1, tracking: CGFloat = 0, color: Color? = nil,
         minScale: CGFloat? = nil) {
        self.text = text; self.size = size; self.lineHeight = lineHeight; self.tracking = tracking; self.color = color
        self.minScale = minScale
    }

    @Environment(\.manga) private var c

    var body: some View {
        Text(text)
            .font(.anton(size))
            .tracking(size * TitleFont.tracking(tracking))
            .foregroundStyle(color ?? c.ink)
            .lineLimit(1)
            .minimumScaleFactor(minScale ?? 1)
            .fixedSize(horizontal: minScale == nil, vertical: true)
            .frame(height: size * lineHeight)
    }
}

/// Text as a path (CoreText), for outlined numbers (`-webkit-text-stroke`) and hard shadows.
struct GlyphText: View {
    let text: String
    let size: CGFloat
    var lineHeight: CGFloat = 1
    var tracking: CGFloat = 0
    var fill: Color
    var stroke: Color? = nil
    var strokeWidth: CGFloat = 0
    /// Hard shadow (`text-shadow: dx dy 0 color`).
    var shadow: (color: Color, dx: CGFloat, dy: CGFloat)? = nil

    var body: some View {
        let g = GlyphText.path(text, size: size, tracking: size * TitleFont.tracking(tracking))
        let h = size * lineHeight
        let baseline = (h - (AntonMetrics.ascent + AntonMetrics.descent) * size) / 2 + AntonMetrics.ascent * size
        let path = Path(g.path).applying(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: baseline))
        ZStack(alignment: .topLeading) {
            if let shadow {
                ZStack {
                    path.fill(shadow.color)
                    if stroke != nil, strokeWidth > 0 { path.stroke(shadow.color, lineWidth: strokeWidth) }
                }
                .offset(x: shadow.dx, y: shadow.dy)
            }
            path.fill(fill)
            if let stroke, strokeWidth > 0 {
                path.stroke(stroke, style: StrokeStyle(lineWidth: strokeWidth, lineJoin: .round))
            }
        }
        .frame(width: g.width, height: h, alignment: .topLeading)
        .accessibilityElement()
        .accessibilityLabel(text)
    }

    /// Paths already computed. Keys include numbers that change (today's steps, records): beyond a certain
    /// number of entries it is cleared, so memory stays bounded in long sessions. Body only, hence main actor.
    @MainActor private static var cache: [String: (path: CGPath, width: CGFloat)] = [:]
    private static let cacheLimit = 128

    @MainActor static func path(_ text: String, size: CGFloat, tracking: CGFloat) -> (path: CGPath, width: CGFloat) {
        let key = "\(text)|\(size)|\(tracking)"
        if let hit = cache[key] { return hit }
        if cache.count >= cacheLimit { cache.removeAll(keepingCapacity: true) }
        let font = TitleFont.ctFont(size)
        let attr = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTKernAttributeName as String): tracking,
        ])
        let line = CTLineCreateWithAttributedString(attr)
        let out = CGMutablePath()
        for run in (CTLineGetGlyphRuns(line) as? [CTRun]) ?? [] {
            // each run with its own font: Anton, the cascaded Asian font or the iOS fallback
            let attributes = CTRunGetAttributes(run) as NSDictionary
            // `as? CTFont` does not exist for CoreFoundation types: the type is checked before converting
            let value = attributes[kCTFontAttributeName as String] as CFTypeRef?
            let runFont = value.map { CFGetTypeID($0) == CTFontGetTypeID() } == true ? (value as! CTFont) : font
            let n = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: n)
            var positions = [CGPoint](repeating: .zero, count: n)
            CTRunGetGlyphs(run, CFRange(location: 0, length: n), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: n), &positions)
            for i in 0..<n {
                guard let gp = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) else { continue }
                out.addPath(gp, transform: CGAffineTransform(translationX: positions[i].x, y: positions[i].y))
            }
        }
        let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        let result = (path: out as CGPath, width: width)
        cache[key] = result
        return result
    }
}

/// Label on a solid background (e.g. «PASSI» on `ink`).
struct TagText: View {
    let text: String
    let size: CGFloat
    var tracking: CGFloat = 0
    var foreground: Color
    var background: Color
    var border: Color? = nil
    var padding = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

    var body: some View {
        AntonText(text, size, tracking: tracking, color: foreground)
            .padding(padding)
            .background(background)
            .overlay { if let border { Rectangle().strokeBorder(border, lineWidth: 2) } }
    }
}
