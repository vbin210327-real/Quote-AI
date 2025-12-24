import SwiftUI

struct ThermalReceiptView: View {
    let content: String
    let date: Date
    let referenceID: String
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Receipt Content
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quote AI")
                            .font(.custom("Courier-Bold", size: 20))
                        Text("NO: \(referenceID)")
                            .font(.custom("Courier", size: 14))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formattedDate)
                            .font(.custom("Courier", size: 16))
                        Text(formattedTime)
                            .font(.custom("Courier", size: 16))
                    }
                }
                
                // Divider
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(height: 1)
                    .foregroundColor(.black.opacity(0.3))
                
                // Main Quote Content
                Text(content)
                    .font(.custom("Courier-Bold", size: 24))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                
                // Bottom Section
                VStack(spacing: 20) {
                    Divider()
                        .background(Color.black)
                    
                    HStack(alignment: .bottom) {
                        // Pixelated Block (Simplified representation)
                        PixelPatternView(seed: referenceID)
                            .frame(width: 80, height: 80)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("SCAN ME")
                                .font(.custom("Courier", size: 12))
                            Text("#\(referenceID)")
                                .font(.custom("Courier", size: 14))
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            .padding(30)
            .background(Color(hex: "F5F5F0")) // Cream background
            
            // Tear Edge
            TearEdgeShape()
                .fill(Color(hex: "F5F5F0"))
                .frame(height: 15)
                .overlay(
                    Text("--- Quote AI ---")
                        .font(.custom("Courier", size: 10))
                        .foregroundColor(.black.opacity(0.4))
                        .offset(y: -10)
                )
        }
        .frame(width: 350) // Fixed width for consistent image generation
        .clipped()
    }
}

// Custom shapes and helper views
struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

struct TearEdgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let zigzagWidth: CGFloat = 10
        let zigzagHeight: CGFloat = 8
        
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        
        var x: CGFloat = width
        while x > 0 {
            x -= zigzagWidth
            path.addLine(to: CGPoint(x: x + zigzagWidth/2, y: height - zigzagHeight))
            path.addLine(to: CGPoint(x: x, y: height))
        }
        
        path.closeSubpath()
        return path
    }
}

struct PixelPatternView: View {
    let seed: String
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<4) { row in
                HStack(spacing: 4) {
                    ForEach(0..<4) { col in
                        Rectangle()
                            .fill(shouldFill(row: row, col: col) ? Color.black : Color.clear)
                            .frame(width: 15, height: 15)
                    }
                }
            }
        }
    }
    
    private func shouldFill(row: Int, col: Int) -> Bool {
        // Generate a deterministic but "random-looking" pattern based on the seed
        // We use the hash of the seed combined with coordinates
        let combinedString = "\(seed)\(row)\(col)"
        let hash = combinedString.hashValue
        // Use the modulo to decide if the pixel is black or clear (roughly 60% black for a dense look)
        return abs(hash) % 10 < 6
    }
}

#Preview {
    ThermalReceiptView(
        content: "Fail a lot of job interviews making me feel like I may sleep on the street someday if I run out of all my money",
        date: Date(),
        referenceID: "E5AB45"
    )
}
