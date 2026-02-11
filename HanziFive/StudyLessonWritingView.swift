import SwiftUI

struct StudyLessonWritingView: View {
    let lesson: StudyLesson
    let onComplete: (() -> Void)?

    @State private var currentIndex = 0
    @State private var isFinished = false
    @State private var didNotifyCompletion = false

    @Environment(\.dismiss) private var dismiss

    init(lesson: StudyLesson, onComplete: (() -> Void)? = nil) {
        self.lesson = lesson
        self.onComplete = onComplete
    }

    private var currentCard: StudyLessonCard {
        lesson.cards[currentIndex]
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if isFinished {
                completionCard
                    .padding(24)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header
                        writingPanel
                        navigationRow
                    }
                    .padding(.vertical, 16)
                    .maxReadableWidth(720)
                }
            }
        }
        .navigationTitle("\(lesson.title) Writing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Character \(currentIndex + 1) of \(lesson.cards.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()
            }

            AnimatedProgressBar(current: currentIndex + 1, total: lesson.cards.count, color: AppTheme.success)
        }
        .padding(.horizontal, 20)
    }

    private var writingPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Writing")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            Text(currentCard.pinyin)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)

            Text(currentCard.meaning)
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)

            CharacterWritingPracticeView(character: currentCard.character)
                .id("\(lesson.number)-writing-\(currentIndex)-\(currentCard.character)")

            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                Text("Stroke-order animation is not available in this deck export, so guide mode is used for tracing and practice.")
                    .font(.caption)
            }
            .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
        .padding(.horizontal, 16)
    }

    private var navigationRow: some View {
        HStack(spacing: 10) {
            Button {
                guard currentIndex > 0 else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentIndex -= 1
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(currentIndex == 0 ? AppTheme.tertiaryText : AppTheme.info)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.info.opacity(currentIndex == 0 ? 0.05 : 0.12))
                )
            }
            .disabled(currentIndex == 0)

            Button {
                if currentIndex < lesson.cards.count - 1 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentIndex += 1
                    }
                } else {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        isFinished = true
                    }
                    if !didNotifyCompletion {
                        didNotifyCompletion = true
                        onComplete?()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentIndex == lesson.cards.count - 1 ? "Finish" : "Next")
                    Image(systemName: currentIndex == lesson.cards.count - 1 ? "checkmark" : "chevron.right")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(currentIndex == lesson.cards.count - 1 ? AppTheme.accent : AppTheme.success)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private var completionCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.13))
                    .frame(width: 100, height: 100)
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(AppTheme.success)
            }

            Text("Writing Complete")
                .font(.title2.weight(.black))
                .foregroundStyle(AppTheme.primaryText)

            Text("You finished writing all characters in \(lesson.title). Your lesson now earns the prism mastery outline.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Back to Study")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.info)
                    )
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .warmShadow(0.15)
        )
        .maxReadableWidth(520)
    }
}

struct CharacterWritingPracticeView: View {
    let character: String

    @State private var strokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var showGuide = false

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.985, green: 0.983, blue: 0.975))

                    Canvas { context, size in
                        drawGrid(in: &context, size: size)
                        drawStrokes(in: &context)
                    }

                    if showGuide {
                        Text(character)
                            .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.55, weight: .regular, design: .serif))
                            .foregroundStyle(AppTheme.primaryText.opacity(0.12))
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                            .padding(20)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.stroke, lineWidth: 1)
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            currentStroke.append(value.location)
                        }
                        .onEnded { _ in
                            if currentStroke.count > 1 {
                                strokes.append(currentStroke)
                            }
                            currentStroke = []
                        }
                )
            }
            .frame(height: 280)

            HStack(spacing: 10) {
                Button {
                    showGuide.toggle()
                } label: {
                    Label(showGuide ? "Hide guide" : "Show guide", systemImage: showGuide ? "eye.slash" : "eye")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.info)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppTheme.info.opacity(0.12)))
                }

                Button {
                    if !strokes.isEmpty {
                        _ = strokes.removeLast()
                    }
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppTheme.warning.opacity(0.12)))
                }
                .disabled(strokes.isEmpty)

                Button {
                    strokes.removeAll()
                    currentStroke.removeAll()
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.danger)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppTheme.danger.opacity(0.12)))
                }

                Spacer()
            }
        }
    }

    private func drawGrid(in context: inout GraphicsContext, size: CGSize) {
        var frame = Path()
        frame.addRect(CGRect(origin: .zero, size: size))
        context.stroke(frame, with: .color(AppTheme.stroke), style: StrokeStyle(lineWidth: 1))

        var horizontal = Path()
        horizontal.move(to: CGPoint(x: 0, y: size.height / 2))
        horizontal.addLine(to: CGPoint(x: size.width, y: size.height / 2))
        context.stroke(horizontal, with: .color(AppTheme.stroke.opacity(0.8)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

        var vertical = Path()
        vertical.move(to: CGPoint(x: size.width / 2, y: 0))
        vertical.addLine(to: CGPoint(x: size.width / 2, y: size.height))
        context.stroke(vertical, with: .color(AppTheme.stroke.opacity(0.8)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

        var diagonalA = Path()
        diagonalA.move(to: .zero)
        diagonalA.addLine(to: CGPoint(x: size.width, y: size.height))
        context.stroke(diagonalA, with: .color(AppTheme.stroke.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))

        var diagonalB = Path()
        diagonalB.move(to: CGPoint(x: size.width, y: 0))
        diagonalB.addLine(to: CGPoint(x: 0, y: size.height))
        context.stroke(diagonalB, with: .color(AppTheme.stroke.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
    }

    private func drawStrokes(in context: inout GraphicsContext) {
        for stroke in strokes {
            let path = strokePath(points: stroke)
            context.stroke(path, with: .color(AppTheme.characterPrimary), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
        }

        let active = strokePath(points: currentStroke)
        context.stroke(active, with: .color(AppTheme.accent), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
    }

    private func strokePath(points: [CGPoint]) -> Path {
        guard let first = points.first else { return Path() }
        var path = Path()
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}
