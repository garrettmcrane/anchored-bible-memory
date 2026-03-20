import SwiftUI

struct AddTabView: View {
    var body: some View {
        AddVerseView(showsCancelButton: false) { newVerse in
            VerseRepository.shared.addVerse(newVerse)
        }
    }
}

#Preview {
    AddTabView()
}
