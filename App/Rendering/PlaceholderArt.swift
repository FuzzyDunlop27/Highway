// Purpose: Labeled placeholder pictures for missing menu art, and the per-category placeholder colors (also used by 3D boxes). Notes: docs/features/rendering-art.md
import UIKit

enum PlaceholderArt {
    /// Flat rounded box with the art id written on it (menu and HUD icons).
    static func flatBox(_ id: String, size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: min(size.width, size.height) * 0.08)
            color(for: id).setFill()
            path.fill()
            UIColor.black.withAlphaComponent(0.7).setStroke()
            path.lineWidth = 2
            path.stroke()
            drawLabel(id, in: rect, fontSize: max(9, min(size.width, size.height) * 0.14))
        }
    }

    private static func drawLabel(_ text: String, in rect: CGRect, fontSize: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byCharWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize), .foregroundColor: UIColor.white,
            .paragraphStyle: style, .strokeColor: UIColor.black, .strokeWidth: -3,
        ]
        let label = NSAttributedString(string: text, attributes: attrs)
        let box = label.boundingRect(with: CGSize(width: rect.width - 6, height: rect.height),
                                     options: .usesLineFragmentOrigin, context: nil)
        label.draw(with: CGRect(x: rect.minX + 3, y: rect.midY - box.height / 2, width: rect.width - 6, height: box.height),
                   options: .usesLineFragmentOrigin, context: nil)
    }

    /// One color per art category (id prefix from docs/graphics-spec-phase1.md), so missing art is easy to spot.
    static func color(for id: String) -> UIColor {
        let byPrefix: [(String, UIColor)] = [
            ("tile_grass", UIColor(red: 0.42, green: 0.48, blue: 0.29, alpha: 1)), ("tile_dirt", UIColor(red: 0.54, green: 0.44, blue: 0.31, alpha: 1)),
            ("tile_asphalt", UIColor(red: 0.29, green: 0.30, blue: 0.32, alpha: 1)), ("tile_concrete", UIColor(red: 0.60, green: 0.60, blue: 0.56, alpha: 1)),
            ("tile_", .gray), ("dec_", .brown), ("bld_", .systemBlue), ("def_", .systemOrange),
            ("unit_", .systemTeal), ("zmb_", .systemGreen), ("fx_", .systemYellow), ("icon_", .systemPurple), ("ui_", .systemPurple),
        ]
        return byPrefix.first { id.hasPrefix($0.0) }?.1 ?? .systemPink
    }
}

extension UIColor {
    func darker(_ amount: CGFloat) -> UIColor { adjusted(by: 1 - amount) }
    func lighter(_ amount: CGFloat) -> UIColor { adjusted(by: 1 + amount) }

    private func adjusted(by factor: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r * factor, 1), green: min(g * factor, 1), blue: min(b * factor, 1), alpha: a)
    }
}
