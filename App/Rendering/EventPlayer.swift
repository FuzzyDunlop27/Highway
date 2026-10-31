// Purpose: Turns Core's per-frame SimEvents into effects (tracers, goo, dust, shakes) and remembers where towers aim. Notes: docs/features/rendering-art.md
import SpriteKit
import HoldoutCore

@MainActor
final class EventPlayer {
    /// Goo splats (flat, on the ground).
    private let decals = SKNode()
    /// Tracers, muzzle flashes, dust puffs (over everything).
    private let air = SKNode()
    /// Last screen angle each tower fired at, so a rebuilt node keeps its aim.
    private(set) var towerAim: [BuildingID: Double] = [:]

    // Caps so a 150-zombie horde can't pile up thousands of nodes: the oldest goo goes, extra air effects are skipped.
    private static let maxDecals = 60
    private static let maxAirEffects = 80

    /// Puts the (emptied) effect layers into a freshly built world.
    func reset(in world: SKNode) {
        for layer in [decals, air] {
            layer.removeAllChildren()
            layer.removeFromParent()
            world.addChild(layer)
        }
    }

    func play(_ events: [SimEvent], loop: GameLoop, style: ArtStyle, art: ArtRegistry,
              buildings: [BuildingID: SKNode], zombies: ZombieLayer) {
        guard !events.isEmpty else { return }
        let geometry = style.geometry
        // Where each zombie stands (grid), including ones that died this frame (shots can target them).
        var spots: [ZombieID: (x: Double, y: Double)] = [:]
        for z in loop.state.base.zombies { spots[z.id] = (z.x, z.y) }
        for case let .zombieDied(id, _, x, y) in events { spots[id] = (x, y) }

        for event in events {
            switch event {
            case .shot(let from, let target):
                guard let towerNode = buildings[from], let tower = loop.state.base.building(from),
                      let def = loop.content.buildingDef(tower.defId), let spot = spots[target] else { continue }
                let center = geometry.center(origin: tower.origin, width: def.width, height: def.height)
                let ground = geometry.point(gx: spot.x, gy: spot.y)
                let angle = atan2(Double(ground.y - center.y), Double(ground.x - center.x))
                towerAim[from] = angle
                if let turret = def.turretSprite {
                    DefenseNodeFactory.aimTurret(towerNode, turretId: turret, def: def, screenAngle: angle, style: style, art: art)
                }
                let muzzle = DefenseNodeFactory.muzzlePoint(towerNode, style: style)
                let hit = zombies.nodes[target]?.hitPoint ?? geometry.standingAnchor(gx: spot.x, gy: spot.y)
                addAir(FXNodeFactory.tracer(from: muzzle, to: hit, style: style, art: art))
                addAir(FXNodeFactory.muzzleFlash(at: muzzle, angle: atan2(hit.y - muzzle.y, hit.x - muzzle.x), style: style, art: art))
                zombies.nodes[target]?.flash()
            case .trapHit(let trap, let target):
                zombies.nodes[target]?.flash()
                if let trapNode = buildings[trap] { FXNodeFactory.trapFlash(trapNode) }
            case .zombieDied(_, _, let x, let y):
                if decals.children.count >= Self.maxDecals { decals.children.first?.removeFromParent() }
                decals.addChild(FXNodeFactory.gooSplat(at: geometry.point(gx: x, gy: y), style: style, art: art))
            case .buildingDamaged(let id):
                if let node = buildings[id] { FXNodeFactory.shake(node) }
            case .buildingDestroyed(let id):
                guard let b = loop.state.base.building(id), let def = loop.content.buildingDef(b.defId) else { continue }
                addAir(FXNodeFactory.dustPuff(at: geometry.center(origin: b.origin, width: def.width, height: def.height),
                                              width: geometry.footprintWidth(width: def.width, height: def.height) * 1.2,
                                              style: style, art: art))
            default:
                break   // horde start/end/warning are banners and HUD (GameStore); spawns need no effect
            }
        }
        if towerAim.count > buildings.count { towerAim = towerAim.filter { buildings[$0.key] != nil } }
    }

    private func addAir(_ node: SKNode) {
        guard air.children.count < Self.maxAirEffects else { return }
        air.addChild(node)
    }
}
