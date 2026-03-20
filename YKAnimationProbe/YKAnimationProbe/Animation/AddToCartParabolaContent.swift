//
//  AddToCartParabolaContent.swift
//  YKAnimationProbe
//
//  Created by Yakamoz on 2026/3/19.
//

import SwiftUI

// MARK: - 抛物线 + 购物车 Q 弹（SwiftUI 写法）
struct AddToCartParabolaContent: View {
    @State private var flyProgress: CGFloat = 0
    @State private var isFlying = false
    @State private var cartNudge = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let start = CGPoint(x: w * 0.22, y: h * 0.72)
            let end = CGPoint(x: w * 0.88, y: h * 0.12)
            let ctrl = CGPoint(
                x: (start.x + end.x) / 2,
                y: min(start.y, end.y) - 140
            )
            let pos = quadBezier(t: flyProgress, p0: start, p1: ctrl, p2: end)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.blue.opacity(0.12))
                    .frame(width: w * 0.5, height: 120)
                    .position(x: w * 0.28, y: h * 0.72)

                Text("商品")
                    .font(.headline)
                    .position(x: w * 0.28, y: h * 0.72)

                Button(action: launchFlight) {
                    Label("加入购物车", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .position(x: w * 0.28, y: h * 0.72 + 52)

                CartIconBadge(nudge: cartNudge)
                    .position(x: end.x, y: end.y)

                if isFlying {
                    Image(systemName: "bag.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .position(pos)
                }
            }
        }
    }

    private func launchFlight() {
        isFlying = true
        flyProgress = 0
        withAnimation(.timingCurve(0.2, 0.9, 0.15, 1.0, duration: 0.58)) {
            flyProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            isFlying = false
            flyProgress = 0
            cartNudge += 1
        }
    }

    private func quadBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let u = 1 - t
        let x = u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x
        let y = u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }
}

struct AddToCartParabolaDemo: View {
    var body: some View {
        AddToCartParabolaContent()
            .padding()
            .navigationTitle("购物车抛物线")
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// 被「砸中」时：缩放 + 旋转，用 spring 一次表达 Q 弹
private struct CartIconBadge: View {
    var nudge: Int

    var body: some View {
        PhaseAnimator([0, 1, 0], trigger: nudge) { phase in
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.2))
                    .frame(width: 52, height: 52)
                Image(systemName: "cart.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .scaleEffect(phase == 1 ? 1.28 : 1.0)
            .rotationEffect(.degrees(phase == 1 ? -14 : 0))
        } animation: { phase in
            switch phase {
            case 1:
                return .spring(response: 0.32, dampingFraction: 0.38)
            default:
                return .spring(response: 0.45, dampingFraction: 0.65)
            }
        }
    }
}
