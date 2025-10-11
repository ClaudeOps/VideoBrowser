//
//  VideoPlayerApp.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI
import AVKit
import Combine


// MARK: - Models

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

struct VideoFile: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    
    var name: String {
        url.lastPathComponent
    }
    
    var path: String {
        url.path
    }
}

// MARK: - ViewModel

class VideoPlayerViewModel: ObservableObject {
    // Published state
    @Published var videoFiles: [VideoFile] = []
    @Published var selectedFolder: URL?
    @Published var isScanning = false
    @Published var currentIndex = 0
    @Published var player: AVPlayer?
    @Published var isPlaying = true
    @Published var selectedSort: SortOption = .fileName
    @Published var playbackEndOption: PlaybackEndOption = .playNext
    @Published var shouldSelectFolder = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    private var isSorting = false
    private let fileManager = FileManager.default
    private let videoExtensions = ["mp4", "mov", "m4v", "3gp"]
    private var timeObserver: Any?
    
    // MARK: - Public Methods
    
    func triggerFolderSelection() {
        shouldSelectFolder = true
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to scan for video files"
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }
            self.selectedFolder = url
            self.scanForVideoFiles(in: url)
        }
    }
    
    func setSortOption(_ option: SortOption) {
        selectedSort = option
        applySorting()
    }
    
    func setPlaybackEndOption(_ option: PlaybackEndOption) {
        playbackEndOption = option
    }
    
    func playVideo(at index: Int) {
        guard index >= 0 && index < videoFiles.count else { return }
        
        currentIndex = index
        let videoURL = videoFiles[index].url
        
        // Remove previous observer
        if let player = player {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            if let observer = timeObserver {
                player.removeTimeObserver(observer)
                timeObserver = nil
            }
        }
        
        player?.pause()
        player = AVPlayer(url: videoURL)
        
        // Add observer for when video ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.handleVideoEnd()
        }
        
        // Add time observer for progress updates
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            if let duration = self?.player?.currentItem?.duration.seconds, duration.isFinite {
                self?.duration = duration
            }
        }
        
        player?.play()
        isPlaying = true
    }
    
    func seek(to percentage: Double) {
        guard let player = player, duration > 0 else { return }
        let targetTime = duration * percentage
        let cmTime = CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
    }
    
    func seekForward(seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        player.seek(to: newTime)
    }
    
    func seekBackward(seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        let zeroTime = CMTime.zero
        player.seek(to: newTime > zeroTime ? newTime : zeroTime)
    }
    
    func playPrevious() {
        guard !videoFiles.isEmpty else { return }
        
        if currentIndex > 0 {
            playVideo(at: currentIndex - 1)
        } else {
            playVideo(at: videoFiles.count - 1)
        }
    }
    
    func playNext() {
        guard !videoFiles.isEmpty else { return }
        
        if currentIndex < videoFiles.count - 1 {
            playVideo(at: currentIndex + 1)
        } else {
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
    
    func moveCurrentFile(to destinationPath: String) {
        guard currentIndex < videoFiles.count else { return }
        
        let fileURL = videoFiles[currentIndex].url
        let fileName = fileURL.lastPathComponent
        let destinationURL = URL(fileURLWithPath: destinationPath).appendingPathComponent(fileName)
        
        do {
            if !fileManager.fileExists(atPath: destinationPath) {
                print("Destination directory does not exist: \(destinationPath)")
                return
            }
            
            player?.pause()
            try fileManager.moveItem(at: fileURL, to: destinationURL)
            videoFiles.remove(at: currentIndex)
            
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
        
        let fileURL = videoFiles[currentIndex].url
        
        do {
            player?.pause()
            try fileManager.trashItem(at: fileURL, resultingItemURL: nil)
            videoFiles.remove(at: currentIndex)
            
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
    
    // MARK: - Private Methods
    
    private func scanForVideoFiles(in directory: URL) {
        isScanning = true
        videoFiles.removeAll()
        player?.pause()
        player = nil
        currentIndex = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let enumerator = self.fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
                return
            }
            
            var foundFiles: [VideoFile] = []
            
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    
                    if resourceValues.isRegularFile == true {
                        let fileExtension = fileURL.pathExtension.lowercased()
                        if self.videoExtensions.contains(fileExtension) {
                            let size = resourceValues.fileSize.map { Int64($0) } ?? 0
                            foundFiles.append(VideoFile(url: fileURL, size: size))
                        }
                    }
                } catch {
                    print("Error checking file: \(error)")
                }
            }
            
            foundFiles.sort { $0.path < $1.path }
            
            DispatchQueue.main.async {
                self.videoFiles = foundFiles
                self.isScanning = false
                self.selectedSort = .fileName
                
                if !foundFiles.isEmpty {
                    self.playVideo(at: 0)
                }
            }
        }
    }
    
    private func handleVideoEnd() {
        switch playbackEndOption {
        case .stop:
            break
            
        case .replay:
            player?.seek(to: .zero)
            player?.play()
            
        case .playNext:
            if currentIndex < videoFiles.count - 1 {
                playVideo(at: currentIndex + 1)
            } else if !videoFiles.isEmpty {
                playVideo(at: 0)
            }
        }
    }
    
    private func applySorting() {
        guard !videoFiles.isEmpty else { return }
        guard !isSorting else { return }
        
        let currentVideoURL = videoFiles[currentIndex].url
        
        if selectedSort == .fileName || selectedSort == .filePath || selectedSort == .random {
            switch selectedSort {
            case .fileName:
                videoFiles.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                
            case .filePath:
                videoFiles.sort { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
                
            case .random:
                videoFiles.shuffle()
                
            default:
                break
            }
            
            if let newIndex = videoFiles.firstIndex(where: { $0.url == currentVideoURL }) {
                currentIndex = newIndex
            }
        } else {
            isSorting = true
            let filesToSort = videoFiles
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                var sortedFiles = filesToSort
                
                switch self.selectedSort {
                case .sizeAscending:
                    sortedFiles.sort { $0.size < $1.size }
                    
                case .sizeDescending:
                    sortedFiles.sort { $0.size > $1.size }
                    
                default:
                    break
                }
                
                DispatchQueue.main.async {
                    self.videoFiles = sortedFiles
                    self.isSorting = false
                    
                    if let newIndex = self.videoFiles.firstIndex(where: { $0.url == currentVideoURL }) {
                        self.currentIndex = newIndex
                    }
                }
            }
        }
    }
}

// MARK: - View

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

// MARK: - Subviews

struct HeaderView: View {
    let selectedFolder: URL?
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Video Player")
                .font(.largeTitle)
                .padding(.top)
            
            if let folder = selectedFolder {
                Text("Selected: \(folder.path)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
        Text("No video files found. Select a folder to begin.")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VideoContentView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let player = viewModel.player {
                CustomVideoPlayerView(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(viewModel.currentIndex) // Force recreation on video change
            }
            
            VideoControlsView()
        }
    }
}

// Custom video player that avoids built-in controls
struct CustomVideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> PlayerContainerView {
        let containerView = PlayerContainerView()
        containerView.setupPlayer(player)
        return containerView
    }
    
    func updateNSView(_ nsView: PlayerContainerView, context: Context) {
        nsView.updatePlayer(player)
    }
}

class PlayerContainerView: NSView {
    private var playerLayer: AVPlayerLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPlayer(_ player: AVPlayer) {
        // Remove old layer if exists
        playerLayer?.removeFromSuperlayer()
        
        // Create new player layer
        let newPlayerLayer = AVPlayerLayer(player: player)
        newPlayerLayer.videoGravity = .resizeAspect
        newPlayerLayer.frame = bounds
        
        layer?.addSublayer(newPlayerLayer)
        self.playerLayer = newPlayerLayer
        
        // Force initial layout
        needsLayout = true
        layoutSubtreeIfNeeded()
    }
    
    func updatePlayer(_ player: AVPlayer) {
        if playerLayer?.player !== player {
            setupPlayer(player)
        }
    }
    
    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = bounds
        CATransaction.commit()
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }
}

struct VideoControlsView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            VideoInfoView()
            ProgressBarView()
            NavigationButtonsView()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ProgressBarView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    @State private var isDragging = false
    
    var progress: Double {
        guard viewModel.duration > 0 else { return 0 }
        return viewModel.currentTime / viewModel.duration
    }
    
    var timeString: String {
        let current = formatTime(viewModel.currentTime)
        let total = formatTime(viewModel.duration)
        return "\(current) / \(total)"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    // Progress fill
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .cornerRadius(3)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let percentage = max(0, min(1, value.location.x / geometry.size.width))
                            viewModel.seek(to: percentage)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 6)
            
            Text(timeString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct VideoInfoView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            if !viewModel.videoFiles.isEmpty && viewModel.currentIndex < viewModel.videoFiles.count {
                Text(viewModel.videoFiles[viewModel.currentIndex].name)
                    .font(.headline)
                    .lineLimit(1)
                Text("Video \(viewModel.currentIndex + 1) of \(viewModel.videoFiles.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 10)
    }
}

struct NavigationButtonsView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: viewModel.playPrevious) {
                Label("Previous", systemImage: "backward.fill")
            }
            .buttonStyle(.bordered)
            
            Button(action: viewModel.togglePlayPause) {
                Label(viewModel.isPlaying ? "Pause" : "Play", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.bordered)
            
            Button(action: viewModel.playRandom) {
                Label("Random", systemImage: "shuffle")
            }
            .disabled(viewModel.videoFiles.count <= 1)
            .buttonStyle(.bordered)
            
            Button(action: viewModel.playNext) {
                Label("Next", systemImage: "forward.fill")
            }
            .buttonStyle(.bordered)
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Preview

#Preview {
    VideoPlayerView()
        .environmentObject(VideoPlayerViewModel())
}
