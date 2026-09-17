import RealityKit
import SwiftUI

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            let root = Entity()
            root.name = "HandJutsuRoot"
            content.add(root)
        }
    }
}
