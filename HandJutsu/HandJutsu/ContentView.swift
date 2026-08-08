//
//  ContentView.swift
//  HandJutsu
//
//  Created by Im gaeun on 8/8/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hand Jutsu")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Hand Tracking Spike")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(appModel.handTracking.status.title)
                    .font(.headline)

                Text(appModel.handTracking.status.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                Text(appModel.handTracking.leftHandSummary)
                Text(appModel.handTracking.rightHandSummary)
            }
            .monospacedDigit()

            ToggleImmersiveSpaceButton()
        }
        .frame(width: 420, alignment: .leading)
        .padding(32)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
