// Purpose: Draws labeled placeholder images for missing art: flat boxes (top-down) and 3D blocks/diamonds (isometric). Notes: docs/features/rendering-art.md
import UIKit

enum PlaceholderArt {
    /// Flat rounded box with the art id written on it (top-down and UI icons).
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

    /// Isometric block standing on a `w`×`h` footprint diamond, `height` points tall (0 = flat diamond, e.g. a ground tile).
    /// Image is the block's bounding box; its ground point (the diamond's bottom corner) is the image's bottom middle.
    static func isoBlock(_ id: String, footprintW w: Int, footprintH h: Int,
                         tileW: CGFloat, tileH: CGFloat, height: CGFloat, labeled: Bool = true) -> UIImage {
        let width = CGFloat(w + h) * tileW / 2
        let diamond = CGFloat(w + h) * tileH / 2
        let size = CGSize(width: width, height: diamond + height)
        // Footprint corners (y down, top face at y = 0): north, east, south, west.
        let n = CGPoint(x: CGFloat(h) * tileW / 2, y: 0)
        let e = CGPoint(x: width, y: CGFloat(w) * tileH / 2)
        let s = CGPoint(x: CGFloat(w) * tileW / 2, y: diamond)
        let wst = CGPoint(x: 0, y: CGFloat(h) * tileH / 2)
        func down(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x, y: p.y + height) }
        let base = color(for: id)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let outline = UIColor.black.withAlphaComponent(0.6)
            if height > 0 {
                fill([wst, s, down(s), down(wst)], base.darker(0.15), outline)   // left (south-west) face
                fill([s, e, down(e), down(s)], base.darker(0.35), outline)       // right (south-east) face
            }
            fill([n, e, s, wst], base.lighter(0.12), height > 0 ? outline : base.darker(0.25))  // top face
            if labeled {
                let top = CGRect(x: wst.x, y: n.y, width: width, height: diamond)
                drawLabel(id, in: top.insetBy(dx: width * 0.18, dy: 0), fontSize: max(7, min(width * 0.09, 13)))
            }
        }
    }

    private static func fill(_ points: [CGPoint], _ color: UIColor, _ stroke: UIColor) {
        let path = UIBezierPath()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.close()
        color.setFill()
        path.fill()
        stroke.setStroke()
        path.lineWidth = 1
        path.stroke()
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
