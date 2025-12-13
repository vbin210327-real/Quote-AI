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
        Text(attributedText)
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
    
    private var attributedText: AttributedString {
        var container = AttributedString(text)
        container.font = font
        if isItalic {
            container.inlinePresentationIntent = .emphasized // mostly maps to italic
        }
        
        // Convert string index to AttributedString index is non-trivial if done naively,
        // but since we just initialized from string, characters match 1:1 generally.
        // Easier way: Build it from two substrings.
        
        let characters = Array(text)
        let visiblePart = String(characters.prefix(revealedCount))
        let invisiblePart = String(characters.dropFirst(revealedCount))
        
        var visibleAttr = AttributedString(visiblePart)
        visibleAttr.font = font
        /// Note: .italic() modifier on Text works, but for AttributedString we set properties.
        /// However, SwiftUI Text(AttributedString) might ignore view modifiers if attributes are unset?
        /// Best to apply attributes directly.
        if isItalic { visibleAttr.font = font.italic() }
        visibleAttr.foregroundColor = textColor
        if isStrikethrough {
            visibleAttr.strikethroughStyle = Text.LineStyle(pattern: .solid, color: strikeColor)
        }

        var invisibleAttr = AttributedString(invisiblePart)
        invisibleAttr.font = font
        if isItalic { invisibleAttr.font = font.italic() }
        invisibleAttr.foregroundColor = .clear

        return visibleAttr + invisibleAttr
    }
    
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
