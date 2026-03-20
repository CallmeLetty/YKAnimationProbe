//
//  HeartbeatBreathingDemo.swift
//  YKAnimationProbe
//
//  Created by Yakamoz on 2026/3/19.
//

import SwiftUI

// MARK: - 心跳呼吸灯
struct HeartbeatBreathingDemo: View {
    @State private var beat = false

    var body: some View {
        VStack(spacing: 24) {
            Text("scale + opacity + shadow 同步缓动，repeatForever")
                .font(.caption)
                .foregroundStyle(.secondary)

            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .red], startPoint: .top, endPoint: .bottom)
                )
                .scaleEffect(beat ? 1.12 : 0.96)
                .opacity(beat ? 1.0 : 0.72)
                .shadow(color: .red.opacity(beat ? 0.55 : 0.15), radius: beat ? 18 : 6)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: beat
                )
                .onAppear { beat = true }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("心跳呼吸")
        .navigationBarTitleDisplayMode(.inline)
    }
}
