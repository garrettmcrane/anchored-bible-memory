import SwiftUI

struct LibraryHeaderSectionView: View {
    @Binding var isSearchPresented: Bool
    @Binding var searchText: String
    @Binding var selectedFilter: LibraryView.FilterType
    let totalCount: Int
    let practicingCount: Int
    let memorizedCount: Int
    let hasActiveSearch: Bool
    let searchTransitionNamespace: Namespace.ID
    let isSearchFieldFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                CenteredScreenTitleBar(title: "Library") {
                    Color.clear
                        .frame(width: ShellCircularIconLabel.diameter, height: ShellCircularIconLabel.diameter)
                } trailing: {
                    ShellCircularIconButton(systemImage: "magnifyingglass") {
                        withAnimation(.snappy(duration: 0.28, extraBounce: 0.06)) {
                            isSearchPresented = true
                        }
                    }
                    .matchedTransitionSource(id: "library-search", in: searchTransitionNamespace)
                    .accessibilityLabel("Search library")
                }

                if isSearchPresented || hasActiveSearch {
                    LibrarySearchSectionView(
                        searchText: $searchText,
                        isSearchPresented: $isSearchPresented,
                        hasActiveSearch: hasActiveSearch,
                        searchTransitionNamespace: searchTransitionNamespace,
                        isSearchFieldFocused: isSearchFieldFocused
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Text("View and practice your library of saved passages.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Picker("Library Filter", selection: $selectedFilter) {
                Text("All (\(totalCount))").tag(LibraryView.FilterType.all)
                Text("Practicing (\(practicingCount))").tag(LibraryView.FilterType.practicing)
                Text("Memorized (\(memorizedCount))").tag(LibraryView.FilterType.memorized)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 0)
        .padding(.top, 14)
        .padding(.bottom, 0)
    }
}

private struct LibrarySearchSectionView: View {
    @Binding var searchText: String
    @Binding var isSearchPresented: Bool
    let hasActiveSearch: Bool
    let searchTransitionNamespace: Namespace.ID
    let isSearchFieldFocused: FocusState<Bool>.Binding

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.textSecondary)

                    TextField("Search reference or text", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused(isSearchFieldFocused)

                    if hasActiveSearch {
                        Button {
                            searchText = ""
                            isSearchFieldFocused.wrappedValue = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .glassEffect(.regular.interactive(), in: .capsule)
                .glassEffectID("library-search-field", in: searchTransitionNamespace)

                Button("Cancel") {
                    withAnimation(.snappy(duration: 0.24)) {
                        isSearchPresented = false
                        searchText = ""
                    }
                    isSearchFieldFocused.wrappedValue = false
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.glass)
            }
        }
        .onAppear {
            isSearchFieldFocused.wrappedValue = true
        }
    }
}

struct LibraryManagementRailView: View {
    let isSelectionMode: Bool
    let selectedVisibleCount: Int
    let hasActiveFolderFilter: Bool
    let folderSelectionSummary: String
    let hasNonDefaultSortMode: Bool
    let onCancelSelection: () -> Void
    let onShowFolderFilter: () -> Void
    let onShowSort: () -> Void
    let onEnterSelectionMode: () -> Void

    var body: some View {
        if isSelectionMode {
            HStack(spacing: 12) {
                Text("\(selectedVisibleCount) Selected")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer(minLength: 12)

                Button("Cancel", action: onCancelSelection)
                    .font(.system(size: 16, weight: .semibold))
                    .buttonStyle(.glass)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        Button(action: onShowFolderFilter) {
                            Image(systemName: hasActiveFolderFilter ? "folder.fill" : "folder")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            hasActiveFolderFilter
                                ? .regular.tint(AppColors.selectionFill).interactive()
                                : .regular.interactive(),
                            in: .circle
                        )
                        .accessibilityLabel("Folders")

                        Button(action: onShowSort) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            hasNonDefaultSortMode
                                ? .regular.tint(AppColors.selectionFill).interactive()
                                : .regular.interactive(),
                            in: .circle
                        )
                        .accessibilityLabel("Sort")

                        Button(action: onEnterSelectionMode) {
                            Text("Select")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                        }
                        .buttonStyle(.plain)
                        .fixedSize()
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }

                if hasActiveFolderFilter {
                    Text("Folders: \(folderSelectionSummary)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.top, 8)
                        .padding(.horizontal, 2)
                }
            }
        }
    }
}

struct LibraryBottomOverlayView: View {
    let isSelectionMode: Bool
    let selectedVisibleCount: Int
    let hasSelection: Bool
    let practicingReviewEnabled: Bool
    let reviewAllEnabled: Bool
    let onStartPracticingReview: () -> Void
    let onStartReviewAll: () -> Void
    let onDoneSelection: () -> Void
    let onEditSelection: () -> Void

    var body: some View {
        if isSelectionMode {
            HStack(spacing: 12) {
                Text("\(selectedVisibleCount) Selected")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer(minLength: 12)

                Button("Done", action: onDoneSelection)
                    .buttonStyle(.glass)

                Button("Edit", action: onEditSelection)
                    .buttonStyle(.glass)
                    .disabled(!hasSelection)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule(style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        } else {
            HStack(spacing: 10) {
                libraryReviewButton(
                    title: "Review Practicing",
                    tint: AppColors.reviewPracticingActionBackground,
                    textColor: AppColors.reviewPracticingActionText,
                    isEnabled: practicingReviewEnabled,
                    action: onStartPracticingReview
                )

                libraryReviewButton(
                    title: "Review All",
                    tint: AppColors.reviewAllActionBackground,
                    textColor: AppColors.reviewAllActionText,
                    isEnabled: reviewAllEnabled,
                    action: onStartReviewAll
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func libraryReviewButton(
        title: String,
        tint: Color,
        textColor: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(isEnabled ? textColor : AppColors.textSecondary.opacity(0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
        }
        .buttonStyle(.glass(.regular.tint(isEnabled ? tint : AppColors.secondarySurface).interactive()))
        .disabled(!isEnabled)
    }
}
