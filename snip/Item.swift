//
//  Item.swift
//  snip
//
//  Created by leto on 2026/5/12.
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
