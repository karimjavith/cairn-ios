//
//  Item.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
