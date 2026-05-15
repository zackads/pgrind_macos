//
//  PgrindMigrationPlan.swift
//  pgrind
//
//  Created by Zack Adlington on 21/02/2026.
//

import Foundation
import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self,
        ]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            let webpageProblems = try context.fetch(FetchDescriptor<WebpageProblem>())
            for problem in webpageProblems {
                context.delete(problem)
            }
            try context.save()
        },
        didMigrate: nil
    )
}
