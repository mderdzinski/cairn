import CairnCore
import SwiftData
import SwiftUI

struct ReflectSheet: View {
    let moment: Moment
    let onDismiss: () -> Void
    let onDelete: () -> Void

    @State private var editingText: String
    @State private var showingDeleteConfirmation = false

    init(moment: Moment, onDismiss: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.moment = moment
        self.onDismiss = onDismiss
        self.onDelete = onDelete
        _editingText = State(initialValue: moment.reflection ?? "")
    }

    private var hasUnsavedChanges: Bool {
        editingText != (moment.reflection ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                handle
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
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.cairnSurfaceOverlay)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.thinMaterial)
        .interactiveDismissDisabled(hasUnsavedChanges)
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
            Button("Skip for now") { onDismiss() }
                .buttonStyle(GhostButtonStyle())
            Button(action: save) {
                HStack(spacing: CairnSpacing.size2) {
                    Image(systemName: "checkmark")
                    Text("Save reflection")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
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
