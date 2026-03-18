//
//  AnimationShowcaseDemo.swift
//  YKAnimationProbe
//
//  点赞弹性 / 金币弹跳 / 心跳呼吸 / 加入购物车抛物线 + Q 弹
//  内含：弹簧物理笔记、PhaseAnimator 流转说明、SwiftUI 渲染优化要点、UIKit Keyframes 对比
//

import SwiftUI
import UIKit

// MARK: - ═══════════════════════════════════════════════════════════════════
// MARK: 理论深挖（弹簧 · PhaseAnimator · 性能）
// MARK: ═══════════════════════════════════════════════════════════════════
//
// 【1】弹簧底层数学（与 mass / stiffness / damping 的关系）
//
// 二阶系统：m·x'' + c·x' + k·x = 0
//   m = 质量，k = 刚度，c = 阻尼
//
// 无阻尼固有角频率：ω₀ = √(k/m)  → k↑ 或 m↓ 都会让振荡更快（更“硬”、更轻）
// 阻尼比：ζ = c / (2√(mk))
//   ζ < 1 欠阻尼：过冲、振荡（Q 弹、点赞感）
//   ζ = 1 临界阻尼：最快无振荡回到目标
//   ζ > 1 过阻尼： sluggish，像糖浆
//
// SwiftUI `.interpolatingSpring(mass:stiffness:damping:)` 直接暴露 m,k,c，
// 视觉直觉：刚度大 = 更“绷”、周期短；阻尼小 = 晃得久；质量大 = 惯性大、回弹慢。
//
// `.spring(response:dampingFraction:)` 是另一套参数化：response≈2π/ω（时间尺度），
// dampingFraction 对应 ζ 的体感（0~1 欠阻尼→临界）。二者可由设计目标互推。
//
// 【2】PhaseAnimator 状态流转
//
// `PhaseAnimator(phases:trigger:content:animation:)`：
//   - `phases`：有序相位数组，动画按序从 phase[i] → phase[i+1]。
//   - `trigger` 变化时：从 phases.first 重新跑完全程（可用来实现「每次点击一套连招」）。
//   - `animation:` 闭包按**目标相位**返回 Transaction/Animation，故每一段的曲线可不同
//     （例如第一段大弹性、第二段快速压扁、第三段柔和归位）。
//   - 与 `animation` 修饰符栈的区别：PhaseAnimator 把「多段动画」声明为数据（phases），
//     状态机清晰，避免嵌套 withAnimation 与相对时间心智负担。
//
// 【3】SwiftUI 如何扛住高频动画（性能要点）
//
//   - 属性图（AttributeGraph）做依赖追踪：仅当驱动动画的 @State 变化时，标记脏节点；
//     布局/显示列表尽量增量更新，而非整树重算。
//   - 动画在渲染进程通过插值与显示链路合成；许多情况下用 CALayer 做 transform/opacity，
//     不触发完整重绘位图（具体由系统按视图类型优化）。
//   - `drawingGroup()` / Metal 路径适合粒子，但普通矢量 SF Symbol + transform 已很轻。
//   - 避免在 `body` 里做重计算；抛物线系数可缓存。尽量减少无关 @State 抖动。
//
// ═══════════════════════════════════════════════════════════════════════════

// MARK: - Root

struct AnimationShowcaseRoot: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("❤️ 点赞 · 多段弹性（PhaseAnimator）") {
                    LikeMultiSpringDemo()
                }
                NavigationLink("🪙 金币 · 掉落反弹（interpolatingSpring）") {
                    CoinBounceDemo()
                }
                NavigationLink("💓 心跳 · 呼吸灯") {
                    HeartbeatBreathingDemo()
                }
                NavigationLink("🛒 加入购物车 · 抛物线 + Q 弹") {
                    AddToCartParabolaDemo()
                }
                NavigationLink("⚠️ UIKit Keyframes「屎山」对照") {
                    KeyframesVsSwiftUISplitDemo()
                }
                NavigationLink("📊 Charts · 折线/柱/扇区 + 手势与无障碍") {
                    ChartVisualizationDemo()
                }
                Section {
                    TheoryNotesExpandable()
                } header: {
                    Text("笔记")
                }
            }
            .navigationTitle("动画探针")
        }
    }
}

// MARK: - 理论笔记（可折叠）

private struct TheoryNotesExpandable: View {
    @State private var open = false

    var body: some View {
        DisclosureGroup("弹簧 / PhaseAnimator / 性能（摘要）", isExpanded: $open) {
            Text(theoryText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
        }
    }

    private var theoryText: String {
        """
        弹簧：ω₀=√(k/m)，ζ=c/(2√(mk))。欠阻尼→过冲振荡；SwiftUI 的 interpolatingSpring 直接调 m,k,c。

        PhaseAnimator：trigger 触发后按 phases 顺序过渡，每段可指定不同 animation，等价于结构化状态机。

        性能：AttributeGraph 增量更新；transform/opacity 常走合成层；body 保持轻量。
        """
    }
}

// MARK: - 点赞多段弹性

private enum LikePhase: CaseIterable, Equatable {
    case neutral, blowUp, shrink, settle

    var scale: CGFloat {
        switch self {
        case .neutral: return 1.0
        case .blowUp: return 1.45
        case .shrink: return 0.88
        case .settle: return 1.0
        }
    }
}

private struct LikeMultiSpringDemo: View {
    @State private var burst = 0
    @State private var liked = false

    var body: some View {
        VStack(spacing: 28) {
            Text("四段相位：原大 → 鼓起 → 轻压 → 归位。每段不同 spring。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            PhaseAnimator(LikePhase.allCases, trigger: burst) { phase in
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

// MARK: - 金币掉落（显式 m, k, c）

private struct CoinBounceDemo: View {
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

// MARK: - 心跳呼吸灯

private struct HeartbeatBreathingDemo: View {
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

// MARK: - 抛物线 + 购物车 Q 弹（SwiftUI 写法）

private struct AddToCartParabolaContent: View {
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

private struct AddToCartParabolaDemo: View {
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

// MARK: - UIKit Keyframes 屎山 vs SwiftUI

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

private struct KeyframesVsSwiftUISplitDemo: View {
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

// MARK: - Preview

#Preview {
    AnimationShowcaseRoot()
}
