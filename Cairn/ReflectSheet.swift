import CairnCore
import SwiftData
import SwiftUI

struct ReflectSheet: View {
    /// Where the reflection editor is hosted. The same editor serves both: a
    /// bottom sheet over the Path list in a compact column (phone, Duo closed)
    /// and the detail pane beside it when the column is regular width (Duo
    /// open), so the hierarchy stays the same across poses and only the
    /// container changes.
    enum Presentation {
        case sheet
        case pane
    }

    let moment: Moment
    /// The in-progress reflection text. Owned by the presenting view, not by
    /// this one, so the draft survives when the editor is rebuilt in a
    /// different container (sheet to pane, or back) as the size class changes
    /// mid-edit. The owner seeds it from `moment.reflection` on selection.
    @Binding var editingText: String
    let presentation: Presentation
    let onDismiss: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirmation = false

    init(
        moment: Moment,
        draft: Binding<String>,
        presentation: Presentation = .sheet,
        onDismiss: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.moment = moment
        _editingText = draft
        self.presentation = presentation
        self.onDismiss = onDismiss
        self.onDelete = onDelete
    }

    private var hasUnsavedChanges: Bool {
        editingText != (moment.reflection ?? "")
    }

    var body: some View {
        editor
            .confirmationDialog(
                "Delete this moment?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete moment", role: .destructive) {
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
    }

    @ViewBuilder
    private var editor: some View {
        switch presentation {
        case .sheet:
            form
                .background(Color.cairnSurfaceOverlay)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.thinMaterial)
                .interactiveDismissDisabled(hasUnsavedChanges)
        case .pane:
            // No navigation chrome of its own: the pane lives inside the Path
            // stack's arrangement, and that stack owns the one navigation bar.
            form
                .background(Color.cairnPaper.ignoresSafeArea())
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if presentation == .sheet {
                    handle
                }
                header
                    .padding(.bottom, CairnSpacing.size5)
                prompt
                    .padding(.bottom, CairnSpacing.size3)
                textArea
                    .padding(.bottom, CairnSpacing.size4)
                deleteAction
                    .padding(.bottom, CairnSpacing.size6)
                footer
            }
            .padding(.horizontal, CairnSpacing.size5)
            .padding(.top, CairnSpacing.size3)
            .padding(.bottom, CairnSpacing.size12)
            .frame(maxWidth: CairnLayout.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var handle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.cairnBorderStrong)
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.bottom, CairnSpacing.size4)
    }

    private var header: some View {
        HStack(spacing: CairnSpacing.size3) {
            CategoryDot(category: moment.category, size: 48, filled: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(moment.category.displayName)
                    .font(.cairnBody.weight(.semibold))
                    .foregroundStyle(Color.cairnTextPrimary)
                Text(headerDateString(for: moment.timestamp))
                    .font(.cairnMono)
                    .foregroundStyle(Color.cairnTextTertiary)
            }
            Spacer(minLength: 0)
        }
    }

    private var prompt: some View {
        Text("What happened, and why did it matter?")
            .font(.cairnSerif(size: 24, weight: .light))
            .foregroundStyle(Color.cairnTextPrimary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textArea: some View {
        TextField("Take your time…", text: $editingText, axis: .vertical)
            .font(.cairnSerif(size: 18, weight: .regular))
            .foregroundStyle(Color.cairnTextPrimary)
            .lineLimit(4...)
            .padding(.horizontal, CairnSpacing.size4)
            .padding(.vertical, CairnSpacing.size3)
            .background(Color.cairnSurfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CairnRadii.medium)
                    .strokeBorder(Color.cairnBorderDefault, lineWidth: 1)
            )
    }

    private var deleteAction: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack(spacing: CairnSpacing.size2) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .regular))
                    .accessibilityHidden(true)
                Text("Delete moment")
                    .font(.cairnLabel)
            }
            .foregroundStyle(Color.cairnTextTertiary)
            .padding(.vertical, CairnSpacing.size2)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: CairnSpacing.size3) {
            Button { onDismiss() } label: {
                Text("Skip for now")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(CairnButtonStyle(.ghost))
            // Keep the label whole: next to the block-width primary button
            // the HStack otherwise shaves a point or two off this one and
            // truncates it (seen in the stacked split on iPhone Duo's inner
            // display in portrait). Fixing the label's width and giving the
            // button layout priority settles the allocation.
            .layoutPriority(1)
            // A closure rather than `action: save`: Xcode's preview
            // instrumentation wraps every argument in a generic
            // `__designTimeSelection`, and a bare method reference there is
            // ambiguous between its View and non-View overloads, which broke
            // every #Preview in this file.
            Button {
                save()
            } label: {
                HStack(spacing: CairnSpacing.size2) {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                    Text("Save reflection")
                }
            }
            .buttonStyle(CairnButtonStyle(.primary, block: true))
        }
    }

    private func save() {
        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        moment.reflection = trimmed.isEmpty ? nil : editingText
        onDismiss()
    }

    private func headerDateString(for date: Date) -> String {
        let calendar = Calendar.current
        let dayPart: String = if calendar.isDateInToday(date) {
            "Today"
        } else if calendar.isDateInYesterday(date) {
            "Yesterday"
        } else {
            date.formatted(.dateTime.month(.abbreviated).day())
        }
        let timePart = date.formatted(date: .omitted, time: .shortened)
        return "\(dayPart) · \(timePart)"
    }
}

#Preview("Pane") {
    @Previewable @State var draft = "A slow walk home. Nothing needed fixing."
    ReflectSheet(
        moment: Moment(timestamp: .now, category: .contentment, reflection: nil),
        draft: $draft,
        presentation: .pane,
        onDismiss: {},
        onDelete: {}
    )
    .modelContainer(for: Moment.self, inMemory: true)
}
