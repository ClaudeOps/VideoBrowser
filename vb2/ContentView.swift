//
//  ContentView.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI
import AVKit

enum SortOption: String, CaseIterable {
    case fileName = "File Name"
    case filePath = "File Path"
    case sizeAscending = "Size (Smallest First)"
    case sizeDescending = "Size (Largest First)"
    case random = "Random"
}

enum PlaybackEndOption: String, CaseIterable {
    case stop = "Stop"
    case replay = "Replay"
    case playNext = "Play Next"
}

struct ContentView: View {
    @State private var videoFiles: [URL] = []
    @State private var selectedFolder: URL?
    @State private var isScanning = false
    @State private var currentIndex = 0
    @State private var player: AVPlayer?
    @State private var selectedSort: SortOption = .fileName
    @State private var playbackEndOption: PlaybackEndOption = .playNext
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                Text("Video Player")
                    .font(.largeTitle)
                    .padding(.top)
                
                // Select Folder Button
                Button(action: selectFolder) {
                    Label("Select Folder", systemImage: "folder")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isScanning)
                
                // Sort options
                if !videoFiles.isEmpty {
                    HStack(spacing: 20) {
                        HStack(spacing: 10) {
                            Text("Sort by:")
                                .font(.subheadline)
                            
                            Picker("", selection: $selectedSort) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                        }
                        
                        HStack(spacing: 10) {
                            Text("When video ends:")
                                .font(.subheadline)
                            
                            Picker("", selection: $playbackEndOption) {
                                ForEach(PlaybackEndOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 150)
                        }
                    }
                }
                
                // Selected folder path
                if let folder = selectedFolder {
                    Text("Selected: \(folder.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding()
            
            Divider()
            
            // Main content area
            if isScanning {
                ProgressView("Scanning for video files...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if videoFiles.isEmpty {
                Text("No video files found. Select a folder to begin.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Video player
                VStack(spacing: 0) {
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Controls
                    VStack(spacing: 10) {
                        // Current file info
                        VStack(spacing: 4) {
                            Text(videoFiles[currentIndex].lastPathComponent)
                                .font(.headline)
                                .lineLimit(1)
                            Text("Video \(currentIndex + 1) of \(videoFiles.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)
                        
                        // Navigation buttons
                        HStack(spacing: 20) {
                            Button(action: playPrevious) {
                                Label("Previous", systemImage: "backward.fill")
                            }
                            .disabled(currentIndex == 0)
                            .buttonStyle(.bordered)
                            
                            Button(action: playNext) {
                                Label("Next", systemImage: "forward.fill")
                            }
                            .disabled(currentIndex >= videoFiles.count - 1)
                            .buttonStyle(.bordered)
                        }
                        .padding(.bottom, 10)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: selectedSort) { _, _ in
            applySorting()
        }
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to scan for video files"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                selectedFolder = url
                scanForVideoFiles(in: url)
            }
        }
    }
    
    func scanForVideoFiles(in directory: URL) {
        isScanning = true
        videoFiles.removeAll()
        player?.pause()
        player = nil
        currentIndex = 0
        
        // Scan in background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            // AVPlayer compatible formats (native macOS support)
            let videoExtensions = ["mp4", "mov", "m4v", "3gp"]
            
            if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                var foundFiles: [URL] = []
                
                for case let fileURL as URL in enumerator {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                        if resourceValues.isRegularFile == true {
                            let fileExtension = fileURL.pathExtension.lowercased()
                            if videoExtensions.contains(fileExtension) {
                                foundFiles.append(fileURL)
                            }
                        }
                    } catch {
                        print("Error checking file: \(error)")
                    }
                }
                
                // Sort files alphabetically
                foundFiles.sort { $0.path < $1.path }
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.videoFiles = foundFiles
                    self.isScanning = false
                    self.selectedSort = .fileName
                    
                    // Start playing first video if available
                    if !foundFiles.isEmpty {
                        self.playVideo(at: 0)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
            }
        }
    }
    
    func playVideo(at index: Int) {
        guard index >= 0 && index < videoFiles.count else { return }
        
        currentIndex = index
        let videoURL = videoFiles[index]
        
        // Remove previous observer if it exists
        if let player = player {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
        
        player?.pause()
        player = AVPlayer(url: videoURL)
        
        // Add observer for when video ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [self] _ in
            handleVideoEnd()
        }
        
        player?.play()
    }
    
    func handleVideoEnd() {
        switch playbackEndOption {
        case .stop:
            // Do nothing, video stays at the end
            break
            
        case .replay:
            // Seek back to beginning and play again
            player?.seek(to: .zero)
            player?.play()
            
        case .playNext:
            // Play next video if available
            if currentIndex < videoFiles.count - 1 {
                playVideo(at: currentIndex + 1)
            }
        }
    }
    
    func playPrevious() {
        if currentIndex > 0 {
            playVideo(at: currentIndex - 1)
        }
    }
    
    func playNext() {
        if currentIndex < videoFiles.count - 1 {
            playVideo(at: currentIndex + 1)
        }
    }
    
    func applySorting() {
        guard !videoFiles.isEmpty else { return }
        
        let currentVideoURL = videoFiles[currentIndex]
        
        switch selectedSort {
        case .fileName:
            videoFiles.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            
        case .filePath:
            videoFiles.sort { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            
        case .sizeAscending:
            videoFiles.sort { getFileSize($0) < getFileSize($1) }
            
        case .sizeDescending:
            videoFiles.sort { getFileSize($0) > getFileSize($1) }
            
        case .random:
            videoFiles.shuffle()
        }
        
        // Update current index to maintain the same video
        if let newIndex = videoFiles.firstIndex(of: currentVideoURL) {
            currentIndex = newIndex
        }
    }
    
    func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}


#Preview {
    ContentView()
}
