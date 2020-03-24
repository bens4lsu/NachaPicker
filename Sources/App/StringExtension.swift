//
//  StringExtension.swift
//  App
//
//  Created by Ben Schultz on 3/23/20.
//

import Foundation

extension StringProtocol{
    subscript(range: ClosedRange<Int>) -> SubSequence {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        return self[startIndex..<index(startIndex, offsetBy: range.count)]
    }
}
