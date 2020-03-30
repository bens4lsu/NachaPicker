//
//  PickerContext.swift
//  App
//
//  Created by Ben Schultz on 3/27/20.
//

import Foundation

struct PickerLine: Encodable {
    var uuid: UUID
    var aba: String?
    var accountNumber: String?
    var amount: String?
    var idNumber: String?
    var name: String?
    
    init (record: NachaType6) {
        self.uuid = record.uuid
        self.aba = record.aba
        self.accountNumber = record.accountNumber
        if let printAmt = record.amount {
            self.amount = String(format: "%.2f", printAmt)
        }
        self.idNumber = record.idNumber
        self.name = record.name
    }
}

struct PickerContext: Encodable {
    var uuid: String
    var lines: [PickerLine]
    
    init(uuid: UUID, lines: [PickerLine]) {
        self.uuid = uuid.description
        self.lines = lines
    }
}
