//
//  SplashScreenView.swift
//  Quote AI
//
//  Splash screen with app icon
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    
    var body: some View {
        if isActive {
            // Navigate to main app after splash
            EmptyView()
        } else {
            ZStack {
                // White background
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Horizontal layout: Icon + App Name
                    HStack(spacing: 12) {
                        // App Icon
                        if let iconPath = Bundle.main.path(forResource: "quote_icon_black", ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: iconPath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                        } else {
                            // Fallback: SF Symbol quote bubble
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 52))
                                .foregroundColor(.black)
                        }
                        
                        // App Name
                        Text("Quote AI")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                }
                .opacity(opacity)
            }
            .onAppear {
                // Fade in animation
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1.0
                }
                
                // Auto-dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
