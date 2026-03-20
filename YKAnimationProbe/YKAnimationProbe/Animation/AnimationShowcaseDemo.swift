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

// MARK: - Preview

#Preview {
    AnimationShowcaseRoot()
}
