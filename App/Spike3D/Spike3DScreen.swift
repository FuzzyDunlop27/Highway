// Purpose: DEBUG 1R spike screen: 3D scene + touches + fps readout + scene/walker/shadow/host/cap toggles. Notes: docs/plans/3d-spike-1R-results.md
#if DEBUG
import SwiftUI

struct Spike3DScreen: View {
    enum Host: String, CaseIterable { case reality = "RealityView", ar = "ARView" }

    let close: () -> Void
    @State private var host: Host
    @State private var walkers: Int
    @State private var shadows: Bool
    @State private var compact: Bool
    @State private var capped: Bool
    @State private var scene: Spike3DScene
    @State private var stats = Spike3DStats()
    @State private var world: Spike3DWorld?
    private let config = Spike3DConfig.shared

    /// Launch arguments let the spike be measured without touches, e.g. `-spike3DWalkers 100 -spike3DHost ar -spike3DCap 1 -spike3DScene free`.
    init(close: @escaping () -> Void) {
        self.close = close
        let d = UserDefaults.standard
        let wanted = d.string(forKey: "spike3DHost").flatMap { $0 == "ar" ? Host.ar : Host.reality } ?? .reality
        if #available(iOS 18.0, *) { _host = State(initialValue: wanted) } else { _host = State(initialValue: .ar) }
        _walkers = State(initialValue: d.integer(forKey: "spike3DWalkers"))
        _capped = State(initialValue: d.bool(forKey: "spike3DCap"))
        _shadows = State(initialValue: d.object(forKey: "spike3DShadows") == nil || d.bool(forKey: "spike3DShadows"))
        _compact = State(initialValue: d.bool(forKey: "spike3DCompact"))
        _scene = State(initialValue: d.string(forKey: "spike3DScene") == "free" ? .freeAssets : .study)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.42, green: 0.36, blue: 0.30).ignoresSafeArea()
            if let world {
                scene(world).ignoresSafeArea()
                Spike3DGestureLayer(world: world).ignoresSafeArea()
            }
            controls
        }
        .onAppear { rebuild() }
        .onChange(of: host) { rebuild() }
        .onChange(of: scene) { rebuild() }
        .onChange(of: walkers) { world?.setWalkers(walkers) }
        .onChange(of: shadows) { world?.setShadows(shadows) }
    }

    @ViewBuilder private func scene(_ world: Spike3DWorld) -> some View {
        if #available(iOS 18.0, *), host == .reality {
            Spike3DRealityHost(world: world).id(ObjectIdentifier(world))
        } else {
            Spike3DARHost(world: world, capTo: capped ? config.cappedFrameRate : nil).id(ObjectIdentifier(world))
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("Close", action: close).buttonStyle(.borderedProminent)
                Text(String(format: "%.1f fps · worst %.0f ms · %d walkers · shadows %@ · %@", stats.fps, stats.worstFrameMs,
                            stats.walkers, shadows ? "on" : "off", host.rawValue))
                    .font(.subheadline.monospacedDigit().bold())
                    .accessibilityIdentifier("spike3d_fps")
                Button(compact ? "More" : "Less") { compact.toggle() }.buttonStyle(.bordered)
            }
            if !compact { details }
        }
        .controlSize(.mini)
        .font(.caption)
        .foregroundStyle(.white)
        .padding(8)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
        .padding()
    }

    @ViewBuilder private var details: some View {
        Text("\(host.rawValue) · iOS \(UIDevice.current.systemVersion) · \(stats.loadNote)").font(.caption2)
        Picker("Scene", selection: $scene) {
            ForEach(Spike3DScene.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.segmented).frame(width: 240)
        Picker("Walkers", selection: $walkers) {
            ForEach(config.walkers.counts, id: \.self) { Text("\($0) walkers").tag($0) }
        }.pickerStyle(.segmented).frame(width: 240)
        HStack {
            Toggle("Shadows", isOn: $shadows).frame(width: 120)
            if host == .ar { Toggle("Cap \(Int(config.cappedFrameRate)) fps", isOn: $capped).frame(width: 120) }
        }
        if #available(iOS 18.0, *) {
            Picker("Host", selection: $host) {
                ForEach(Host.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).frame(width: 240)
        }
    }

    private func rebuild() {
        let fresh = Spike3DWorld(stats: stats, scene: scene)
        let d = UserDefaults.standard  // optional fixed camera for repeatable screenshots
        if d.float(forKey: "spike3DDistance") > 0 { fresh.orbit.distance = d.float(forKey: "spike3DDistance") }
        if d.float(forKey: "spike3DPitch") > 0 { fresh.orbit.pitch = d.float(forKey: "spike3DPitch") * .pi / 180 }
        if d.object(forKey: "spike3DYaw") != nil { fresh.orbit.yaw = d.float(forKey: "spike3DYaw") * .pi / 180 }
        fresh.applyCamera()
        fresh.loadModels()
        fresh.setShadows(shadows)
        fresh.setWalkers(walkers)
        world = fresh
    }
}
#endif
