//
//  NachaParser.swift
//  App
//
//  Created by Ben Schultz on 3/23/20.
//

import Foundation

class NachaDetails: Codable {
    var type6: NachaType6
    var type7s = [NachaType7]()
    
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
}

class NachaFile: Codable {
    var type1: NachaType1
    var groups = [NachaGroup]()
    var type9: NachaType9?
    
    init (_ type1: NachaType1) {
        self.type1 = type1
    }
    
    func padding() -> [NachaFilePadding] {
        let count = groups.count + 2
        let linesNeeded = 10 - (10 % count)
        var padding = [NachaFilePadding]()
        for _ in 1...linesNeeded {
            padding.append(try! NachaFilePadding())
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
}
