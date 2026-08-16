//
//  CairnSchema.swift
//  Cairn
//
//  Created by Codex on 16/08/2026.
//

import SwiftData

enum CairnSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            CairnSchemaV1.AccountRecord.self,
            CairnSchemaV1.BudgetRecord.self,
            CairnSchemaV1.CategoryRecord.self,
            CairnSchemaV1.GoalRecord.self,
            CairnSchemaV1.RecurringTransactionRecord.self,
            CairnSchemaV1.TransactionRecord.self
        ]
    }
}

enum CairnSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            CairnSchemaV1.self
        ]
    }

    static var stages: [MigrationStage] {
        []
    }
}
