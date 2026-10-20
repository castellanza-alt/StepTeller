#if DEBUG
import SwiftUI
import StepTellerCore

/// Debug builds only: shows the widgets (small, medium and lock screen) to check them in the simulator
/// screenshots. Launch arguments: `-stepteller.debugWidget 1 -stepteller.debugSteps 3465`
/// (without `debugSteps`: «data unavailable» state), theme with `-stepteller.themeMode day|night`.
struct WidgetPreviewScreen: View {
    var body: some View {
        let d = UserDefaults.standard
        let plan: Plan? = d.object(forKey: "stepteller.debugSteps") != nil
            ? Plan(goal: 10_000, steps: d.integer(forKey: "stepteller.debugSteps"), speed: SpeedTrack.defaultSpeed,
                   model: CalibrationResult.empty.model)
            : nil
        let data = WidgetSnapshot(plan: plan, streak: 14, jolly: 2)
        let palette: MangaPalette = d.string(forKey: ThemeMode.storageKey) == "night" ? .night : .day
        ZStack {
            LinearGradient(colors: palette.theme == .night ? [Color(hex: 0x1B2350), Color(hex: 0x0A0D1E)]
                                                          : [Color(hex: 0xC9D6E8), Color(hex: 0xE8D9C8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 28) {
                WidgetSmallView(data: data)
                    .frame(width: 170, height: 170)
                    .background(palette.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.22), radius: 17, y: 14)
                WidgetMediumView(data: data)
                    .frame(width: 364, height: 170)
                    .background(palette.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.22), radius: 17, y: 14)
                HStack(spacing: 14) {
                    LockCircular(plan: plan).frame(width: 72, height: 72)
                    LockRectangular(data: data).frame(width: 172, height: 72)
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.black.opacity(0.28)))
            }
            .environment(\.manga, palette)
        }
    }
}
#endif
