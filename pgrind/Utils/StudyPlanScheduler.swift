//
//  StudyPlanScheduler.swift
//  pgrind
//

import Foundation
import SwiftData

/// Periodically checks each `StudyPlan` and, when its schedule's next fire time has elapsed
/// since the last run, triggers it (populating the user's Inbox).
///
/// macOS apps don't get reliable background execution, so this only fires while the app is
/// open. On launch it also runs any plan whose scheduled time elapsed while the app was closed.
@MainActor
final class StudyPlanScheduler {
    private let modelContext: ModelContext
    private var timer: Timer?
    private let tickInterval: TimeInterval = 30

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func start() {
        tick()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick(now: Date = .now) {
        let descriptor = FetchDescriptor<StudyPlan>()
        guard let plans = try? modelContext.fetch(descriptor) else { return }

        var didRunAny = false
        for plan in plans {
            if plan.isPaused { continue }
            let referenceDate = plan.lastRunDate ?? plan.createdDate
            guard let nextFire = plan.schedule.nextFireDate(after: referenceDate),
                  nextFire <= now
            else { continue }
            plan.run(now: now)
            didRunAny = true
        }

        if didRunAny {
            try? modelContext.save()
        }
    }
}
