//
//  LikeMultiSpringDemo.swift
//  YKAnimationProbe
//
//  Created by Yakamoz on 2026/3/19.
//

import SwiftUI

struct LikeMultiSpringDemo: View {
    @State private var burst = 0
    @State private var liked = false

    var body: some View {
        VStack(spacing: 28) {
            Text("四段相位：原大 → 鼓起 → 轻压 → 归位。每段不同 spring。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // 点赞和取消点赞用不同相位序列，避免“取消也像庆祝”。
            PhaseAnimator(liked ? LikePhase.likeSequence : LikePhase.unlikeSequence, trigger: burst) { phase in
                Image(systemName: liked ? "heart.fill" : "heart")
                    .font(.system(size: 72))
                    .foregroundStyle(liked ? Color.red.gradient : Color.gray.gradient)
                    .scaleEffect(phase.scale)
            } animation: { phase in
                switch phase {
                case .neutral:
                    return .default
                case .blowUp:
                    // 大过冲：低阻尼感
                    return .spring(response: 0.28, dampingFraction: 0.42)
                case .shrink:
                    return .spring(response: 0.12, dampingFraction: 0.78)
                case .settle:
                    return .spring(response: 0.4, dampingFraction: 0.72)
                }
            }
            .onTapGesture {
                liked.toggle()
                burst += 1
            }

            Text("点击红心触发整套连招")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("点赞弹性")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 点赞多段弹性

private enum LikePhase: CaseIterable, Equatable {
    case neutral, blowUp, shrink, settle

    static let likeSequence: [LikePhase] = [.neutral, .blowUp, .shrink, .settle]
    static let unlikeSequence: [LikePhase] = [.neutral, .shrink, .settle]

    var scale: CGFloat {
        switch self {
        case .neutral: return 1.0
        case .blowUp: return 1.8
        case .shrink: return 0.78
        case .settle: return 1.0
        }
    }
}
