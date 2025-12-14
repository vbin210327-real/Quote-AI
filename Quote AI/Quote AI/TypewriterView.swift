//
//  TypewriterView.swift
//  Quote AI
//
//  A view that reveals text character by character while maintaining layout stability
//

import SwiftUI

struct TypewriterView: View {
    let text: String
    let font: Font
    let textColor: Color
    var isItalic: Bool = false
    var isStrikethrough: Bool = false
    var strikeColor: Color = .gray
    var speed: TimeInterval = 0.1
    var startDelay: TimeInterval = 0
    var isActive: Bool = true
    var onComplete: (() -> Void)? = nil
    
    @State private var revealedCount: Int = 0
    @State private var timer: Timer?
    @State private var hasStartedTyping: Bool = false
    
    var body: some View {
        // Build text using native concatenation to support smooth property animations
        let visibleString = String(text.prefix(revealedCount))
        let invisibleString = String(text.dropFirst(revealedCount))
        
        // Ensure font metrics match exactly for both parts
        let effectiveFont = isItalic ? font.italic() : font
        
        let visibleText = Text(visibleString)
            .font(effectiveFont)
        
        let invisibleText = Text(invisibleString)
            .font(effectiveFont)
            .foregroundColor(.clear)

        return (visibleText + invisibleText)
            .foregroundColor(textColor) // Smoothly animates color changes
            .overlay(
                // Strikethrough line overlay (No GeometryReader to prevent layout flicker)
                Rectangle()
                    .fill(strikeColor)
                    .frame(height: 2)
                    .offset(y: 1) // Fine-tune vertical position
                    .scaleEffect(x: isStrikethrough ? 1 : 0, y: 1, anchor: .leading)
                    .opacity(isStrikethrough ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: isStrikethrough)
            )
            .onChange(of: isActive) { active in
                if active && !hasStartedTyping {
                    startAnimationSequence()
                }
            }
            .onAppear {
                if isActive && !hasStartedTyping {
                    startAnimationSequence()
                }
            }
            .onDisappear {
                stopTimer()
            }
    }
    
    // attributedText property removed as it caused re-render glitches
    
    private func startAnimationSequence() {
        hasStartedTyping = true
        
        if startDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                startTyping()
            }
        } else {
            startTyping()
        }
    }
    
    private func startTyping() {
        let totalCount = text.count
        
        // If already full (e.g. empty string), complete
        if totalCount == 0 {
            onComplete?()
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in
            if revealedCount < totalCount {
                revealedCount += 1
                
                 if revealedCount % 3 == 0 {
                     let impact = UIImpactFeedbackGenerator(style: .light)
                     impact.impactOccurred(intensity: 0.3)
                }
            } else {
                stopTimer()
                onComplete?()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    VStack(spacing: 20) {
        TypewriterView(
            text: "Stable Layout Scaling",
            font: .title,
            textColor: .black
        )
        .border(Color.red)
        
        TypewriterView(
            text: "Hello\nMulti-line\nWorld",
            font: .body,
            textColor: .blue,
            speed: 0.2
        )
        .border(Color.green)
    }
}
