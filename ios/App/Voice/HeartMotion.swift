import SwiftUI
import UIKit
import StepTellerCore

/// Timing curves of the T-023 animations (CSS names): applied to each stretch between two keyframes, as in CSS.
enum Curve {
    case linear, easeInOut, easeOut
    case bezier(Double, Double, Double, Double)

    func callAsFunction(_ x: Double) -> Double {
        switch self {
        case .linear: x
        case .easeInOut: Self.solve(x, 0.42, 0, 0.58, 1)
        case .easeOut: Self.solve(x, 0, 0, 0.58, 1)
        case let .bezier(x1, y1, x2, y2): Self.solve(x, x1, y1, x2, y2)
        }
    }

    /// Cubic Bézier from (0,0) to (1,1): the y at a given x (Newton, then bisection).
    private static func solve(_ x: Double, _ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> Double {
        func bx(_ t: Double) -> Double { 3 * (1 - t) * (1 - t) * t * x1 + 3 * (1 - t) * t * t * x2 + t * t * t }
        func by(_ t: Double) -> Double { 3 * (1 - t) * (1 - t) * t * y1 + 3 * (1 - t) * t * t * y2 + t * t * t }
        func dx(_ t: Double) -> Double { 3 * (1 - t) * (1 - t) * x1 + 6 * (1 - t) * t * (x2 - x1) + 3 * t * t * (1 - x2) }
        var t = x
        for _ in 0..<6 {
            let d = dx(t)
            guard abs(d) > 1e-6 else { break }
            t -= (bx(t) - x) / d
        }
        if t < 0 || t > 1 || abs(bx(t) - x) > 1e-4 {
            var lo = 0.0, hi = 1.0
            t = x
            for _ in 0..<30 {
                if bx(t) < x { lo = t } else { hi = t }
                t = (lo + hi) / 2
            }
        }
        return by(t)
    }
}

/// A CSS `@keyframes` property: values at fractions of the duration, the curve on every stretch.
struct Track {
    let stops: [(Double, Double)]
    let curve: Curve

    init(_ curve: Curve, _ stops: [(Double, Double)]) { self.curve = curve; self.stops = stops }

    func at(_ p: Double) -> Double {
        guard let first = stops.first, let last = stops.last else { return 0 }
        if p <= first.0 { return first.1 }
        if p >= last.0 { return last.1 }
        let i = stops.lastIndex { $0.0 <= p } ?? 0
        let a = stops[i], b = stops[i + 1]
        let local = (p - a.0) / max(1e-9, b.0 - a.0)
        return a.1 + (b.1 - a.1) * curve(local)
    }
}

/// Where every part of the heart is at one instant (T-023 §3). The view draws it; nothing else moves.
struct HeartPose {
    /// The whole heart: heartbeat (at rest) and action (speaking, tap).
    var scaleX = 1.0, scaleY = 1.0, rotation = 0.0, x = 0.0, y = 0.0
    /// Piccante: the crown of spikes and the body.
    var spikesScale = 1.0, spikesRotation = 0.0, bodyScale = 1.0
    /// NASTY: the shards flying off.
    var shardsScale = 1.0, shardsRotation = 0.0, shardsOpacity = 1.0
    /// NASTY: the two halves of the split (x, y, degrees), nil when whole.
    var split: (left: (Double, Double, Double), right: (Double, Double, Double))?
    /// NASTY: light of the cracks (added brightness, 0…1.4) and their red glow (pt on a 200 pt heart).
    var glow = 0.0, glowRadius = 0.0
    /// Piccante: the three puffs (0 = none, otherwise the progress of their flight).
    var puffs = 0.0
    /// «Reduce Motion»: the heart blinks.
    var opacity = 1.0
}

/// Where the bubble is: hidden in the heart, flying out, in place.
struct BubblePose {
    var scale = 1.0, opacity = 1.0
    /// 1 = at the center of the heart, 0 = in its place.
    var fly = 0.0
    var x = 0.0, y = 0.0
}

/// What the heart is doing and since when (T-023 §3): rest, speaking, the tap reactions in rotation and the anger
/// of quick taps. The views ask for the pose of an instant: one clock for heart and bubble, always the real time
/// (never `AppClock`: with `-stepteller.debugNow` the views' clock is the real one).
@MainActor
@Observable
final class HeartMotion {
    enum Event: Equatable {
        case speak(slow: Bool)
        case tap(reaction: Int, k: Double)
    }

    private(set) var event: Event?
    private(set) var eventAt = Date.distantPast
    private(set) var taps: [Date] = []
    @ObservationIgnored private var reactions = 0
    @ObservationIgnored private var haptics: [DispatchWorkItem] = []

    /// The heart says a new line (§3.3); `slow`: the first line after the update, at half speed (§4).
    func speak(_ level: NastyLevel, slow: Bool = false, now: Date = Date()) {
        event = .speak(slow: slow)
        eventAt = now
        let d = slow ? 2.0 : 1.0
        if level == .nasty || slow {
            haptic(.rigid, at: 0.21 * d)
            haptic(.rigid, at: 0.35 * d)
        } else {
            haptic(.soft, at: 0)
        }
    }

    /// A tap (§3.4): the next reaction of the level, angrier with quick taps.
    func tap(_ level: NastyLevel, now: Date = Date()) {
        taps = NastyRage.recent(taps, now: now) + [now]
        let k = NastyRage.k(taps: taps.count)
        let count = level == .nasty ? 4 : 3
        let reaction = reactions % count
        reactions += 1
        event = .tap(reaction: reaction, k: k)
        eventAt = now
        if level == .nasty {
            haptic(.heavy, at: 0)
            if reaction == 1 { haptic(.rigid, at: 0.28) }     // the horn hits
        } else {
            haptic(k >= 1.7 ? .heavy : .medium, at: 0)
        }
    }

    /// Taps of the last 4 s at `now`.
    func angry(_ now: Date) -> Bool { NastyRage.angry(taps: NastyRage.recent(taps, now: now).count) }

    /// Something is moving at `now` besides the rest (the views keep the clock running).
    func busy(_ now: Date) -> Bool { now.timeIntervalSince(eventAt) < 1.6 || angry(now) }

    /// For the views' clocks: true now, false once the event and the anger are over (re-run at every event).
    static func busyWhile(_ motion: HeartMotion) async -> Bool {
        guard motion.event != nil else { return false }
        while motion.busy(Date()) {
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled { return true }
        }
        return false
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle, at delay: Double) {
        let item = DispatchWorkItem { UIImpactFeedbackGenerator(style: style).impactOccurred() }
        haptics.append(item)
        haptics = haptics.filter { !$0.isCancelled }.suffix(8)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    // MARK: durations

    static func duration(_ event: Event, level: NastyLevel) -> Double {
        switch event {
        case let .speak(slow): slow ? 1.4 : 0.7
        case let .tap(reaction, _):
            level == .nasty ? [0.65, 0.7, 0.8, 0.7][reaction % 4] : [0.6, 0.6, 0.7][reaction % 3]
        }
    }

    // MARK: pose of the heart

    func pose(_ level: NastyLevel, at now: Date, rest: Bool, reduceMotion: Bool) -> HeartPose {
        var p = HeartPose()
        let elapsed = now.timeIntervalSince(eventAt)
        if reduceMotion {
            // §3.5: only a blink at a tap, nothing else moves
            if case .tap = event, elapsed < 0.2 { p.opacity = 0.55 + 0.45 * Curve.easeOut(elapsed / 0.2) }
            return p
        }
        let angry = self.angry(now)
        if rest { Self.rest(&p, level, t: now.timeIntervalSinceReferenceDate, angry: angry) }
        guard let event else { return p }
        let d = Self.duration(event, level: level)
        guard elapsed >= 0, elapsed < d else { return p }
        let q = elapsed / d
        switch event {
        case .speak: Self.speak(&p, level, q)
        case let .tap(reaction, k): Self.tap(&p, level, reaction: reaction, k: k, q)
        }
        return p
    }

    /// §3.2: heartbeat, breathing spikes, cracks lighting up with every beat; angry: faster, cracks always on.
    private static func rest(_ p: inout HeartPose, _ level: NastyLevel, t: Double, angry: Bool) {
        if level == .piccante {
            let period = angry ? 0.9 : 1.2
            let beat = Track(.easeInOut, [(0, 1), (0.1, 1.07), (0.2, 1), (0.3, 1.04), (0.42, 1), (1, 1)])
                .at(t.truncatingRemainder(dividingBy: period) / period)
            p.scaleX = beat; p.scaleY = beat
            let b = t.truncatingRemainder(dividingBy: 2.4) / 2.4
            p.spikesScale = Track(.easeInOut, [(0, 1), (0.5, 1.06), (1, 1)]).at(b)
            p.spikesRotation = Track(.easeInOut, [(0, 0), (0.5, 3), (1, 0)]).at(b)
        } else {
            let period = angry ? 0.6 : 0.85
            let q = t.truncatingRemainder(dividingBy: period) / period
            let beat = Track(.linear, [(0, 1), (0.08, 1.09), (0.15, 0.99), (0.23, 1.06), (0.33, 1), (1, 1)]).at(q)
            p.scaleX = beat; p.scaleY = beat
            p.x = Track(.linear, [(0, 0), (0.08, -1.5), (0.15, 1.5), (0.23, -1), (0.33, 0), (1, 0)]).at(q)
            if angry {
                let f = t.truncatingRemainder(dividingBy: 0.6) / 0.6
                p.glow = Track(.easeInOut, [(0, 0.7), (0.5, 1.1), (1, 0.7)]).at(f)
                p.glowRadius = Track(.easeInOut, [(0, 6), (0.5, 10), (1, 6)]).at(f)
            } else {
                p.glow = Track(.linear, [(0, 0), (0.08, 0.9), (0.2, 0.1), (0.23, 0.6), (0.4, 0), (1, 0)]).at(q)
                p.glowRadius = Track(.linear, [(0, 0), (0.08, 7), (0.2, 1), (0.23, 5), (0.4, 0), (1, 0)]).at(q)
            }
        }
    }

    /// §3.3: the heart loads up and shoots the bubble.
    private static func speak(_ p: inout HeartPose, _ level: NastyLevel, _ q: Double) {
        if level == .piccante {
            p.scaleX *= Track(.easeOut, [(0, 1), (0.15, 0.9), (0.35, 1.18), (0.5, 0.95), (0.7, 1.03), (1, 1)]).at(q)
            p.scaleY *= Track(.easeOut, [(0, 1), (0.15, 1.08), (0.35, 1.18), (0.5, 0.95), (0.7, 1.03), (1, 1)]).at(q)
            p.y += Track(.easeOut, [(0, 0), (0.35, 0), (0.5, 4), (0.7, 0), (1, 0)]).at(q)
            p.spikesScale = Track(.easeOut, [(0, 1), (0.3, 1.22), (0.55, 1.05), (1, 1)]).at(q)
            p.spikesRotation = Track(.easeOut, [(0, 0), (0.3, -4), (0.55, 0), (1, 0)]).at(q)
        } else {
            let times = [0, 0.15, 0.3, 0.36, 0.42, 0.48, 0.54, 0.62, 0.72, 1]
            let sx = [1, 0.88, 1.2, 1.18, 1.15, 1.12, 1.08, 1.04, 0.97, 1]
            let sy = [1, 1.1, 1.2, 1.18, 1.15, 1.12, 1.08, 1.04, 0.97, 1]
            let rot = [0, 0, -3, 3, -3, 3, -2, 2, 0, 0.0]
            let x = [0, 0, 0, 2, -2, 0, 2, 0, 0, 0.0]
            func track(_ v: [Double]) -> Double { Track(.easeOut, Array(zip(times, v))).at(q) }
            p.scaleX *= track(sx); p.scaleY *= track(sy); p.rotation += track(rot); p.x += track(x)
            let shards = [(0, 1.0, 0.0, 1.0), (0.3, 1.05, 0, 1), (0.7, 1.7, 25, 0), (0.71, 0.6, 0, 0), (1, 1, 0, 1)]
            p.shardsScale = Track(.easeOut, shards.map { ($0.0, $0.1) }).at(q)
            p.shardsRotation = Track(.easeOut, shards.map { ($0.0, $0.2) }).at(q)
            p.shardsOpacity = Track(.easeOut, shards.map { ($0.0, $0.3) }).at(q)
            flash(&p, q)
        }
    }

    /// Cracks: one flash (speaking, the split).
    private static func flash(_ p: inout HeartPose, _ q: Double) {
        p.glow = Track(.easeOut, [(0, 0), (0.3, 1.2), (0.7, 0.8), (1, 0)]).at(q)
        p.glowRadius = Track(.easeOut, [(0, 0), (0.3, 10), (0.7, 6), (1, 0)]).at(q)
    }

    /// §3.4: the reactions, `k` the anger.
    private static func tap(_ p: inout HeartPose, _ level: NastyLevel, reaction: Int, k: Double, _ q: Double) {
        if level == .piccante {
            switch reaction % 3 {
            case 0:     // hedgehog
                p.spikesScale = Track(.bezier(0.2, 1.6, 0.4, 1), [(0, 1), (0.12, 1 + 0.3 * k), (0.4, 1 + 0.27 * k), (1, 1)]).at(q)
                p.bodyScale = Track(.easeOut, [(0, 1), (0.12, 0.9), (0.4, 0.92), (1, 1)]).at(q)
            case 1:     // dodges
                let c = Curve.bezier(0.3, 1.4, 0.5, 1)
                p.x += Track(c, [(0, 0), (0.18, 30 * k), (0.5, 28 * k), (0.8, -3), (1, 0)]).at(q)
                p.rotation += Track(c, [(0, 0), (0.18, 12 * k), (0.5, 10 * k), (0.8, -2), (1, 0)]).at(q)
            default:    // puffs
                let s = Track(.easeOut, [(0, 1), (0.3, 1 + 0.12 * k), (0.45, 0.94), (0.7, 1.02), (1, 1)]).at(q)
                p.scaleX *= s; p.scaleY *= s
                p.puffs = q
            }
        } else {
            switch reaction % 4 {
            case 0:     // splits and mends
                let c = Curve.bezier(0.3, 1.5, 0.5, 1)
                func t(_ v: [Double]) -> Double { Track(c, Array(zip([0, 0.15, 0.45, 0.7, 1], v))).at(q) }
                p.split = ((t([0, -8 * k, -7 * k, 1, 0]), t([0, 3, 3, 0, 0]), t([0, -6 * k, -5 * k, 1, 0])),
                           (t([0, 8 * k, 7 * k, -1, 0]), t([0, -1, -1, 0, 0]), t([0, 6 * k, 5 * k, -1, 0])))
                flash(&p, q)
            case 1:     // horn
                let c = Curve.bezier(0.4, 0, 0.2, 1)
                let times = [0, 0.25, 0.4, 0.48, 0.56, 1]
                func t(_ v: [Double]) -> Double { Track(c, Array(zip(times, v))).at(q) }
                p.rotation += t([0, -14 * k, 18 * k, 14 * k, 18 * k, 0])
                p.x += t([0, -6, 14 * k, 12 * k, 14 * k, 0])
                p.y += t([0, 4, -10, -8, -10, 0])
            case 2:     // turns its back
                let c = Curve.bezier(0.2, 0.8, 0.3, 1)
                let times = [0, 0.12, 0.3, 0.4, 0.5, 0.75, 0.88, 1]
                func t(_ v: [Double]) -> Double { Track(c, Array(zip(times, v))).at(q) }
                p.scaleX *= t([1, -1, -1, -1, -1, -1, 1.05, 1])
                p.rotation += t([0, -6, -4, -7, -4, -5, 0, 0])
                p.x += t([0, 8, 10, 9, 10, 9, 0, 0])
            default:    // cracks flash three times
                p.glow = Track(.linear, [(0, 0), (0.1, 1.4), (0.25, 0), (0.4, 1.4), (0.55, 0), (0.7, 1.4), (0.85, 0), (1, 0)]).at(q)
                p.glowRadius = Track(.linear, [(0, 0), (0.1, 12), (0.25, 0), (0.4, 12), (0.55, 0), (0.7, 12), (0.85, 0), (1, 0)]).at(q)
                let s = Track(.easeOut, [(0, 1), (0.1, 1.06), (0.2, 0.98), (1, 1)]).at(q)
                p.scaleX *= s; p.scaleY *= s
            }
        }
    }

    // MARK: pose of the bubble

    func bubble(_ level: NastyLevel, at now: Date, reduceMotion: Bool) -> BubblePose {
        var b = BubblePose()
        guard let event else { return b }
        let elapsed = now.timeIntervalSince(eventAt)
        switch event {
        case let .speak(slow):
            let d = slow ? 1.4 : 0.7
            guard elapsed < d else { return b }
            if reduceMotion { b.opacity = min(1, max(0, elapsed / 0.2)); return b }
            let q = max(0, elapsed) / d
            let c = Curve.bezier(0.2, 0.9, 0.3, 1.2)
            b.fly = Track(c, [(0, 1), (0.32, 1), (0.55, 0), (1, 0)]).at(q)
            b.scale = Track(c, [(0, 0.2), (0.32, 0.2), (0.55, 1.08), (0.7, 0.97), (1, 1)]).at(q)
            b.opacity = q < 0.32 ? 0 : Track(c, [(0.32, 0), (0.55, 1), (1, 1)]).at(q)
            b.x = Track(c, [(0, 0), (0.32, 0), (0.55, 6), (0.7, 0), (1, 0)]).at(q)
            b.y = Track(c, [(0, 0), (0.32, 0), (0.55, -4), (0.7, 0), (1, 0)]).at(q)
        case .tap:
            // after the reaction, at 0.3 s, the new line pops in (0.25 s); «Reduce Motion»: a fade after the blink
            let t = elapsed - (reduceMotion ? 0.2 : 0.3)
            guard t < 0.25 else { return b }
            let q = max(0, t) / (reduceMotion ? 0.2 : 0.25)
            b.opacity = t < 0 ? 0 : Curve.easeOut(min(1, q))
            if !reduceMotion { b.scale = 0.6 + 0.4 * Curve.easeOut(min(1, q)) }
        }
        return b
    }
}
