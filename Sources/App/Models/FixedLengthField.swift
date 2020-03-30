//
//  FixedLengthField.swift
//  App
//
//  Created by Ben Schultz on 3/23/20.
//

import Foundation

enum Justification: String, Codable {
    case left = "left"
    case right = "right"
}

enum FillResult {
    case success
    case error(reason: String)
}

class FixedLengthField: Codable {
    var length: Int
    var text: String
    var padding: Character
    var justification: Justification
    var assumedDecimals: Int?
    
    var out: String {
        if text.lengthOfBytes(using: .ascii) > self.length {
            return String(text.prefix(self.length))
        }
        let paddingChars = String(repeating: padding, count: (self.length - text.lengthOfBytes(using: .ascii)))
        switch justification {
        case .left:
            return text + paddingChars
        case .right:
            return paddingChars + text
        }
        
    }
    
    init(_ val: String, size: Int) {
        self.length = size
        self.text = String(val.prefix(size))
        self.padding = " "
        self.justification = .left
        self.assumedDecimals = nil
    }
    
    init(_ val: Int, size: Int) {
        let string = String(String(val).prefix(size))
        self.length = size
        self.text = string
        self.padding = "0"
        self.justification = .right
        self.assumedDecimals = 0
        
    }
    
    init(_ val: Double, size: Int) {
        let string = String(String(format: "%.0f", val * 100).prefix(size))
        self.length = size
        self.text = string
        self.padding = "0"
        self.justification = .right
        self.assumedDecimals = 2
    }
    
    
    
    func fill(from: Int, size: Int, with: FixedLengthField) -> FillResult {
        let to = size + from - 1
        return fill(from: from, to: to, with: with)
    }
    
    func fill(from: Int, to: Int, with newData: FixedLengthField) -> FillResult {
        let size = to - from + 1
        if newData.length != size {
            return .error(reason: "Fill reqeust from \(from) and size \(size) can not be filled by FixedLengthField of size \(newData.length)")
        }
       
        let substring1 = self.text[0...from - 1]
        
        let substring2 = self.text[to + 1...length - 1]
        
        let newString = newData.out
        
        self.text = String(substring1) + newString + String(substring2)
        return .success
    }
    
    func val(from startPosition: Int, to endPosition: Int) -> String? {
        let range = startPosition...endPosition
        return String(self.text[range])
    }
    
    func val(from startPosition: Int, to endPosition: Int) -> Double? {
        let str: String? = self.val(from: startPosition, to: endPosition)
        
        guard let string = str, let double = Double(string) else {
            return nil
        }
        return double / 100
    }
    
    func val(from startPosition: Int, to endPosition: Int) -> Int? {
        let str: String? = self.val(from: startPosition, to: endPosition)
        
        guard let string = str, let int = Int(string) else {
            return nil
        }
        return int
    }
    
}
