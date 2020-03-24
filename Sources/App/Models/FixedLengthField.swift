//
//  FixedLengthField.swift
//  App
//
//  Created by Ben Schultz on 3/23/20.
//

import Foundation

enum Justification {
    case left
    case right
}

enum FillResult {
    case success
    case error(reason: String)
}

class FixedLengthField {
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
        let string = String(String(Int(val * 100)).prefix(size))
        self.length = size
        self.text = string
        self.padding = "0"
        self.justification = .right
        self.assumedDecimals = 2
    }
    
    
    
    func fill(from: Int, to: Int, with: FixedLengthField) -> FillResult {
        let size = to - from + 1
        return fill(from: from, size: size, with: with)
    }
    
    func fill(from: Int, size: Int, with newData: FixedLengthField) -> FillResult {
        if newData.length != size {
            return .error(reason: "Fill reqeust from \(from) and size \(size) can not be filled by FixedLengthField of size \(newData.length)")
        }
        self.text = newData.text
        return .success
    }
}
