// Purpose: A snapshot of build slots, queue and builders for the App's build-queue strip. Notes: docs/features/construction.md
import Foundation

public struct BuildQueueStatus: Equatable, Sendable {
    /// Jobs that can run at once at the current HQ level.
    public let slots: Int
    public let active: Int
    public let queued: Int
    public let queueLength: Int
    /// Survivors not borrowed as builders.
    public let freeBuilders: Int

    static func make(state: GameState, content: GameContent) -> BuildQueueStatus {
        BuildQueueStatus(slots: BuildQueue.slots(state.base, content: content),
                         active: BuildQueue.activeCount(state.base), queued: BuildQueue.queuedCount(state.base),
                         queueLength: content.buildings.rules.constructionQueueLength,
                         freeBuilders: BuildQueue.freeBuilders(state))
    }
}
