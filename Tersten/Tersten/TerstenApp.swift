//
//  TerstenApp.swift
//  Tersten
//
//  Created by Silvia España on 17/2/22.
//

import SwiftUI

@main
struct TerstenApp: App {
    
    @StateObject var dataModel = TerstenDataModel()
    @StateObject var colorSchemeManager = ColorSchemeManager()
    
    var body: some Scene {
        
        WindowGroup {
            
            GameView()
                .environmentObject(dataModel)
                .environmentObject(colorSchemeManager)
                .onAppear {
                    
                    colorSchemeManager.applyColorScheme()
                }
        }
    }
}
