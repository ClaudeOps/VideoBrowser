//
//  VideoPlayerView.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI

struct VideoPlayerView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(selectedFolder: viewModel.selectedFolder)
            
            Divider()
            
            if viewModel.isScanning {
                ProgressView("Scanning for video files...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.videoFiles.isEmpty {
                EmptyStateView()
            } else {
                VideoContentView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: viewModel.shouldSelectFolder) { _, newValue in
            if newValue {
                viewModel.selectFolder()
                viewModel.shouldSelectFolder = false
            }
        }
        .onAppear {
            setupKeyboardHandling()
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
    
    private func setupKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak viewModel] event in
            guard let viewModel = viewModel else { return event }
            return handleKeyPress(event: event, viewModel: viewModel)
        }
    }
    
    private func handleKeyPress(event: NSEvent, viewModel: VideoPlayerViewModel) -> NSEvent? {
        guard let characters = event.characters?.lowercased() else {
            return event
        }
        
        switch event.keyCode {
        case 123: // Left arrow
            viewModel.playPrevious()
            return nil
        case 124: // Right arrow
            viewModel.playNext()
            return nil
        case 51: // Delete key
            viewModel.moveCurrentFileToTrash()
            return nil
        case 49: // Spacebar
            viewModel.togglePlayPause()
            return nil
        default:
            if characters == "r" {
                viewModel.playRandom()
                return nil
            } else if characters == "m" {
                viewModel.moveCurrentFile(to: "/Volumes/Seagate-8TB/USBDDP1/xxxxx/all/CIS/move")
                return nil
            } else if characters == "," {
                viewModel.seekBackward(seconds: 10)
                return nil
            } else if characters == "." {
                viewModel.seekForward(seconds: 10)
                return nil
            }
        }
        return event
    }
}
