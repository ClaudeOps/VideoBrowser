//
//  SettingsView.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Settings Content
            Form {
                Section {
                    HStack {
                        Text("Seek Forward:")
                            .frame(width: 120, alignment: .leading)
                        
                        Slider(value: $viewModel.settings.seekForwardSeconds, in: 1...60, step: 1)
                        
                        Text("\(Int(viewModel.settings.seekForwardSeconds))s")
                            .frame(width: 40, alignment: .trailing)
                            .monospacedDigit()
                    }
                    
                    HStack {
                        Text("Seek Backward:")
                            .frame(width: 120, alignment: .leading)
                        
                        Slider(value: $viewModel.settings.seekBackwardSeconds, in: 1...60, step: 1)
                        
                        Text("\(Int(viewModel.settings.seekBackwardSeconds))s")
                            .frame(width: 40, alignment: .trailing)
                            .monospacedDigit()
                    }
                } header: {
                    Text("Keyboard Shortcuts")
                        .font(.headline)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        KeyboardShortcutRow(key: ",", description: "Seek backward \(Int(viewModel.settings.seekBackwardSeconds))s")
                        KeyboardShortcutRow(key: ".", description: "Seek forward \(Int(viewModel.settings.seekForwardSeconds))s")
                        KeyboardShortcutRow(key: "Space", description: "Play/Pause")
                        KeyboardShortcutRow(key: "←", description: "Previous video")
                        KeyboardShortcutRow(key: "→", description: "Next video")
                        KeyboardShortcutRow(key: "R", description: "Random video")
                        KeyboardShortcutRow(key: "M", description: "Move file")
                        KeyboardShortcutRow(key: "Delete", description: "Move to trash")
                    }
                } header: {
                    Text("Keyboard Shortcuts Reference")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            .padding()
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
}

struct KeyboardShortcutRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(VideoPlayerViewModel())
}
