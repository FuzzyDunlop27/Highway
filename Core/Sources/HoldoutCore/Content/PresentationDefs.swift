// Purpose: Codable shape for Content/presentation.json (3D view: camera, light, placeholder sizes). Read by the App only. Notes: docs/features/rendering-art.md
import Foundation

/// How the App draws the map (real 3D with RealityKit, D-027/D-030). Core never uses this; it is decoded here so
/// content tests cover the file.
public struct PresentationContent: Codable, Sendable {
    public let schemaVersion: Int
    /// Hex color drawn around and beyond the map.
    public let outsideMapColor: String
    /// The 3D view's settings.
    public let reality3d: Reality3DDef
}

/// Settings for the RealityKit 3D view. 1 tile = `metresPerTile` metres; +X = east, +Z = south (WorldMapping3D).
public struct Reality3DDef: Codable, Sendable {
    public let metresPerTile: Double
    /// Load `<artId>.usdz` models from the app bundle in the background (false = always draw labeled boxes).
    public let loadModels: Bool
    /// Placeholder box height per building category, in tiles (box = footprint × this).
    public let placeholderHeightTiles: [String: Double]
    /// Zombie placeholder box: width (and depth) and height, in tiles.
    public let zombieBoxTiles: ZombieBox3D
    /// Animated zombies/defenders (chunk 3M): gliding, turning, walk speed, look variants.
    public let characters: Characters3DDef
    public let camera: Camera3DDef
    public let light: Light3DDef
}

public struct ZombieBox3D: Codable, Sendable {
    public let width: Double
    public let height: Double
}

/// How 3D characters move between Core ticks and play their clips (CharacterMotion3D). Look only.
public struct Characters3DDef: Codable, Sendable {
    public let turnRadiansPerSecond: Double
    /// Each Core step is glided over the time the last step took, kept within these bounds.
    public let minGlideSeconds: Double
    public let maxGlideSeconds: Double
    /// A move longer than this (tiles) is drawn as a jump (spawn, reload).
    public let snapDistanceTiles: Double
    /// Slower than this (tiles/s) for longer than standGraceSeconds = standing.
    public let standSpeedTiles: Double
    public let standGraceSeconds: Double
    public let speedSmoothingSeconds: Double
    /// Walk-cycle speed cap (× as authored), so a runner using the walker's shamble doesn't blur.
    public let maxWalkRate: Double
    /// Cross-fade between walk, attack and idle.
    public let clipBlendSeconds: Double
    /// Art id → drawn with another model, scaled and tinted, until it gets its own model.
    public let variants: [String: CharacterVariant3D]
}

public struct CharacterVariant3D: Codable, Sendable {
    /// Art id of the model file to use (`<model>.usdz`).
    public let model: String
    public let scale: Double
    /// Hex color multiplied into the model's textures.
    public let tint: String
}

/// Orbit camera (D-029): turns in `snapAngles` steps, eased; pan, pinch zoom toward the fingers and limited tilt.
public struct Camera3DDef: Codable, Sendable {
    /// Vertical field of view.
    public let fieldOfViewDegrees: Double
    /// Distance from the camera to the ground point it looks at, in metres.
    public let startDistance: Double
    public let minDistance: Double
    public let maxDistance: Double
    /// The camera never goes lower than this above the ground (metres), so it can't enter roofs.
    public let minHeightMetres: Double
    /// Pitch = angle above the ground (90 = straight down).
    public let startPitchDegrees: Double
    public let minPitchDegrees: Double
    public let maxPitchDegrees: Double
    /// Tilt change per screen point of a two-finger up/down drag.
    public let tiltDegreesPerPoint: Double
    /// Opening angle around the map; the snap angles are this plus multiples of 360 / snapAngles.
    public let startYawDegrees: Double
    public let snapAngles: Int
    /// How far two fingers must twist before the camera turns one step (one step per twist).
    public let twistThresholdDegrees: Double
    /// Seconds for the eased turn to the next angle.
    public let snapTurnSeconds: Double
    /// Pinch strength: 1 = zoom exactly with the fingers, smaller = calmer.
    public let pinchSensitivity: Double
    /// How far past the map edge (tiles) the looked-at point may go.
    public let panMarginTiles: Double
}

/// One warm sun with shadows plus a weak fill light (values from the 1R spike).
public struct Light3DDef: Codable, Sendable {
    public let sunElevationDegrees: Double
    public let sunAzimuthDegrees: Double
    public let sunIntensityLux: Double
    public let sunColor: String
    public let fillIntensityLux: Double
    public let fillColor: String
    public let shadows: Bool
    public let shadowMaxDistance: Double
    public let shadowDepthBias: Double
}
