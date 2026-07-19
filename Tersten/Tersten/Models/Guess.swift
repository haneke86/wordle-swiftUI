//
//  Guess.swift
//  Tersten
//
//  Created by Silvia España on 17/2/22.
//

import SwiftUI

struct Guess {
    
    let index: Int
    var word = "     "
    var backgroundColors = [Color](repeating: .wrong, count: 5)
    var cardFlipped = [Bool](repeating: false, count: 5)
    var guessLetters: [String] {
        word.map { String($0) }
    }
    
    var results: String {
        
        let tryColors: [Color : String] = [.misplaced : "🟨", .correct : "🟩", .wrong : "⬛"]
        return backgroundColors.compactMap { tryColors[$0]}.joined(separator: "")
    }
}
