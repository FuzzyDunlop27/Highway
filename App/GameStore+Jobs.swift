// Purpose: Player actions for the job panels (upgrade, workers, training, defenders, runs, research), all sent as Core Commands. Notes: docs/features/hud-ui.md
import Foundation
import HoldoutCore

extension GameStore {
    /// Queues the next level of the selected building (cost, HQ gate and queue room are Core's call; a "no" shows as a notice).
    func upgradeSelected() {
        guard case .selected(let id) = placement.mode else { return }
        send(.upgrade(id: id))
    }

    /// Cancels the selected building's waiting or running job (a new building, an upgrade, a rebuild).
    func cancelSelectedJob() {
        guard case .selected(let id) = placement.mode else { return }
        send(.cancelJob(buildingId: id))
        if loop?.state.base.building(id) == nil { placement.select(nil) }
    }

    /// One more (+1) or one fewer (−1) worker in the selected building.
    func changeWorkers(by delta: Int) {
        guard case .selected(let id) = placement.mode, let b = loop?.state.base.building(id),
              let def = content?.buildingDef(b.defId) else { return }
        send(.setWorkers(id: id, count: min(max((b.assignedWorkers ?? def.workers) + delta, 0), def.workers)))
    }

    func trainDefender() { send(.trainDefender) }
    func cancelTraining(index: Int) { send(.cancelTraining(index: index)) }
    func garrison(_ defender: DefenderID, in tower: BuildingID) { send(.garrison(defender: defender, in: tower)) }
    func recall(_ defender: DefenderID) { send(.recallDefender(defender)) }
    func startRun(post: BuildingID, runId: String) { send(.startRun(buildingId: post, runId: runId)) }
    func collectRun(post: BuildingID) { send(.collectRun(buildingId: post)) }
    func startResearch(_ id: String) { send(.startResearch(id)) }

    /// The next tap on the map sends `defender` to hold that tile.
    func chooseSpot(for defender: DefenderID) {
        choosingSpotFor = defender
        placement.select(nil)
    }
}
