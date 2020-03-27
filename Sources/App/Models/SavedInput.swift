//
//  SavedInputs.swift
//  App
//
//  Created by Ben Schultz on 3/27/20.
//

import Foundation

class SavedInput {
    var date = Date()
    var uuid = UUID()
    var nacha: NachaAll
    
    var isOutdated: Bool {
        date.addingTimeInterval(1800) < Date()
    }
    
    init(_ nacha: NachaAll) {
        self.nacha = nacha
    }
}
