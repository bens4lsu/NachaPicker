//
//  NachaParser.swift
//  App
//
//  Created by Ben Schultz on 3/23/20.
//

import Foundation
import Vapor

class NachaDetails: Codable {
    var type6: NachaType6
    var type7s = [NachaType7]()
    
    var lineCount: Int {
        return 1 + type7s.count
    }
    
    init(_ type6: NachaType6) {
        self.type6 = type6
    }
    
    func out() -> String {
        var outString = type6.text + "\n"
        for type7 in type7s {
            outString += type7.text + "\n"
        }
        return outString
    }
}

class NachaGroup: Codable {
    var type5: NachaType5
    var details = [NachaDetails]()
    var type8: NachaType8?
    
    var lineCount: Int {
        var count = 2
        for detail in details {
            count += detail.lineCount
        }
        return count
    }
    
    init(_ type5: NachaType5) {
        self.type5 = type5
    }
    
    func out() -> String {
        guard let type8 = self.type8 else {
            return ""
        }
        var outString = type5.text + "\n"
        for detail in details {
            outString += detail.out()
        }
        outString += type8.text + "\n"
        return outString
    }
    
    func updateValues() {
        let count = FixedLengthField(lineCount - 2, size: 6)
        
        var hash = 0
        var debitTotal = 0.0
        var creditTotal = 0.0
        for detail in details {
            if let t6hash = detail.type6.hash {
                hash += t6hash
            }
            if let t6amount = detail.type6.amount {
                if detail.type6.isDebit {
                    debitTotal += t6amount
                }
                else {
                    creditTotal += t6amount
                }
            }
            for type7 in detail.type7s {
                if let t7hash = type7.hash {
                    hash += t7hash
                }
            }
        }
        
        if let type8 = self.type8 {
            let _ = type8.fill(from: 4, to: 9, with: count)
            let _ = type8.fill(from: 10, to: 19, with: FixedLengthField(hash, size: 10))
            let _ = type8.fill(from: 20, to: 31, with: FixedLengthField(debitTotal, size: 12))
            let _ = type8.fill(from: 32, to: 43, with: FixedLengthField(creditTotal, size: 12))
            
        }
    }
}

class NachaFile: Codable {
    var type1: NachaType1
    var groups = [NachaGroup]()
    var type9: NachaType9?
    
    var lineCount: Int {
        var count = 2
        for group in groups {
            count += group.lineCount
        }
        return count
    }
    
    init (_ type1: NachaType1) {
        self.type1 = type1
    }
    
    func padding() -> [NachaFilePadding] {
        let linesNeeded = lineCount % 10 == 0 ? 0 : 10 - (lineCount % 10)
        
        var padding = [NachaFilePadding]()
        if linesNeeded > 0 {
            for _ in 1...linesNeeded {
                padding.append(try! NachaFilePadding())
            }
        }
        return padding
    }
    
    func out() -> String {
        guard let type9 = self.type9 else {
            return ""
        }
        
        var outString = type1.text + "\n"
        for group in groups {
            outString += group.out()
        }
        outString += type9.text + "\n"
        for padLine in padding() {
            outString += padLine.text + "\n"
        }
       
        return outString
    }
    
    
    func updateValues() {
        // type 1
//        if let modifier: String = type1.val(from: 33, to: 33) {
//            let char = Character(modifier)
//            if let ascii = char.asciiValue {
//                type1.fill(from: 33, to: 33, with: Character(ascii + 1))
//            }
//        }
        for group in groups {
            group.updateValues()
        }
        
        let groupCount = groups.count
        let blockCount = lineCount % 10 == 0 ? lineCount / 10 : (lineCount / 10) + 1
        
        var aeCount = 0
        var hash = 0
        var debitAmount = 0.0
        var creditAmount = 0.0
        
        
        for group in groups {
            if let type8 = group.type8 {
                aeCount += type8.aeCount ?? 0
                hash += type8.hash ?? 0
                debitAmount += type8.debitAmount ?? 0.0
                creditAmount += type8.creditAmount ?? 0.0
            }
        }
        
        if let type9 = self.type9 {
            let _ = type9.fill(from: 1, to: 7, with: FixedLengthField(groupCount, size: 6))
            let _ = type9.fill(from: 7, to: 12, with: FixedLengthField(blockCount, size: 6))
            let _ = type9.fill(from: 13, to: 20, with: FixedLengthField(aeCount, size: 8))
            let _ = type9.fill(from: 21, to: 30, with: FixedLengthField(hash, size: 10))
            let _ = type9.fill(from: 31, to: 42, with: FixedLengthField(debitAmount, size: 12))
            let _ = type9.fill(from: 43, to: 54, with: FixedLengthField(creditAmount, size: 12))
        }
    }
    
    
    
}

class NachaAll: Codable {
    var files = [NachaFile]()
    
    func out() -> String {
        var outString = ""
        for file in files {
            outString += file.out()
        }
        return outString
    }
    
    func validateStructure() throws {
        for file in files {
            for group in file.groups {
                if group.type8 == nil {
                    throw Abort(.badRequest, reason:"Unclosed group.  Type 8 record required at end of each group of transactions.")
                }
            }
            if file.type9 == nil {
                throw Abort(.badRequest, reason:"Unclosed file.  Type 9 record required at end of each logic file.")
            }
        }
    }
    
    func context() -> [PickerLine] {
        var records = [PickerLine]()
        for file in files {
            for group in file.groups {
                for detail in group.details{
                    records.append(PickerLine(record: detail.type6))
                }
            }
        }
        return records
    }
    
    func removeDetail(withId id: UUID) {
        for file in files {
            for group in file.groups {
                group.details = group.details.filter( {$0.type6.uuid != id } )
            }
        }
    }
    
    func updateValues() {
        for file in files {
            file.updateValues()
        }
    }
}
