import SwiftUI

struct PurgeView: View {
    let store: CleanupStore

    var body: some View {
        CleanupReviewView(
            store: store,
            title: "Purge",
            subtitle: "Project artifacts such as build outputs will require explicit review.",
            systemImage: "shippingbox"
        )
    }
}
