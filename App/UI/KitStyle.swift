// Purpose: The menu look from ChatGPT's UI kit (HighwayHoldout_UI_Kit): colors, panels, buttons, glyphs, chips, cards. Notes: docs/features/hud-ui.md
import SwiftUI

/// Colors from `HighwayHoldout_UI_Kit/design_tokens.json`.
enum Kit {
    static let ink = Color(red: 0x15 / 255, green: 0x36 / 255, blue: 0x3B / 255)
    static let muted = Color(red: 0x5F / 255, green: 0x77 / 255, blue: 0x75 / 255)
    static let paper = Color(red: 0xF5 / 255, green: 0xF0 / 255, blue: 0xE5 / 255)
    static let white = Color(red: 0xFF / 255, green: 0xFC / 255, blue: 0xF5 / 255)
    static let teal = Color(red: 0x2F / 255, green: 0x70 / 255, blue: 0x6C / 255)
    static let danger = Color(red: 0xA8 / 255, green: 0x4D / 255, blue: 0x43 / 255)
    static let gold = Color(red: 0xDB / 255, green: 0xAE / 255, blue: 0x63 / 255)

    /// Look-only tint of the level badge: bronze, silver, gold for levels 1, 2, 3.
    static func levelTint(_ level: Int) -> Color {
        switch level {
        case ...1: Color(red: 0.80, green: 0.55, blue: 0.35)
        case 2: Color(red: 0.78, green: 0.82, blue: 0.85)
        default: gold
        }
    }

    /// A stretchable kit image (`Art/UI/<name>`): the corners keep their shape at any size.
    static func surface(_ name: String, corner: CGFloat) -> some View {
        Image("UI/\(name)")
            .resizable(capInsets: EdgeInsets(top: corner, leading: corner, bottom: corner, trailing: corner), resizingMode: .stretch)
    }
}

/// A white line icon from the kit (`ui_glyph_<name>`), tinted to `color`.
struct KitGlyph: View {
    let name: String
    var size: CGFloat = 20
    var color: Color = Kit.ink

    var body: some View {
        Image("UI/ui_glyph_\(name)")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
    }
}

extension View {
    /// Cream kit panel behind a bar or banner.
    func kitPanel(_ name: String = "ui_panel_light") -> some View {
        background(Kit.surface(name, corner: 24))
    }
}

/// Kit buttons: primary (teal), secondary (cream), danger (red), each with normal/pressed/disabled art.
struct KitButtonStyle: ButtonStyle {
    enum Kind: String { case primary, secondary, danger }
    let kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let state = !isEnabled ? "disabled" : (configuration.isPressed ? "pressed" : "normal")
        let text: Color = !isEnabled ? Kit.muted : (kind == .secondary ? Kit.ink : Kit.white)
        configuration.label
            .font(.headline)
            .foregroundStyle(text)
            .padding(.horizontal, 14)
            .frame(minWidth: 80, minHeight: 44)
            .background(Kit.surface("ui_button_\(kind.rawValue)_\(state)", corner: 16))
    }
}

/// Square kit icon button with a glyph (view toggle, close).
struct KitIconButton: View {
    let glyph: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            KitGlyph(name: glyph, size: 22)
                .frame(width: 44, height: 44)
                .background(Kit.surface("ui_icon_button_normal", corner: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// A button label: glyph + text, colored by the button style.
struct KitLabel: View {
    let glyph: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image("UI/ui_glyph_\(glyph)").renderingMode(.template).resizable().scaledToFit().frame(width: 18, height: 18)
            Text(title).lineLimit(1)
        }
        .fixedSize()
    }
}
