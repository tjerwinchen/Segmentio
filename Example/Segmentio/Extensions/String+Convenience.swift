//
//  String+Convenience.swift
//  Segmentio
//
//  Created by Dmitriy Demchenko
//  Copyright © 2016 Yalantis Mobile. All rights reserved.
//

import Foundation

extension String {
    
    func stringFromCamelCase() -> String {
        var string = self
        
        
        string = string.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression,
            range: Range<String.Index>(uncheckedBounds: (lower: string.characters.startIndex, upper: string.characters.endIndex))
        )
        
        string = string.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression,
            range: Range<String.Index>(uncheckedBounds: (lower: string.characters.startIndex, upper: string.characters.endIndex))
        )
        
        
        string.replaceSubrange(startIndex...startIndex, with: String(self[startIndex]))
        
        return String(string.characters.prefix(1)).capitalized + String(string.lowercased().characters.dropFirst())
    }
    
}
