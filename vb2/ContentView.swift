//
//  ContentView.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI

struct ContentView: View {
    @State private var videoFiles: [URL] = []
    @State private var selectedFolder: URL?
    @State private var isScanning = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Video File Finder")
                .font(.largeTitle)
                .padding(.top)
            
            // Select Folder Button
            Button(action: selectFolder) {
                Label("Select Folder", systemImage: "folder")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isScanning)
            
            // Selected folder path
            if let folder = selectedFolder {
                Text("Selected: \(folder.path)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Divider()
            
            // Video files list
            if isScanning {
                ProgressView("Scanning for video files...")
                    .padding()
            } else if videoFiles.isEmpty {
                Text("No video files found. Select a folder to begin.")
                    .foregroundColor(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Found \(videoFiles.count) video file\(videoFiles.count == 1 ? "" : "s")")
                        .font(.headline)
                    
                    List(videoFiles, id: \.self) { file in
                        HStack {
                            Image(systemName: "film")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.lastPathComponent)
                                    .font(.body)
                                Text(file.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
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
        
        // Scan in background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "mpeg", "mpg", "3gp", "m2ts", "mts"]
            
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
                }
            } else {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
