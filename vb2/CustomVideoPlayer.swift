//
//  CustomVideoPlayer.swift
//  vb2
//
//  Created by Claude Wilder on 2025-10-10.
//

import SwiftUI
import AVKit
import AppKit

// MARK: - Custom Video Player View

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

// MARK: - Player Container View

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
