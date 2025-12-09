//
//  GoogleLogoView.swift
//  Quote AI
//
//  Google "G" logo recreation in SwiftUI with official colors
//

import SwiftUI

struct GoogleLogoView: View {
    var size: CGFloat = 24
    
    var body: some View {
        ZStack {
            // White background circle
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
            
            // The "G" shape using official Google colors
            Text("G")
                .font(.system(size: size * 0.7, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 66/255, green: 133/255, blue: 244/255), // Google Blue
                            Color(red: 52/255, green: 168/255, blue: 83/255),  // Google Green
                            Color(red: 251/255, green: 188/255, blue: 5/255),  // Google Yellow
                            Color(red: 234/255, green: 67/255, blue: 53/255)   // Google Red
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

#Preview {
    GoogleLogoView(size: 48)
}
