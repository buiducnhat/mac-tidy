import SwiftUI

struct InstallersView: View {
    let store: CleanupStore

    var body: some View {
        CleanupReviewView(
            store: store,
            title: "Installers",
            subtitle: "Installer files will be listed here after scanning selected locations.",
            systemImage: "opticaldiscdrive"
        )
    }
}
