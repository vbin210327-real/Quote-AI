//
//  SquarePenIcon.swift
//  Quote AI
//
//  Static square pen icon based on Lucide square-pen
//

import SwiftUI

struct SquarePenIcon: View {
    var size: CGFloat = 24
    var strokeColor: Color = .primary
    var lineWidth: CGFloat = 2

    // Scale factor from standard 24x24 Lucide viewbox
    private var scale: CGFloat {
        size / 24.0
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scaledLineWidth = lineWidth * scale

            // Square path: M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7
            // This draws the  document/square frame with open top-right corner
            var squarePath = Path()
            squarePath.move(to: CGPoint(x: 12 * scale, y: 3 * scale))
            squarePath.addLine(to: CGPoint(x: 5 * scale, y: 3 * scale))
            // Arc for top-left corner (radius 2)
            squarePath.addArc(
                tangent1End: CGPoint(x: 3 * scale, y: 3 * scale),
                tangent2End: CGPoint(x: 3 * scale, y: 5 * scale),
                radius: 2 * scale
            )
            squarePath.addLine(to: CGPoint(x: 3 * scale, y: 19 * scale))
            // Arc for bottom-left corner
            squarePath.addArc(
                tangent1End: CGPoint(x: 3 * scale, y: 21 * scale),
                tangent2End: CGPoint(x: 5 * scale, y: 21 * scale),
                radius: 2 * scale
            )
            squarePath.addLine(to: CGPoint(x: 19 * scale, y: 21 * scale))
            // Arc for bottom-right corner
            squarePath.addArc(
                tangent1End: CGPoint(x: 21 * scale, y: 21 * scale),
                tangent2End: CGPoint(x: 21 * scale, y: 19 * scale),
                radius: 2 * scale
            )
            squarePath.addLine(to: CGPoint(x: 21 * scale, y: 14 * scale))

            context.stroke(
                squarePath,
                with: .color(strokeColor),
                style: StrokeStyle(lineWidth: scaledLineWidth, lineCap: .round, lineJoin: .round)
            )

            // Pen path - simplified version of the Lucide pen
            // The pen goes from top-right corner diagonally to center-left
            var penPath = Path()

            // Pen body (diagonal line from top-right to center)
            let penTopX = 21.375 * scale
            let penTopY = 2.625 * scale
            let penBottomX = 9.362 * scale
            let penBottomY = 14.639 * scale

            // Draw the pen as a rotated rectangle/line with rounded ends
            penPath.move(to: CGPoint(x: penTopX, y: penTopY))
            penPath.addLine(to: CGPoint(x: penBottomX, y: penBottomY))

            context.stroke(
                penPath,
                with: .color(strokeColor),
                style: StrokeStyle(lineWidth: scaledLineWidth, lineCap: .round, lineJoin: .round)
            )

            // Pen tip/nib area (the writing point part)
            var tipPath = Path()
            tipPath.move(to: CGPoint(x: penBottomX, y: penBottomY))
            tipPath.addLine(to: CGPoint(x: 6.5 * scale, y: 17.5 * scale))

            context.stroke(
                tipPath,
                with: .color(strokeColor),
                style: StrokeStyle(lineWidth: scaledLineWidth, lineCap: .round, lineJoin: .round)
            )

            // Small dot/circle at the pen handle top
            let circlePath = Path(ellipseIn: CGRect(
                x: (penTopX - 1 * scale),
                y: (penTopY - 1 * scale),
                width: 2 * scale,
                height: 2 * scale
            ))
            context.fill(circlePath, with: .color(strokeColor))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            SquarePenIcon(size: 18)
            SquarePenIcon(size: 24)
            SquarePenIcon(size: 32)
        }
        HStack(spacing: 20) {
            SquarePenIcon(size: 24, strokeColor: .blue)
            SquarePenIcon(size: 24, strokeColor: .gray)
            SquarePenIcon(size: 24, strokeColor: .green)
        }
    }
    .padding()
}
