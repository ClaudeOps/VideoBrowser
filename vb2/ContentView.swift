//
//  ContentView.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI
import AVKit
import Combine

// Shared state for menu bar and content view
class AppState: ObservableObject {
    @Published var selectedSort: SortOption = .fileName
    @Published var playbackEndOption: PlaybackEndOption = .playNext
    @Published var shouldSelectFolder = false
}

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
    @EnvironmentObject var appState: AppState
    @State private var videoFiles: [URL] = []
    @State private var selectedFolder: URL?
    @State private var isScanning = false
    @State private var currentIndex = 0
    @State private var player: AVPlayer?
    @State private var showingPermissionAlert = false
    @State private var fileSizeCache: [URL: Int64] = [:]
    @State private var isSorting = false
    @State private var isPlaying = true
    @State private var shouldSelectFolder = false
    
    private var selectedSort: SortOption {
        appState.selectedSort
    }
    
    private var playbackEndOption: PlaybackEndOption {
        appState.playbackEndOption
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                Text("Video Player")
                    .font(.largeTitle)
                    .padding(.top)
                
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
                        CustomVideoPlayer(player: player)
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
                            .buttonStyle(.bordered)
                            
                            Button(action: togglePlayPause) {
                                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                            }
                            .buttonStyle(.bordered)
                  
                            Button(action: playRandom) {
                                 Label("Random", systemImage: "shuffle")
                             }
                             .disabled(videoFiles.count <= 1)
                             .buttonStyle(.bordered)
                            
                            Button(action: playNext) {
                                Label("Next", systemImage: "forward.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.bottom, 10)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: appState.selectedSort) { _, _ in
            applySorting()
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                return handleKeyPress(event: event)
            }
        }
        .onChange(of: appState.shouldSelectFolder) { _, newValue in
            if newValue {
                selectFolder()
                appState.shouldSelectFolder = false
            }
        }
        .onChange(of: shouldSelectFolder) { _, newValue in
            if newValue {
                selectFolder()
                shouldSelectFolder = false
            }
        }

    }
        
    func handleKeyPress(event: NSEvent) -> NSEvent? {
        // Get the character from the key press
        guard let characters = event.characters?.lowercased() else {
            return event
        }
        
        switch event.keyCode {
        case 123: // Left arrow
            playPrevious()
            return nil // Consume the event
        case 124: // Right arrow
            playNext()
            return nil // Consume the event
        case 51: // Delete key
            moveCurrentFileToTrash()
            return nil // Consume the event
        case 49: // Spacebar
            togglePlayPause()
            return nil // Consume the event
        default:
            // Handle character keys
            if characters == "r" {
                playRandom()
                return nil // Consume the event
            } else if characters == "m" {
                moveCurrentFile(to: "/Volumes/Seagate-8TB/USBDDP1/xxxxx/all/CIS/move")
                return nil // Consume the event
            }
        }
        return event // Pass through unhandled events
    }
    
    func moveCurrentFile(to destinationPath: String) {
        guard currentIndex < videoFiles.count else { return }
        
        let fileURL = videoFiles[currentIndex]
        let fileName = fileURL.lastPathComponent
        let destinationURL = URL(fileURLWithPath: destinationPath).appendingPathComponent(fileName)
        
        do {
            // Check if destination directory exists
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: destinationPath) {
                print("Destination directory does not exist: \(destinationPath)")
                return
            }
            
            // Stop playing current video
            player?.pause()
            
            // Move the file
            try fileManager.moveItem(at: fileURL, to: destinationURL)
            
            // Remove from list
            videoFiles.remove(at: currentIndex)
            
            // Play next video or adjust index
            if videoFiles.isEmpty {
                player = nil
                currentIndex = 0
            } else if currentIndex >= videoFiles.count {
                currentIndex = videoFiles.count - 1
                playVideo(at: currentIndex)
            } else {
                playVideo(at: currentIndex)
            }
            
            print("Moved file to: \(destinationURL.path)")
        } catch {
            print("Error moving file: \(error.localizedDescription)")
        }
    }
    
    func moveCurrentFileToTrash() {
        guard currentIndex < videoFiles.count else { return }
        
        let fileURL = videoFiles[currentIndex]
        
        do {
            // Stop playing current video
            player?.pause()
            
            // Move to trash using NSWorkspace
            try FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
            
            // Remove from list
            videoFiles.remove(at: currentIndex)
            
            // Play next video or adjust index
            if videoFiles.isEmpty {
                player = nil
                currentIndex = 0
            } else if currentIndex >= videoFiles.count {
                currentIndex = currentIndex - 1
                playVideo(at: currentIndex)
            } else {
                playVideo(at: currentIndex)
            }
            
            print("Moved file to trash: \(fileURL.lastPathComponent)")
        } catch {
            print("Error moving file to trash: \(error.localizedDescription)")
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
                
                // Build file size cache in background
                var sizeCache: [URL: Int64] = [:]
                for fileURL in foundFiles {
                    if let size = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 {
                        sizeCache[fileURL] = size
                    }
                }
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.videoFiles = foundFiles
                    self.fileSizeCache = sizeCache
                    self.isScanning = false
                    self.appState.selectedSort = .fileName
                    
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
        isPlaying = true
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
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
            // Play next video, wrapping to beginning if at end
            if currentIndex < videoFiles.count - 1 {
                playVideo(at: currentIndex + 1)
            } else if !videoFiles.isEmpty {
                playVideo(at: 0)
            }
        }
    }
    
    func playPrevious() {
        guard !videoFiles.isEmpty else { return }
        
        if currentIndex > 0 {
            playVideo(at: currentIndex - 1)
        } else {
            // Wrap to last video
            playVideo(at: videoFiles.count - 1)
        }
    }
    
    func playNext() {
        guard !videoFiles.isEmpty else { return }
        
        if currentIndex < videoFiles.count - 1 {
            playVideo(at: currentIndex + 1)
        } else {
            // Wrap to first video
            playVideo(at: 0)
        }
    }
    
    func playRandom() {
        guard videoFiles.count > 1 else { return }
        
        var randomIndex: Int
        repeat {
            randomIndex = Int.random(in: 0..<videoFiles.count)
        } while randomIndex == currentIndex
        
        playVideo(at: randomIndex)
    }
    
    func applySorting() {
        guard !videoFiles.isEmpty else { return }
        guard !isSorting else { return }
        
        let currentVideoURL = videoFiles[currentIndex]
        
        // For simple sorts, do them immediately
        if selectedSort == .fileName || selectedSort == .filePath || selectedSort == .random {
            switch selectedSort {
            case .fileName:
                videoFiles.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
                
            case .filePath:
                videoFiles.sort { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
                
            case .random:
                videoFiles.shuffle()
                
            default:
                break
            }
            
            // Update current index to maintain the same video
            if let newIndex = videoFiles.firstIndex(of: currentVideoURL) {
                currentIndex = newIndex
            }
        } else {
            // For size sorts, do them in background
            isSorting = true
            let filesToSort = videoFiles
            let cache = fileSizeCache
            
            DispatchQueue.global(qos: .userInitiated).async {
                var sortedFiles = filesToSort
                
                switch self.appState.selectedSort {
                case .sizeAscending:
                    sortedFiles.sort { self.getCachedFileSize($0, cache: cache) < self.getCachedFileSize($1, cache: cache) }
                    
                case .sizeDescending:
                    sortedFiles.sort { self.getCachedFileSize($0, cache: cache) > self.getCachedFileSize($1, cache: cache) }
                    
                default:
                    break
                }
                
                DispatchQueue.main.async {
                    self.videoFiles = sortedFiles
                    self.isSorting = false
                    
                    // Update current index to maintain the same video
                    if let newIndex = self.videoFiles.firstIndex(of: currentVideoURL) {
                        self.currentIndex = newIndex
                    }
                }
            }
        }
    }
    
    func getCachedFileSize(_ url: URL, cache: [URL: Int64]) -> Int64 {
        return cache[url] ?? 0
    }
}

// Custom video player view that doesn't dim the video
struct CustomVideoPlayer: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        view.wantsLayer = true
        view.layer = playerLayer
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let playerLayer = nsView.layer as? AVPlayerLayer {
            playerLayer.player = player
        }
    }
}


#Preview {
    ContentView()
}
