//
//  KeyframesVsSwiftUISplitDemo.swift
//  YKAnimationProbe
//
//  Created by Yakamoz on 2026/3/19.
//

import SwiftUI

// MARK: - UIKit Keyframes 屎山 vs SwiftUI

struct KeyframesVsSwiftUISplitDemo: View {
    @State private var uiKitReplay = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("UIKit")
                        .font(.headline)
                    Text("animateKeyframes + 12 段手动采样贝塞尔 + 再嵌两段 scale/rotate。时间轴是「魔法分数」，改一个动效要全盘重算。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    KeyframesShitMountainRepresentable(replay: $uiKitReplay)
                        .frame(height: 220)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.1)))

                    Button("再播一次 UIKit 版") { uiKitReplay += 1 }
                        .buttonStyle(.bordered)
                }

                Divider().padding(.vertical, 8)

                Group {
                    Text("SwiftUI")
                        .font(.headline)
                    Text("一条 timingCurve 驱动 flyProgress；贝塞尔闭包可读；购物车反馈用 PhaseAnimator。数据（进度、相位）与视图分离。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    AddToCartParabolaContent()
                        .frame(height: 320)
                        .border(Color.orange.opacity(0.3))
                }
            }
            .padding()
        }
        .navigationTitle("Keyframes vs SwiftUI")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 典型「相对时间轴」堆叠：难读、难改、难与 SwiftUI 声明式混排
private final class KeyframesShitMountainView: UIView {
    private let bag = UIImageView(image: UIImage(systemName: "cart.fill"))
    private let fly = UIImageView(image: UIImage(systemName: "bag.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        bag.tintColor = .systemOrange
        fly.tintColor = .systemOrange
        addSubview(bag)
        addSubview(fly)
        bag.frame = CGRect(x: frame.width - 70, y: 50, width: 40, height: 40)
        fly.frame = CGRect(x: 40, y: frame.height - 120, width: 28, height: 28)
        fly.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func replay() {
        fly.isHidden = false
        fly.center = CGPoint(x: 60, y: bounds.height - 100)
        bag.transform = .identity

        let end = CGPoint(x: bag.center.x, y: bag.center.y)
        let start = fly.center
        let mid = CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - 100)

        UIView.animateKeyframes(withDuration: 0.9, delay: 0, options: [.calculationModeCubic]) {
            for step in 0..<12 {
                let t = CGFloat(step + 1) / 12
                let u = 1 - t
                let x = u * u * start.x + 2 * u * t * mid.x + t * t * end.x
                let y = u * u * start.y + 2 * u * t * mid.y + t * t * end.y
                UIView.addKeyframe(withRelativeStartTime: Double(step) / 12, relativeDuration: 1.0 / 12) {
                    self.fly.center = CGPoint(x: x, y: y)
                }
            }
            UIView.addKeyframe(withRelativeStartTime: 0.82, relativeDuration: 0.18) {
                self.fly.isHidden = true
            }
            UIView.addKeyframe(withRelativeStartTime: 0.82, relativeDuration: 0.1) {
                self.bag.transform = CGAffineTransform(rotationAngle: -0.25).scaledBy(x: 1.35, y: 1.35)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.1) {
                self.bag.transform = .identity
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bag.frame = CGRect(x: bounds.width - 70, y: 50, width: 40, height: 40)
    }
}

private struct KeyframesShitMountainRepresentable: UIViewRepresentable {
    @Binding var replay: Int

    final class Coordinator {
        var lastReplay = 0
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> KeyframesShitMountainView {
        KeyframesShitMountainView(frame: .zero)
    }

    func updateUIView(_ uiView: KeyframesShitMountainView, context: Context) {
        if replay != context.coordinator.lastReplay, replay > 0 {
            context.coordinator.lastReplay = replay
            uiView.replay()
        }
    }
}
