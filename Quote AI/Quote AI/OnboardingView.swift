//
//  OnboardingView.swift
//  Quote AI
//
//  "Soul Tuning" Onboarding Flow
//

import SwiftUI
import GoogleSignInSwift

struct OnboardingView: View {
    var onGoBack: (() -> Void)? = nil
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var currentStep = 0
    @State private var selectedGender = ""
    @State private var nameInput = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var navigationCounter = 0
    @State private var setupLoadingComplete = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // White Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation & Progress - Hidden during setup loading step
                if currentStep != 10 {
                    HStack(spacing: 16) {
                        // Back Button - Always visible
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            if currentStep > 0 {
                                withAnimation {
                                    // Skip loading step (10) when going back from sign-in (11)
                                    if currentStep == 11 {
                                        currentStep = 9 // Go directly to personalize page
                                        setupLoadingComplete = false // Reset loading state
                                    } else {
                                        currentStep -= 1
                                    }
                                    navigationCounter += 1
                                }
                            } else {
                                // On first step, go back to Welcome
                                onGoBack?()
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                        }

                        // Linear Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Track
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)

                                // Fill
                                Capsule()
                                    .fill(Color.black)
                                    .frame(width: geometry.size.width * (CGFloat(currentStep + 1) / 12.0), height: 4)
                                    .animation(.spring(), value: currentStep)
                            }
                            .frame(height: 4)
                            .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .frame(height: 4)
                    }
                    .frame(height: 44)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                }
                
                // Title and Subtitle (dynamic based on step) - Hidden for setup loading step
                if currentStep != 10 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(stepTitle)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .lineLimit(currentStep == 3 || currentStep == 4 || currentStep == 6 || currentStep == 7 || currentStep == 8 ? nil : 1)
                            .minimumScaleFactor(currentStep == 3 || currentStep == 4 || currentStep == 6 || currentStep == 7 || currentStep == 8 ? 1.0 : 0.5)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(stepSubtitle)
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 0)
                }

                Spacer()

                // Content Steps - Custom container (no swipe navigation)
                Group {
                    switch currentStep {
                    case 0:
                        genderStep
                            .id("gender-\(navigationCounter)")
                    case 1:
                        nameStep
                    case 2:
                        birthYearStep
                            .id("birthyear-\(navigationCounter)")
                    case 3:
                        mentalEnergyStep
                            .id("mental-\(navigationCounter)")
                    case 4:
                        energyDrainStep
                            .id("energy-\(navigationCounter)")
                    case 5:
                        focusStep
                            .id("focus-\(navigationCounter)")
                    case 6:
                        barrierStep
                            .id("barrier-\(navigationCounter)")
                    case 7:
                        mindsetChartStep
                            .id("mindset-\(navigationCounter)")
                    case 8:
                        toneStep
                            .id("tone-\(navigationCounter)")
                    case 9:
                        personalizeStep
                            .id("personalize-\(navigationCounter)")
                    case 10:
                        setupLoadingStep
                            .id("setup-\(navigationCounter)")
                    default:
                        signInStep
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                Spacer()
                
                // Continue Button - Same position as Get Started in WelcomeView
                // Hide for setup loading step (10) which shows its own button, and sign-in step (11)
                if currentStep < 10 {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        nextStep()
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .italic()
                            .foregroundColor(.white)
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .frame(height: 60)
                            .background(Color.black)
                            .cornerRadius(30)
                    }
                    .disabled((currentStep == 0 && selectedGender.isEmpty) || (currentStep == 1 && nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                    .opacity((currentStep == 0 && selectedGender.isEmpty) || (currentStep == 1 && nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1.0)
                    .padding(.bottom, 20)
                }

                // "Let's get started" button for setup loading step (10)
                if currentStep == 10 && setupLoadingComplete {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        withAnimation {
                            currentStep = 11
                            navigationCounter += 1
                        }
                    }) {
                        Text("Let's get started")
                            .font(.system(size: 18, weight: .semibold))
                            .italic()
                            .foregroundColor(.white)
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .frame(height: 60)
                            .background(Color.black)
                            .cornerRadius(30)
                    }
                    .padding(.bottom, 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            selectedGender = preferences.userGender
            nameInput = preferences.userName
        }
        .onChange(of: supabaseManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                preferences.completeOnboarding()
            }
        }
    }
    
    // Dynamic title based on current step
    var stepTitle: String {
        switch currentStep {
        case 0: return "What is your gender?"
        case 1: return "What should we call you?"
        case 2: return "When were you born?"
        case 3: return "How is your mental energy right now?"
        case 4: return "What is currently draining your energy?"
        case 5: return "What are you seeking?"
        case 6: return "What's your biggest obstacle right now?"
        case 7: return "Quote AI will bring out the best in you."
        case 8: return "Pick a personality for your Quote AI experience."
        case 9: return ""
        case 10: return ""
        default: return "Save your progress"
        }
    }

    // Dynamic subtitle based on current step
    var stepSubtitle: String {
        switch currentStep {
        case 0: return "This will be used to personalize Quote AI for you"
        case 1: return "This will be used to personalize Quote AI for you"
        case 2: return "This will be used to personalize Quote AI for you"
        case 3: return ""
        case 4: return ""
        case 5: return ""
        case 6: return ""
        case 7: return ""
        case 8: return "This will be used to personalize Quote AI for you"
        case 9: return ""
        case 10: return ""
        default: return ""
        }
    }
    // Step 0: Gender - Use GenderStepView
    var genderStep: some View {
        GenderStepView(
            isActive: .constant(currentStep == 0),
            selectedGender: $selectedGender
        )
    }
    
    // Step 1: Name
    var nameStep: some View {
        VStack(spacing: 24) {
            TextField("Your Name", text: $nameInput)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.black)
                .accentColor(.black)
                .padding(.horizontal, 40)
                .submitLabel(.next)
                .onSubmit {
                    if !nameInput.isEmpty {
                        nextStep()
                    }
                }
        }
    }

    // Step 2: Birth Year - Use BirthYearStepView
    var birthYearStep: some View {
        BirthYearStepView(
            isActive: .constant(currentStep == 2),
            birthYear: $preferences.userBirthYear
        )
    }

    // Step 3: Mental Energy - Use MentalEnergyStepView
    var mentalEnergyStep: some View {
        MentalEnergyStepView(
            isActive: .constant(currentStep == 3),
            mentalEnergy: $preferences.mentalEnergy
        )
    }

    // Step 4: Energy Drain - Use EnergyDrainStepView
    var energyDrainStep: some View {
        EnergyDrainStepView(
            isActive: .constant(currentStep == 4),
            selectedEnergyDrain: $preferences.userEnergyDrain
        )
    }

    // Step 5: Focus - Use FocusStepView
    var focusStep: some View {
        FocusStepView(
            isActive: .constant(currentStep == 5),
            selectedFocus: $preferences.userFocus
        )
    }

    // Step 6: Barrier - Use BarrierStepView
    var barrierStep: some View {
        BarrierStepView(
            isActive: .constant(currentStep == 6),
            selectedBarrier: $preferences.userBarrier
        )
    }

    // Step 7: Mindset Chart
    var mindsetChartStep: some View {
        MindsetChartStepView(
            isActive: .constant(currentStep == 7)
        )
    }

    // Step 8: Tone - Use ToneStepView
    var toneStep: some View {
        ToneStepView(
            isActive: .constant(currentStep == 8),
            selectedTone: $preferences.quoteTone
        )
    }

    // Step 9: Personalize
    var personalizeStep: some View {
        PersonalizeStepView(
            isActive: .constant(currentStep == 9)
        )
    }

    // Step 10: Setup Loading
    var setupLoadingStep: some View {
        SetupLoadingStepView(
            isActive: .constant(currentStep == 10),
            isLoadingComplete: $setupLoadingComplete
        )
    }

    // Step 11: Sign In
    var signInStep: some View {
        VStack(spacing: 30) {
            Text("One last step.")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            Text("Save your profile to start.")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                Button(action: {
                    handleGoogleSignIn()
                }) {
                    HStack {
                        if let logoPath = Bundle.main.path(forResource: "google_logo", ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: logoPath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        } else {
                            GoogleLogoView(size: 24)
                        }
                        
                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .disabled(isSigningIn)
                
                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 32)
            
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    private func nextStep() {
        withAnimation {
            if currentStep == 0 {
                // Save gender
                preferences.userGender = selectedGender
                currentStep += 1
                navigationCounter += 1
            } else if currentStep == 1 {
                // Save name
                preferences.userName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                currentStep += 1
                navigationCounter += 1
            } else if currentStep == 2 {
                // Birth year is already bound to preferences, just move on
                currentStep += 1
                navigationCounter += 1
            } else if currentStep < 10 {
                currentStep += 1
                navigationCounter += 1
            }
        }
    }
    
    private func handleGoogleSignIn() {
        isSigningIn = true
        errorMessage = nil
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to present sign-in"
            isSigningIn = false
            return
        }
        
        Task {
            do {
                try await supabaseManager.signInWithGoogle(presentingViewController: rootViewController)
                // On success, the onChange handler will complete onboarding
                isSigningIn = false
            } catch {
                // Ignore user cancellation error (code -5)
                let nsError = error as NSError
                if nsError.code == -5 {
                    isSigningIn = false
                    return
                }
                
                errorMessage = "Sign-in failed: \(error.localizedDescription)"
                isSigningIn = false
            }
        }
    }
}

struct SelectionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let selection = UISelectionFeedbackGenerator()
            selection.selectionChanged()
            action()
        }) {
            HStack(spacing: 16) {
                // Radio button circle
                Circle()
                    .strokeBorder(isSelected ? Color.white : Color.gray.opacity(0.3), lineWidth: 2)
                    .background(Circle().fill(isSelected ? Color.white : Color.clear))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.black : Color.clear)
                            .frame(width: 12, height: 12)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .black)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(20)
            .background(isSelected ? Color.black : Color.gray.opacity(0.05))
            .cornerRadius(16)
        }
    }
}

#Preview {
    OnboardingView()
}

struct ToneStepView: View {
    @Binding var isActive: Bool
    @Binding var selectedTone: QuoteTone
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(QuoteTone.allCases.enumerated()), id: \.element) { index, tone in
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    selectedTone = tone
                }) {
                    Text(tone.rawValue)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(selectedTone == tone ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(selectedTone == tone ? Color.black : Color.gray.opacity(0.1))
                        .cornerRadius(16)
                }
                .offset(y: showContent ? 0 : 100)
                .opacity(showContent ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                    .delay(0.1 + Double(index) * 0.15),
                    value: showContent
                )
            }
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }
}

struct FocusStepView: View {
    @Binding var isActive: Bool
    @Binding var selectedFocus: UserFocus
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(UserFocus.allCases.enumerated()), id: \.element) { index, focus in
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    selectedFocus = focus
                }) {
                    HStack(spacing: 16) {
                        // Icon with circular white background
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: focus.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                        }
                        
                        Text(focus.rawValue)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedFocus == focus ? .white : .black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(selectedFocus == focus ? Color.black : Color.gray.opacity(0.08))
                    .cornerRadius(16)
                }
                .offset(y: showContent ? 0 : 100)
                .opacity(showContent ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                    .delay(0.1 + Double(index) * 0.15),
                    value: showContent
                )
            }
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }
}

struct BarrierStepView: View {
    @Binding var isActive: Bool
    @Binding var selectedBarrier: UserBarrier
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(UserBarrier.allCases.enumerated()), id: \.element) { index, barrier in
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    selectedBarrier = barrier
                }) {
                    HStack(spacing: 16) {
                        // Icon with circular white background
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: barrier.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                        }
                        
                        Text(barrier.rawValue)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedBarrier == barrier ? .white : .black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(selectedBarrier == barrier ? Color.black : Color.gray.opacity(0.08))
                    .cornerRadius(16)
                }
                .offset(y: showContent ? 0 : 100)
                .opacity(showContent ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                    .delay(0.1 + Double(index) * 0.15),
                    value: showContent
                )
            }
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }
}

struct EnergyDrainStepView: View {
    @Binding var isActive: Bool
    @Binding var selectedEnergyDrain: UserEnergyDrain
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(UserEnergyDrain.allCases.enumerated()), id: \.element) { index, energyDrain in
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    selectedEnergyDrain = energyDrain
                }) {
                    HStack(spacing: 16) {
                        // Icon with circular white background
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: energyDrain.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                        }
                        
                        Text(energyDrain.rawValue)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedEnergyDrain == energyDrain ? .white : .black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(selectedEnergyDrain == energyDrain ? Color.black : Color.gray.opacity(0.08))
                    .cornerRadius(16)
                }
                .offset(y: showContent ? 0 : 100)
                .opacity(showContent ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                    .delay(0.1 + Double(index) * 0.15),
                    value: showContent
                )
            }
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }
}

struct GenderStepView: View {
    @Binding var isActive: Bool
    @Binding var selectedGender: String
    @State private var showContent = false
    
    private let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(genderOptions.enumerated()), id: \.element) { index, gender in
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    selectedGender = gender
                }) {
                    Text(gender)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(selectedGender == gender ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(selectedGender == gender ? Color.black : Color.gray.opacity(0.1))
                        .cornerRadius(16)
                }
                .offset(y: showContent ? 0 : 100)
                .opacity(showContent ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                    .delay(0.1 + Double(index) * 0.15),
                    value: showContent
                )
            }
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }
}

struct MentalEnergyStepView: View {
    @Binding var isActive: Bool
    @Binding var mentalEnergy: Double
    @State private var showContent = false
    @State private var wavePhase: CGFloat = 0

    // Energy state for haptic feedback and text
    private var energyState: Int {
        if mentalEnergy < 0.2 { return 0 }      // Exhausted
        else if mentalEnergy < 0.4 { return 1 } // Drained
        else if mentalEnergy < 0.6 { return 2 } // Neutral
        else if mentalEnergy < 0.8 { return 3 } // Fresh
        else { return 4 }                       // Energized
    }

    private var currentEnergyTitle: String {
        switch energyState {
        case 0: return "Exhausted"
        case 1: return "Drained"
        case 2: return "Neutral"
        case 3: return "Fresh"
        default: return "Energized"
        }
    }

    @State private var previousEnergyState: Int = 2

    // Water level based on energy (0.15 to 0.85 of container height)
    private var waterLevel: CGFloat {
        return 0.15 + (mentalEnergy * 0.70)
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Water Container - Deep Water Style
            ZStack {
                // 1. Container Background (Airy Morandi Top)
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.85, green: 0.88, blue: 0.95), // Very light dusty blue top
                                Color.white.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    // Soft shadow for depth
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)

                // 2. Water with Wave Animation (Deep Blue Bottom)
                WaterWaveView(
                    waterLevel: waterLevel,
                    wavePhase: wavePhase
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
                // Add inner shadow/depth to water surface
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    Color(red: 0.60, green: 0.70, blue: 0.85).opacity(0.1) // Light Morandi Blue
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )

                // 3. Ruler / Depth Marks (Left Side)
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        // Create ruler ticks dynamically based on height
                        ForEach(0..<25) { i in
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: i % 5 == 0 ? 8 : 4, height: 1)
                            }
                            .frame(height: 7) // Spacing between ticks
                        }
                    }
                    .padding(.leading, 10)
                    .padding(.bottom, 20) // Align better with water bottom
                    
                    Spacer()
                }
                
                // 4. Content Overlay (Text & Icons)
                VStack {
                    HStack {
                        // Serif Typography - Dynamic Energy Title
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentEnergyTitle)
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.8)) // Deep blue text
                                .italic()
                                .animation(.easeInOut(duration: 0.2), value: currentEnergyTitle)
                            
                            // Optional subtitle or removing the second line if not needed
                            // Keeping it simple with just the status word for now as requested
                        }
                        
                        Spacer()
                        
                        // Swimmer Icon removed
                        // Keeping Spacer to push text to the left
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Depth Indicator (Bottom Left)
                    HStack {
                        Image(systemName: "arrowtriangle.left.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(String(format: "%.1fm", mentalEnergy * 10))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                    }
                    .padding(.bottom, 16)
                    .padding(.leading, 24)
                }
                
            }
            .frame(width: 220, height: 220) // Slightly larger container
            .offset(y: showContent ? 0 : 50)
            .opacity(showContent ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                .delay(0.1),
                value: showContent
            )

            Spacer()

            // Custom Slider
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        // Filled track
                        Capsule()
                            .fill(Color.black)
                            .frame(width: geometry.size.width * mentalEnergy, height: 8)
                            .animation(.easeOut(duration: 0.1), value: mentalEnergy)

                        // Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .offset(x: (geometry.size.width - 32) * mentalEnergy)
                            .animation(.easeOut(duration: 0.1), value: mentalEnergy)
                    }
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newValue = min(max(0, value.location.x / geometry.size.width), 1)
                                mentalEnergy = newValue

                                // Haptic feedback when crossing energy state thresholds
                                if energyState != previousEnergyState {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    previousEnergyState = energyState
                                }
                            }
                    )
                }
                .frame(height: 32)

                // Labels below slider
                HStack {
                    Text("Low")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Spacer()

                    Text("Medium")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Spacer()

                    Text("High")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .offset(y: showContent ? 0 : 100)
            .opacity(showContent ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                .delay(0.25),
                value: showContent
            )

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            startWaveAnimation()
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }

    private var iconOffset: CGFloat {
        return 0 // Removed
    }

    private func startWaveAnimation() {
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            wavePhase = .pi * 2
        }
    }
}

// Water wave view with animated waves
struct WaterWaveView: View {
    let waterLevel: CGFloat
    let wavePhase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep Water Gradient Background (Bottom Fill) - Light Morandi Blue
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.65, green: 0.75, blue: 0.88), // Light Dusty Blue
                                Color(red: 0.55, green: 0.65, blue: 0.80)  // Slightly deeper Light Blue
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(
                        VStack {
                            Spacer()
                            Rectangle().frame(height: geometry.size.height * waterLevel)
                        }
                    )

                // Back wave (lighter dusty blue tint for depth)
                WaveShape(
                    waterLevel: waterLevel,
                    amplitude: 8,
                    frequency: 1.2,
                    phase: wavePhase * 0.7
                )
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.72, green: 0.80, blue: 0.92).opacity(0.4), // Very Light Blue
                            Color(red: 0.60, green: 0.70, blue: 0.85).opacity(0.5)  // Light Mid Blue
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Front wave (Light Dusty Blue Surface)
                WaveShape(
                    waterLevel: waterLevel,
                    amplitude: 6,
                    frequency: 1.5,
                    phase: wavePhase
                )
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(red: 0.75, green: 0.82, blue: 0.93), location: 0.0), // Very Light Blue Surface
                            .init(color: Color(red: 0.65, green: 0.75, blue: 0.88), location: 0.4), // Light Dusty Blue
                            .init(color: Color(red: 0.55, green: 0.65, blue: 0.80), location: 1.0)  // Mid Light Blue
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // Highlights on the crest
                .overlay(
                    WaveShape(
                        waterLevel: waterLevel,
                        amplitude: 6,
                        frequency: 1.5,
                        phase: wavePhase
                    )
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                )
            }
        }
    }
}

// Custom wave shape
struct WaveShape: Shape {
    var waterLevel: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(waterLevel, phase) }
        set {
            waterLevel = newValue.first
            phase = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let waterY = rect.height * (1 - waterLevel)

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: waterY))

        // Draw wave
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * frequency * 2 + phase)
            let y = waterY + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct BirthYearStepView: View {
    @Binding var isActive: Bool
    @Binding var birthYear: Int
    @State private var showContent = false
    @State private var selectedMonth = 1
    @State private var selectedDay = 1

    private let currentYear = Calendar.current.component(.year, from: Date())
    private let minYear = 1920

    private let months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]

    var body: some View {
        VStack {
            Spacer()

            // Date Picker using native DatePicker for proper gesture handling
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        var components = DateComponents()
                        components.year = birthYear
                        components.month = selectedMonth
                        components.day = selectedDay
                        return Calendar.current.date(from: components) ?? Date()
                    },
                    set: { newDate in
                        let components = Calendar.current.dateComponents([.year, .month, .day], from: newDate)
                        birthYear = components.year ?? 2000
                        selectedMonth = components.month ?? 1
                        selectedDay = components.day ?? 1
                    }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 200)
            .offset(y: showContent ? 0 : 100)
            .opacity(showContent ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                .delay(0.1),
                value: showContent
            )

            Spacer()
        }
        .padding(.horizontal, 16)
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }
}

struct MindsetChartStepView: View {
    @Binding var isActive: Bool
    @State private var showContent = false
    @State private var animateChart = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Chart Card
            VStack(alignment: .leading, spacing: 16) {
                // Chart Title
                Text("Your mindset")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)

                // Chart Area
                ZStack {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<3) { _ in
                            Divider()
                                .background(Color.gray.opacity(0.2))
                            Spacer()
                        }
                        Divider()
                            .background(Color.gray.opacity(0.2))
                    }
                    .frame(height: 160)

                    // Lines
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let height: CGFloat = 160
                        let startY = height * 0.75  // Even lower start point

                        // Without Quote AI - wavy flat line (Morandi Blue)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: startY))
                            path.addCurve(
                                to: CGPoint(x: width * 0.25, y: startY - 8),
                                control1: CGPoint(x: width * 0.1, y: startY + 5),
                                control2: CGPoint(x: width * 0.2, y: startY - 12)
                            )
                            path.addCurve(
                                to: CGPoint(x: width * 0.5, y: startY + 5),
                                control1: CGPoint(x: width * 0.35, y: startY - 3),
                                control2: CGPoint(x: width * 0.42, y: startY + 10)
                            )
                            path.addCurve(
                                to: CGPoint(x: width * 0.75, y: startY - 5),
                                control1: CGPoint(x: width * 0.6, y: startY - 2),
                                control2: CGPoint(x: width * 0.68, y: startY - 8)
                            )
                            path.addCurve(
                                to: CGPoint(x: width, y: startY + 3),
                                control1: CGPoint(x: width * 0.85, y: startY),
                                control2: CGPoint(x: width * 0.95, y: startY + 8)
                            )
                        }
                        .trim(from: 0, to: animateChart ? 1 : 0)
                        .stroke(Color(red: 0.60, green: 0.70, blue: 0.85), lineWidth: 2.5) // Light Morandi Blue
                        .animation(.easeOut(duration: 1.2).delay(0.3), value: animateChart)

                        // "Without Quote AI" label next to Morandi Blue line
                        Text("Without Quote AI")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.55, green: 0.65, blue: 0.80)) // Light Morandi Blue
                            .position(x: width - 60, y: startY - 18)
                            .opacity(animateChart ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(1.2), value: animateChart)

                        // With Quote AI - rising curve (black)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: startY))
                            path.addCurve(
                                to: CGPoint(x: width, y: height * 0.12),
                                control1: CGPoint(x: width * 0.35, y: startY - 15),
                                control2: CGPoint(x: width * 0.65, y: height * 0.15)
                            )
                        }
                        .trim(from: 0, to: animateChart ? 1 : 0)
                        .stroke(Color.black, lineWidth: 3)
                        .animation(.easeOut(duration: 1.2).delay(0.3), value: animateChart)

                        // "With Quote AI" label next to black line
                        Text("With Quote AI")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .position(x: width - 52, y: height * 0.05)
                            .opacity(animateChart ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(1.2), value: animateChart)

                        // Fill between the two lines (gap area)
                        Path { path in
                            // Start from red line start
                            path.move(to: CGPoint(x: 0, y: startY))
                            // Follow black line up
                            path.addCurve(
                                to: CGPoint(x: width, y: height * 0.12),
                                control1: CGPoint(x: width * 0.35, y: startY - 15),
                                control2: CGPoint(x: width * 0.65, y: height * 0.15)
                            )
                            // Go down to red line end
                            path.addLine(to: CGPoint(x: width, y: startY + 3))
                            // Follow red line back (reverse)
                            path.addCurve(
                                to: CGPoint(x: width * 0.75, y: startY - 5),
                                control1: CGPoint(x: width * 0.95, y: startY + 8),
                                control2: CGPoint(x: width * 0.85, y: startY)
                            )
                            path.addCurve(
                                to: CGPoint(x: width * 0.5, y: startY + 5),
                                control1: CGPoint(x: width * 0.68, y: startY - 8),
                                control2: CGPoint(x: width * 0.6, y: startY - 2)
                            )
                            path.addCurve(
                                to: CGPoint(x: width * 0.25, y: startY - 8),
                                control1: CGPoint(x: width * 0.42, y: startY + 10),
                                control2: CGPoint(x: width * 0.35, y: startY - 3)
                            )
                            path.addCurve(
                                to: CGPoint(x: 0, y: startY),
                                control1: CGPoint(x: width * 0.2, y: startY - 12),
                                control2: CGPoint(x: width * 0.1, y: startY + 5)
                            )
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.15), Color.black.opacity(0.05)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(animateChart ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateChart)

                        // Start point circle
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                            .background(Circle().fill(Color.white))
                            .frame(width: 12, height: 12)
                            .position(x: 0, y: startY)
                            .opacity(animateChart ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(0.2), value: animateChart)

                        // End point circle (Quote AI line)
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                            .background(Circle().fill(Color.white))
                            .frame(width: 12, height: 12)
                            .position(x: width, y: height * 0.12)
                            .opacity(animateChart ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(1.3), value: animateChart)
                    }
                    .frame(height: 160)
                }
                .frame(height: 160)

                // Month labels
                HStack {
                    Text("Month 1")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                    Spacer()
                    Text("Month 3")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                }

                // Subtext quote
                Text("You can't fix a broken mind with the same broken mind.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            .padding(24)
            .background(Color.gray.opacity(0.06))
            .cornerRadius(20)
            .offset(y: showContent ? 0 : 50)
            .opacity(showContent ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                .delay(0.1),
                value: showContent
            )

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                animateChart = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateChart = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateChart = true
                }
            }
        }
    }
}

struct PersonalizeStepView: View {
    @Binding var isActive: Bool
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Clapping hands scene - static, no animation
                clapScene
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 24)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.8, blendDuration: 0)
                        .delay(0.05),
                        value: showContent
                    )

                // Text
                VStack(spacing: 8) {
                    Text("Now let's personalize")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)

                    Text("Quote AI for you")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                }
                .multilineTextAlignment(.center)
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                    .delay(0.1),
                    value: showContent
                )

                // Privacy + security reassurance card
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 38, height: 38)
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }

                    VStack(spacing: 6) {
                        Text("Your privacy and security matter to us.")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        Text("We keep your info private and only use it to tailor your experience.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(16)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.9, blendDuration: 0)
                    .delay(0.2),
                    value: showContent
                )

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .onChange(of: isActive) { active in
            if active {
                showContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }

    private var clapScene: some View {
        let ringSize: CGFloat = 260
        return ZStack {
            // Thin gradient ring matching the progress bar colors
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(red: 0.65, green: 0.88, blue: 0.82), location: 0.0),  // Mint
                            .init(color: Color(red: 0.98, green: 0.78, blue: 0.65), location: 0.5),  // Peach
                            .init(color: Color(red: 0.65, green: 0.88, blue: 0.82), location: 1.0)   // Mint
                        ]),
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: ringSize, height: ringSize)
                .opacity(0.7)

            // Small decorative dots around the ring
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
                    .offset(y: -ringSize / 2 + 25)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            // Clapping hands image - static
            Image("ClapHands")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SetupLoadingStepView: View {
    @Binding var isActive: Bool
    @Binding var isLoadingComplete: Bool

    @State private var progress: Double = 0
    @State private var currentStatusText = "Analyzing your preferences..."
    @State private var showContent = false

    // Setup items that will appear with checkmarks
    private let setupItems = [
        "Personalized quotes",
        "Daily motivation schedule",
        "Theme preferences",
        "Notification settings"
    ]

    @State private var completedItems: Set<Int> = []

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Percentage display
            Text("\(Int(progress * 100))%")
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.black)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: showContent)

            // Title text
            Text("We're setting up\nQuote AI for you")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

            // Progress bar with gradient
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Gradient fill - mint/cyan to peach/coral
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.65, green: 0.88, blue: 0.82), // Soft mint/cyan
                                    Color(red: 0.98, green: 0.78, blue: 0.65), // Peach/coral
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 40)
            .padding(.top, 32)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

            // Status text
            Text(currentStatusText)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.top, 16)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)

            Spacer()

            // Setup items list
            VStack(alignment: .leading, spacing: 16) {
                Text("Setting up for you")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)

                ForEach(Array(setupItems.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        Text("•")
                            .font(.system(size: 16))
                            .foregroundColor(.black)

                        Text(item)
                            .font(.system(size: 16))
                            .foregroundColor(.black)

                        Spacer()

                        if completedItems.contains(index) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 24, height: 24)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)

            Spacer()
        }
        .onChange(of: isActive) { active in
            if active {
                startLoadingAnimation()
            } else {
                // Reset state when leaving
                progress = 0
                completedItems = []
                showContent = false
                isLoadingComplete = false
            }
        }
        .onAppear {
            if isActive {
                startLoadingAnimation()
            }
        }
    }

    private func startLoadingAnimation() {
        showContent = false
        progress = 0
        completedItems = []
        isLoadingComplete = false
        currentStatusText = "Analyzing your preferences..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showContent = true
        }

        // Increment 1% at a time, with variable delays
        // Slower near the end (90-100%)
        var accumulatedTime: Double = 0.5 // Start delay

        for i in 1...100 {
            // Calculate delay for each percentage point
            let delayForThisStep: Double

            if i <= 50 {
                // 0-50%: Normal speed (~0.08s per %)
                delayForThisStep = 0.08
            } else if i <= 75 {
                // 50-75%: Slightly slower (~0.10s per %)
                delayForThisStep = 0.10
            } else if i <= 85 {
                // 75-85%: Slower (~0.15s per %)
                delayForThisStep = 0.15
            } else if i <= 92 {
                // 85-92%: Even slower (~0.25s per %)
                delayForThisStep = 0.25
            } else if i <= 97 {
                // 92-97%: Very slow (~0.4s per %)
                delayForThisStep = 0.40
            } else {
                // 97-100%: Crawling (~0.6s per %)
                delayForThisStep = 0.60
            }

            accumulatedTime += delayForThisStep

            DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedTime) {
                // Update progress 1% at a time
                progress = Double(i) / 100.0

                // Update status text and checkmarks based on progress with haptic feedback
                if i == 25 && !completedItems.contains(0) {
                    _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        completedItems.insert(0)
                    }
                    // Haptic feedback when item completes
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    currentStatusText = "Creating your quote collection..."
                }
                if i == 50 && !completedItems.contains(1) {
                    _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        completedItems.insert(1)
                    }
                    // Haptic feedback when item completes
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    currentStatusText = "Configuring your schedule..."
                }
                if i == 75 && !completedItems.contains(2) {
                    _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        completedItems.insert(2)
                    }
                    // Haptic feedback when item completes
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    currentStatusText = "Applying final touches..."
                }
                if i == 95 && !completedItems.contains(3) {
                    _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        completedItems.insert(3)
                    }
                    // Haptic feedback when item completes - slightly stronger for final item
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    currentStatusText = "All done!"
                }

                // Signal loading complete at 100%
                if i == 100 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isLoadingComplete = true
                        }
                        // Success haptic when button appears
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                    }
                }
            }
        }
    }
}
