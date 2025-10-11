//
//  VideoPlayerApp.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI
import AVKit
import Combine


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



