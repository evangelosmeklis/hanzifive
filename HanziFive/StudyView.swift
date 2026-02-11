import SwiftUI

struct StudyView: View {
    private let lessons = StudyLessonData.lessons
    @AppStorage("studyCompletedLessons") private var studyCompletedLessons: String = ""
    @AppStorage("studyReverseCompletedLessons") private var studyReverseCompletedLessons: String = ""
    @AppStorage("studyWritingCompletedLessons") private var studyWritingCompletedLessons: String = ""

    private var totalCards: Int {
        lessons.reduce(0) { $0 + $1.cards.count }
    }

    private var totalHanzi: Int {
        Set(lessons.flatMap { lesson in lesson.cards.map { card in card.character } }).count
    }

    private var streakCount: Int {
        writingCompletedSet.count
    }

    private var completedSet: Set<Int> {
        parseLessonSet(studyCompletedLessons)
    }

    private var reverseCompletedSet: Set<Int> {
        parseLessonSet(studyReverseCompletedLessons)
    }

    private var writingCompletedSet: Set<Int> {
        parseLessonSet(studyWritingCompletedLessons)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroBanner

                VStack(spacing: 20) {
                    statsStrip
                        .padding(.top, -28)

                    lessonsSectionHeader

                    ForEach(lessons) { lesson in
                        StudyLessonCardView(
                            lesson: lesson,
                            isCompleted: completedSet.contains(lesson.number),
                            isReverseCompleted: reverseCompletedSet.contains(lesson.number),
                            isWritingCompleted: writingCompletedSet.contains(lesson.number),
                            onCompleted: { markCompleted(lesson.number) },
                            onReverseCompleted: { markReverseCompleted(lesson.number) },
                            onWritingCompleted: { markWritingCompleted(lesson.number) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
                .maxReadableWidth(720)
            }
        }
        .background(Color(red: 0.96, green: 0.955, blue: 0.94).ignoresSafeArea())
    }

    private var heroBanner: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.43, blue: 0.76),
                    Color(red: 0.24, green: 0.57, blue: 0.84),
                    Color(red: 0.30, green: 0.68, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: 220, y: -30)

            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 130, height: 130)
                .offset(x: -20, y: 90)

            VStack(alignment: .leading, spacing: 14) {
                Text("学习")
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text("Lesson Decks 1-11")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))

                HStack(spacing: 8) {
                    Image("lesson")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                    Text("Each lesson has separate Flashcards and Writing")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.15)))

                Spacer().frame(height: 34)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
    }

    private var statsStrip: some View {
        HStack(spacing: 10) {
            statPill(color: AppTheme.warning, value: "\(streakCount)", label: "Streak") {
                Image("usefire")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
            }
            statPill(color: AppTheme.accent, value: "\(totalCards)", label: "Cards") {
                Image("useflashcards")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
            }
            statPill(color: AppTheme.success, value: "\(totalHanzi)", label: "Hanzi") {
                Image("usehanzi")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
            }
        }
    }

    private func statPill<Icon: View>(color: Color, value: String, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 8) {
            icon()

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(AppTheme.primaryText)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }

    private var lessonsSectionHeader: some View {
        HStack {
            HStack(spacing: 7) {
                Image("lesson")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                Text("Lessons for HSK1")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Spacer()

            Text("\(totalCards) cards total")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, 4)
    }

    private func parseLessonSet(_ raw: String) -> Set<Int> {
        Set(raw.split(separator: ",").compactMap { Int($0) })
    }

    private func serializeLessonSet(_ set: Set<Int>) -> String {
        set.sorted().map(String.init).joined(separator: ",")
    }

    private func markCompleted(_ lessonNumber: Int) {
        var set = completedSet
        set.insert(lessonNumber)
        studyCompletedLessons = serializeLessonSet(set)
    }

    private func markReverseCompleted(_ lessonNumber: Int) {
        var completed = completedSet
        completed.insert(lessonNumber)
        studyCompletedLessons = serializeLessonSet(completed)

        var reverse = reverseCompletedSet
        reverse.insert(lessonNumber)
        studyReverseCompletedLessons = serializeLessonSet(reverse)
    }

    private func markWritingCompleted(_ lessonNumber: Int) {
        var writing = writingCompletedSet
        writing.insert(lessonNumber)
        studyWritingCompletedLessons = serializeLessonSet(writing)
    }
}

struct StudyLessonCardView: View {
    let lesson: StudyLesson
    let isCompleted: Bool
    let isReverseCompleted: Bool
    let isWritingCompleted: Bool
    let onCompleted: () -> Void
    let onReverseCompleted: () -> Void
    let onWritingCompleted: () -> Void

    private var tint: Color {
        AppTheme.levelColors[(lesson.number - 1) % AppTheme.levelColors.count]
    }

    private var lessonIconName: String? {
        switch lesson.number {
        case 1: return "lesson1"
        case 2: return "lesson2"
        case 3: return "lesson3"
        case 4: return "lesson4"
        case 5: return "lesson5"
        case 6: return "lesson6"
        case 7: return "lesson7"
        case 8: return "lesson8"
        case 9: return "lesson9"
        case 10: return "lesson10"
        case 11: return "lesson11"
        default: return nil
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                StudyLessonSessionView(
                    lesson: lesson,
                    startInReverse: false,
                    onComplete: onCompleted,
                    onReverseComplete: onReverseCompleted,
                    onWritingComplete: onWritingCompleted
                )
            } label: {
                HStack(spacing: 14) {
                    Group {
                        if let lessonIconName {
                            Image(lessonIconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 62, height: 62)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [tint, tint.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 62, height: 62)

                                Text("L\(lesson.number)")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundStyle(.white)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(lesson.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text("\(lesson.cards.count) flashcards")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)

                        if let sample = lesson.cards.first {
                            Text("\(sample.character) • \(sample.pinyin)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white)
                        .shadow(color: isCompleted ? .clear : .black.opacity(0.05), radius: 6, y: 2)
                )
            }
            .buttonStyle(BounceButtonStyle())
            .modifier(StudyCompletionShimmer(isCompleted: isCompleted, isReverseCompleted: isReverseCompleted, isWritingCompleted: isWritingCompleted))

            if isCompleted {
                HStack(spacing: 6) {
                    NavigationLink {
                        StudyLessonSessionView(
                            lesson: lesson,
                            startInReverse: true,
                            onComplete: onReverseCompleted,
                            onWritingComplete: onWritingCompleted
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 9, weight: .bold))
                            Text(isReverseCompleted ? "Reverse Complete" : "Study in Reverse")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(isReverseCompleted ? AppTheme.info : AppTheme.purple)
                        )
                    }

                    NavigationLink {
                        StudyLessonWritingView(
                            lesson: lesson,
                            onComplete: onWritingCompleted
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.and.scribble")
                                .font(.system(size: 9, weight: .bold))
                            Text(isWritingCompleted ? "Writing Complete" : "Practice Writing")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(isWritingCompleted ? AppTheme.info : AppTheme.success)
                        )
                    }
                }
                .offset(y: -12)
                .padding(.trailing, 8)
            }
        }
    }
}

struct StudyCompletionShimmer: ViewModifier {
    let isCompleted: Bool
    let isReverseCompleted: Bool
    let isWritingCompleted: Bool

    func body(content: Content) -> some View {
        if isCompleted && isReverseCompleted && isWritingCompleted {
            content.shimmeringDiamondBorder(cornerRadius: 18)
        } else if isCompleted && (isReverseCompleted || isWritingCompleted) {
            content.shimmeringRainbowBorder(cornerRadius: 18)
        } else if isCompleted {
            content.shimmeringGoldBorder(cornerRadius: 18)
        } else {
            content
        }
    }
}
