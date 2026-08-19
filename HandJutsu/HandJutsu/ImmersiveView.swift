//
//  ImmersiveView.swift
//  HandJutsu
//
//  Created by Im gaeun on 8/8/26.
//

import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var visualizer = HandJointVisualizer()

    var body: some View {
        RealityView { content in
            content.add(visualizer.rootEntity)
            appModel.handTracking.onSnapshotChanged = { snapshot in
                visualizer.apply(snapshot)
            }
            appModel.handTracking.start()
        }
        .onDisappear {
            appModel.handTracking.stop()
            appModel.handTracking.onSnapshotChanged = nil
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
