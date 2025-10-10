//
//  vb2App.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI

@main
struct vb2App: App {
    @StateObject private var viewModel = VideoPlayerViewModel()

    
    var body: some Scene {
        WindowGroup {
            VideoPlayerView()
                .environmentObject(viewModel)
        }
        .commands {  // <-- Menu bar code starts here
            CommandGroup(replacing: .newItem) {
                Button("Open Folder...") {
                    viewModel.shouldSelectFolder = true
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandMenu("Sort") {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        viewModel.setSortOption(option)
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
                        viewModel.setPlaybackEndOption(option)
                    }
                    .keyboardShortcut(option == .stop ? "s" :
                                    option == .replay ? "l" : "n",
                                    modifiers: [.command])
                }
            }
        }  // <-- Menu bar code ends here
    }
}
