import SwiftUI
import StepTellerCore

/// Anton on several lines with the CSS `line-height` (as `AntonText` does for one line). SwiftUI cannot set
/// lines closer than the font's own, so the text is broken into lines here (CoreText, the same font and tracking)
/// and every line is an `AntonText` as tall as `size × lineHeight`.
struct AntonLines: View {
    let text: String
    let size: CGFloat
    let width: CGFloat
    var lineHeight: CGFloat = 1.08
    var tracking: CGFloat = 0.02
    var color: Color? = nil
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            ForEach(Array(Self.lines(text, size: size, tracking: tracking, width: width).enumerated()), id: \.offset) { _, line in
                AntonText(line, size, lineHeight: lineHeight, tracking: tracking, color: color)
            }
        }
        .frame(width: width, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    /// The largest size from `size` down to `size × minScale` (steps of 0.05) at which `text` takes at most
    /// `maxLines` lines in `width`.
    static func fitting(_ text: String, size: CGFloat, minScale: CGFloat, maxLines: Int, tracking: CGFloat,
                        width: CGFloat) -> CGFloat {
        var scale: CGFloat = 1
        while scale > minScale + 0.001,
              lines(text, size: size * scale, tracking: tracking, width: width).count > maxLines {
            scale -= 0.05
        }
        return size * max(scale, minScale)
    }

    /// Lines of `text` in `width`, broken between words as Text would.
    static func lines(_ text: String, size: CGFloat, tracking: CGFloat, width: CGFloat) -> [String] {
        let attributed = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): TitleFont.ctFont(size),
            NSAttributedString.Key(kCTKernAttributeName as String): size * TitleFont.tracking(tracking),
        ])
        let typesetter = CTTypesetterCreateWithAttributedString(attributed)
        let ns = text as NSString
        var out: [String] = []
        var start = 0
        while start < ns.length {
            // a little room: the tracking after the last letter does not count
            var count = CTTypesetterSuggestLineBreak(typesetter, start, Double(width + size * TitleFont.tracking(tracking)))
            if count <= 0 { count = ns.length - start }
            out.append(ns.substring(with: NSRange(location: start, length: count)).trimmingCharacters(in: .whitespaces))
            start += count
        }
        return out
    }
}

/// The Home bubble (T-023 §2): `paper`, `ink` border, solid shadow, tail to the heart, tilted −4°.
struct SpeechBubble: View {
    let text: String
    let level: NastyLevel
    @Environment(\.manga) private var c

    static let width: CGFloat = 210

    private var shadow: Color {
        level == .nasty ? c.red : c.theme == .night ? c.ink.opacity(0.35) : c.ink
    }

    var body: some View {
        AntonLines(text: text.uppercased(with: Locale.current), size: 17, width: Self.width - 24)
            .padding(EdgeInsets(top: 9, leading: 12, bottom: 8, trailing: 12))
            // (the later background goes behind: fill, then the solid shadow under it)
            .background { RoundedRectangle(cornerRadius: 16).fill(c.paper) }
            .background { RoundedRectangle(cornerRadius: 16).fill(shadow).offset(x: 4, y: 4) }
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(c.ink, lineWidth: 2.5) }
            // the tail over the border, its own border on the two outer sides only
            .overlay(alignment: .topLeading) { Tail(fill: c.paper, stroke: c.ink, line: 2.5).offset(x: -7.5, y: 22 - 7.5) }
            .rotationEffect(.degrees(-4), anchor: .leading)
    }
}

/// The first line after the update (T-023 §4): red, louder, with call lines all around, tilted −5°.
struct FirstLineBubble: View {
    let text: String
    @Environment(\.manga) private var c

    static let width: CGFloat = 228

    var body: some View {
        AntonLines(text: text.uppercased(with: Locale.current), size: 19, width: Self.width - 24, color: MangaPalette.onRed)
            .padding(EdgeInsets(top: 10, leading: 12, bottom: 9, trailing: 12))
            .background { RoundedRectangle(cornerRadius: 16).fill(c.red) }
            .background { RoundedRectangle(cornerRadius: 16).fill(c.ink).offset(x: 5, y: 5) }
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(c.ink, lineWidth: 3) }
            .overlay(alignment: .topLeading) { Tail(fill: c.red, stroke: c.ink, line: 3).offset(x: -7.5, y: 22 - 7.5) }
            .background { CallLines(color: c.ink) }
            .rotationEffect(.degrees(-5), anchor: .leading)
    }
}

/// The tail: a 15 pt square turned 45°, bordered on its left and bottom sides (which point outwards).
private struct Tail: View {
    let fill: Color
    let stroke: Color
    let line: CGFloat
    var body: some View {
        ZStack {
            Rectangle().fill(fill)
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 15))
                p.addLine(to: CGPoint(x: 15, y: 15))
            }
            .stroke(stroke, style: StrokeStyle(lineWidth: line, lineCap: .square))
        }
        .frame(width: 15, height: 15)
        .rotationEffect(.degrees(45))
    }
}

/// Seven call lines around the first line (`ink`, 3 pt, 16–20 long), like a manga shout.
private struct CallLines: View {
    let color: Color
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            Path { p in
                for (deg, len) in [(-160.0, 16.0), (-115, 20), (-70, 18), (-25, 20), (20, 16), (70, 18), (125, 20)] {
                    let a = deg * .pi / 180
                    let rx = w / 2 + 12, ry = h / 2 + 12
                    let start = CGPoint(x: w / 2 + rx * cos(a), y: h / 2 + ry * sin(a))
                    p.move(to: start)
                    p.addLine(to: CGPoint(x: start.x + len * cos(a), y: start.y + len * sin(a)))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

/// Heart and bubble in Home, in the room of the notices (T-023 §2): the heart at (12, 336), the bubble at (84, 334).
/// The bubble comes out of the heart when NEAT speaks; a tap on the heart makes it react and say another line.
struct HomeVoice: View {
    let level: NastyLevel
    let quote: NastyQuote
    let first: Bool
    let motion: HeartMotion
    let onTap: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var bubbleHeight: CGFloat = 60

    /// Top-left corner of this view on the Home canvas.
    static let origin = CGPoint(x: 0, y: 326)
    private var heartSize: CGFloat { first ? 74 : 64 }
    /// Heart center on the canvas: (44, 368).
    private var heartCenter: CGPoint { CGPoint(x: 44, y: 368 - Self.origin.y) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimelineView(.animation(paused: scenePhase != .active || !motion.busy(Date()))) { t in
                let b = motion.bubble(level, at: t.date, reduceMotion: reduceMotion)
                bubble
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { bubbleHeight = $0 }
                    .scaleEffect(b.scale, anchor: .leading)
                    .offset(x: (heartCenter.x - 84) * b.fly + b.x,
                            y: (heartCenter.y - (bubbleTop + bubbleHeight / 2)) * b.fly + b.y)
                    .opacity(b.opacity)
            }
            .offset(x: 84, y: bubbleTop)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            Button(action: onTap) {
                LiveHeart(level: level, size: heartSize, motion: motion)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .offset(x: heartCenter.x - heartSize / 2, y: heartCenter.y - heartSize / 2)
            .accessibilityLabel(L10n.text("voice.heart.vo"))
            .accessibilityValue(quote.text)
        }
        .frame(width: Manga.frameWidth, height: 220, alignment: .topLeading)
    }

    private var bubbleTop: CGFloat { (first ? 332 : 334) - Self.origin.y }

    @ViewBuilder private var bubble: some View {
        if first { FirstLineBubble(text: quote.text) } else { SpeechBubble(text: quote.text, level: level) }
    }
}
