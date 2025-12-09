import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .italic()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(Color.black)
                .cornerRadius(28)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .padding(.horizontal, 50)
        .padding(.bottom, 50)
    }
}
