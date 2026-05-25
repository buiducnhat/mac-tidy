import SwiftUI

struct CleanView: View {
    let store: CleanupStore

    var body: some View {
        CleanupReviewView(
            store: store,
            title: "Clean",
            subtitle: "Review safe cache candidates before moving anything to Trash.",
            systemImage: "sparkles"
        )
    }
}
