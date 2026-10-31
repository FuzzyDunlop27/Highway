// Purpose: Small bars drawn over map things: construction progress, building health, zombie health. Notes: docs/features/rendering-art.md
import SpriteKit

@MainActor
enum BarNodeFactory {
    static let progressName = "progress"
    static let healthName = "health"
    private static let fillName = "fill"

    /// A dark track with a colored fill growing from the left; `centerY` is the bar's middle in the parent's space.
    static func make(name: String, width: CGFloat, height: CGFloat, centerY: CGFloat, color: UIColor) -> SKSpriteNode {
        let bar = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.6), size: CGSize(width: width, height: height))
        bar.name = name
        bar.position = CGPoint(x: 0, y: centerY)
        bar.zPosition = ZLayer.overlayOffset
        let fill = SKSpriteNode(color: color, size: CGSize(width: width, height: height))
        fill.name = fillName
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -width / 2, y: 0)
        fill.zPosition = 0.1
        bar.addChild(fill)
        return bar
    }

    /// Sets how full `bar` is (0...1).
    static func set(_ bar: SKNode?, value: Double) {
        guard let fill = bar?.childNode(withName: fillName) else { return }
        fill.xScale = CGFloat(max(0.001, min(1, value)))
    }

    /// Health color: green when mostly healthy, amber, then red.
    static func healthColor(_ fraction: Double) -> UIColor {
        fraction > 0.6 ? .systemGreen : (fraction > 0.3 ? .systemOrange : .systemRed)
    }
}
