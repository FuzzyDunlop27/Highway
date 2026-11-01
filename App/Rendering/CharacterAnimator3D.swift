// Purpose: Plays a character model's walk/attack/idle clip (cut from its one USDZ timeline) at the right speed. Notes: docs/features/characters-3d.md
import RealityKit
import HoldoutCore

/// One per drawn character. Watches the container ModelRegistry handed out: once the real model has replaced the box,
/// it starts the wanted clip, cross-fades when the clip changes, and sets the playback speed every frame.
/// A clip the model doesn't have falls back: attack → idle → walk held still. Boxes are left alone.
@MainActor
struct CharacterAnimator3D {
    private weak var model: Entity?
    private var clip: CharacterClip3D?
    private var controller: AnimationPlaybackController?

    /// `rate` = playback speed (1 = as authored, 0 = frozen). `phase` (0–1) = where in the loop the first clip starts,
    /// so a pack doesn't step in lockstep.
    mutating func update(_ container: Entity, artId: String, clip wanted: CharacterClip3D, rate: Double, phase: Double = 0,
                         blendSeconds: Double, registry: ModelRegistry) {
        guard let current = container.children.first(where: { $0.name == ModelRegistry.modelName }) else { return }
        var clip = wanted
        var speed = rate
        if registry.clip(artId, clip) == nil, clip == .attack { clip = .idle }
        if registry.clip(artId, clip) == nil, clip == .idle { clip = .walk; speed = 0 }
        if current !== model || clip != self.clip {
            guard let resource = registry.clip(artId, clip) else { return }  // no clips at all: a still model
            let first = model == nil
            controller = current.playAnimation(resource, transitionDuration: first ? 0 : blendSeconds, startsPaused: false)
            if first, let seconds = registry.clipSeconds(artId, clip) { controller?.time = phase * seconds }
            model = current
            self.clip = clip
        }
        controller?.speed = Float(speed)
    }
}

extension ModelRegistry {
    /// The walk stride (tiles) of art `id`'s model at the size it is drawn, from its `.anim.json`.
    func strideTiles(_ id: String) -> Double? {
        guard let info = animInfo(id), let stride = info.file.strideTiles else { return nil }
        return stride * info.scale
    }

    /// Seconds one loop of `clip` lasts as authored.
    func clipSeconds(_ id: String, _ clip: CharacterClip3D) -> Double? {
        animInfo(id)?.file.range(clip).map { $0.upperBound - $0.lowerBound }
    }
}
