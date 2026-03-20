//
//  CoinBounceDemo.swift
//  YKAnimationProbe
//
//  Created by Yakamoz on 2026/3/19.
//

import SwiftUI

// MARK: - 金币掉落（显式 m, k, c）
struct CoinBounceDemo: View {
    @State private var restingY: CGFloat = 0

    /// 控制点：较高刚度 + 适中阻尼 → 落地会「弹几下」再稳
    private let landSpring = Animation.interpolatingSpring(
        mass: 1.0,
        stiffness: 520,
        damping: 28
    )

    var body: some View {
        VStack {
            Text("m=1, k=520, c=28 → 欠阻尼落地感。可改 c↑ 消弹、k↑ 更硬。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.brown.opacity(0.25))
                    .frame(height: 6)
                    .padding(.bottom, 40)

                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.yellow.gradient)
                    .shadow(radius: 2)
                    .offset(y: restingY)
                    .animation(landSpring, value: restingY)
            }
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(.gray.opacity(0.08)))

            Button("掉落一枚") {
                restingY = -220
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    restingY = 0
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 16)
        }
        .padding()
        .navigationTitle("金币弹跳")
        .navigationBarTitleDisplayMode(.inline)
    }
}
