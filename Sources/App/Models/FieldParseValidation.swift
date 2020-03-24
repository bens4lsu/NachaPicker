//
//  FieldParseValidator.swift
//  App
//
//  Created by Ben Schultz on 3/23/20.
//

import Foundation

struct FieldParseValidation {
    var lowerBound: Int
    var upperBound: Int
    var routine: (String, String?) -> FillResult
    var compValue: String?
    
    
    static let isNumeric: (String, String?) -> FillResult = { test, _ in
        let regexPattern = #"\d*"#
        guard test.range(of: regexPattern, options: .regularExpression) != nil else {
            return .error(reason: "Value is not numeric")
        }
        return .success
    }
    
    static let isConstant: (String, String?) -> FillResult = { test, constant in
        return test == constant ? .success : .error(reason: "Expected constant = \(constant ?? "")")
    }
}
