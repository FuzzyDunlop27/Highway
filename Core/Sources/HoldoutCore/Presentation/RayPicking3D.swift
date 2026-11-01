// Purpose: Pure math for 3D touches: a ray from the finger, which building box it hits first, what hides the ghost. Notes: docs/features/input.md
import Foundation

/// A ray from `origin` along `direction` (not necessarily unit length; `point(at: 1)` = origin + direction).
public struct Ray3D: Equatable, Sendable {
    public typealias Point3 = WorldMapping3D.Point3
    public let origin: Point3
    public let direction: Point3

    public init(origin: Point3, direction: Point3) {
        self.origin = origin
        self.direction = direction
    }

    public func point(at t: Double) -> Point3 {
        Point3(x: origin.x + direction.x * t, y: origin.y + direction.y * t, z: origin.z + direction.z * t)
    }

    /// Where the ray reaches the ground (y = 0), or nil if it points at the sky.
    public var groundHit: (x: Double, z: Double)? {
        guard direction.y < -1e-9, origin.y >= 0 else { return nil }
        let p = point(at: -origin.y / direction.y)
        return (p.x, p.z)
    }
}

/// An upright box standing on the ground: a building's footprint (x/z, metres) up to its height (y).
public struct Box3D: Equatable, Sendable {
    public let minX, minY, minZ, maxX, maxY, maxZ: Double

    public init(minX: Double, minY: Double, minZ: Double, maxX: Double, maxY: Double, maxZ: Double) {
        (self.minX, self.minY, self.minZ, self.maxX, self.maxY, self.maxZ) = (minX, minY, minZ, maxX, maxY, maxZ)
    }

    /// The box over a `width`×`height` footprint at `origin`, `tall` metres high.
    public init(footprint origin: GridPoint, width: Int, height: Int, tall: Double, mapping: WorldMapping3D) {
        let a = mapping.world(gx: Double(origin.x), gy: Double(origin.y))
        let b = mapping.world(gx: Double(origin.x + width), gy: Double(origin.y + height))
        self.init(minX: a.x, minY: 0, minZ: a.z, maxX: b.x, maxY: max(tall, 0), maxZ: b.z)
    }

    /// The box shrunk toward its middle by `fraction` of its size on each axis (0.1 = 10% in from every side).
    public func inset(_ fraction: Double) -> Box3D {
        let dx = (maxX - minX) * fraction, dy = (maxY - minY) * fraction, dz = (maxZ - minZ) * fraction
        return Box3D(minX: minX + dx, minY: minY + dy, minZ: minZ + dz, maxX: maxX - dx, maxY: maxY - dy, maxZ: maxZ - dz)
    }

    public var corners: [WorldMapping3D.Point3] {
        [minX, maxX].flatMap { x in [minY, maxY].flatMap { y in [minZ, maxZ].map { z in .init(x: x, y: y, z: z) } } }
    }

    public var center: WorldMapping3D.Point3 { .init(x: (minX + maxX) / 2, y: (minY + maxY) / 2, z: (minZ + maxZ) / 2) }
}

public enum RayPicking3D {
    /// How far along the ray (in `direction` lengths, ≥ 0) it enters `box`, or nil if it misses (slab method).
    public static func hitDistance(_ ray: Ray3D, _ box: Box3D) -> Double? {
        var near = 0.0, far = Double.infinity
        let axes = [(ray.origin.x, ray.direction.x, box.minX, box.maxX),
                    (ray.origin.y, ray.direction.y, box.minY, box.maxY),
                    (ray.origin.z, ray.direction.z, box.minZ, box.maxZ)]
        for (o, d, lo, hi) in axes {
            if abs(d) < 1e-12 {
                if o < lo || o > hi { return nil }
                continue
            }
            let t1 = (lo - o) / d, t2 = (hi - o) / d
            near = max(near, min(t1, t2))
            far = min(far, max(t1, t2))
            if near > far { return nil }
        }
        return near
    }

    /// The box the ray hits first (the one in front on screen: a tall roof in front beats a building behind it).
    public static func nearest<ID>(_ ray: Ray3D, boxes: [(id: ID, box: Box3D)]) -> ID? {
        var best: (id: ID, t: Double)?
        for entry in boxes {
            guard let t = hitDistance(ray, entry.box), t < (best?.t ?? .infinity) else { continue }
            best = (entry.id, t)
        }
        return best?.id
    }

    /// Boxes standing between `eye` and any of `targets` (e.g. points on the placement ghost): they hide it and fade.
    public static func occluders<ID: Hashable>(eye: WorldMapping3D.Point3, targets: [WorldMapping3D.Point3],
                                               boxes: [(id: ID, box: Box3D)]) -> Set<ID> {
        var found = Set<ID>()
        for target in targets {
            let ray = Ray3D(origin: eye, direction: .init(x: target.x - eye.x, y: target.y - eye.y, z: target.z - eye.z))
            for entry in boxes where !found.contains(entry.id) {
                if let t = hitDistance(ray, entry.box), t < 1 { found.insert(entry.id) }  // t < 1: before the target
            }
        }
        return found
    }
}
