//
//  PgrindMigrationPlan.swift
//  pgrind
//
//  Created by Zack Adlington on 21/02/2026.
//

import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {[
        SchemaV1.self, SchemaV2.self
    ]}
    
    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: SchemaV1.self,
                toVersion: SchemaV2.self
            )
        ]
    }
}
