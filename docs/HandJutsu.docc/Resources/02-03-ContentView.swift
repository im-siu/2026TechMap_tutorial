import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var isImmersiveSpaceOpen = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Hand Jutsu")
                .font(.largeTitle)

            Button(isImmersiveSpaceOpen ? "Close Space" : "Open Space") {
                Task {
                    if isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                        isImmersiveSpaceOpen = false
                    } else {
                        let result = await openImmersiveSpace(id: AppSpace.handJutsu)

                        if case .opened = result {
                            isImmersiveSpaceOpen = true
                        }
                    }
                }
            }
        }
        .padding()
    }
}
