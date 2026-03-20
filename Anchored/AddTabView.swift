import SwiftUI

struct AddTabView: View {
    let focusTrigger: Int

    var body: some View {
        AddHubView(showsCancelButton: false, focusTrigger: focusTrigger) { newVerse in
            VerseRepository.shared.addVerse(newVerse)
        }
    }
}

#Preview {
    AddTabView(focusTrigger: 0)
}
