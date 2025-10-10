//
//  vb2App.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI

@main
struct vb2App: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {  // <-- Menu bar code starts here
            CommandGroup(replacing: .newItem) {
                Button("Open FOlder...") {
                    appState.shouldSelectFolder = true
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandMenu("Sort") {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        appState.selectedSort = option
                    }
                    .keyboardShortcut(option == .fileName ? "1" :
                                    option == .filePath ? "2" :
                                    option == .sizeAscending ? "3" :
                                    option == .sizeDescending ? "4" : "5")
                }
            }
            CommandMenu("Playback") {
                ForEach(PlaybackEndOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        appState.playbackEndOption = option
                    }
                    .keyboardShortcut(option == .stop ? "s" :
                                    option == .replay ? "l" : "n",
                                    modifiers: [.command])
                }
            }
        }  // <-- Menu bar code ends here
    }
}
