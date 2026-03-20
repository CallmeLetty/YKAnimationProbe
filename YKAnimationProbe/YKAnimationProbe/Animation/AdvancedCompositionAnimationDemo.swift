//
//  AdvancedCompositionAnimationDemo.swift
//  YKAnimationProbe
//
//  组合运用：matchedGeometryEffect、Transaction、PhaseAnimator（iOS 17+）、
//  自定义 AnyTransition、手势驱动动画，搭建复杂且流畅的界面。
//
//  MARK: ─── 概念速查 ─────────────────────────────────────────────────────────
//
//  【matchedGeometryEffect】
//  - 同一 `Namespace.ID` 下，两处视图在布局变化时由系统插值 frame/cornerRadius 等，形成「共享元素」过渡。
//  - 同一时刻每个 id 通常只保留**一个**主要源；展开详情时常把列表里对应 cell 从树中移除（或用 isSource），
//    避免双源冲突。
//  - 必须配合 `withAnimation` / 动画 Transaction，否则只会「跳变」。
//
//  【Transaction】
//  - `Animation` 修饰符本质是往当前 Transaction 写曲线；子树继承该 Transaction。
//  - `withTransaction { }` 可局部覆盖：例如 `animation = nil` 让某次状态更新**不参与**动画；
//    或 `disablesAnimations = true` 整段关掉隐式动画。
//  - `.transaction { t in ... }` 在 View 上拦截下游，适合「父级 withAnimation，但某一枝要走不同曲线」。
//
//  【PhaseAnimator】（iOS 17+）
//  - 把多段动画建模为 `phases` 数组 + `trigger`；每段 `animation:` 可返回不同 Spring/Timing。
//  - 适合步骤清晰的 UI 序列（工具栏逐项出现、成功勾选连招），比手写链式 `DispatchQueue` 可读。
//
//  【自定义转场】
//  - `AnyTransition` = insertion + removal 的 ViewModifier；`asymmetric` 不对称进出场。
//  - 与 `transition(_:)`、`animation` 一起作用于条件视图的插入删除（`if`、`Group`）。
//
//  【手势驱动】
//  - `onChanged` 里直接写 `@State`（通常不包动画）实现跟手；`onEnded` 里 `withAnimation` 吸附、回弹。
//  - `@GestureState` 适合松手即自动复位的手势偏移；持久偏移用 `@State`。
//
//  MARK: ───────────────────────────────────────────────────────────────────────

import SwiftUI

// MARK: - Root（滚动浏览各小节）

struct AdvancedCompositionAnimationDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                introCard

                sectionHeader("1 · matchedGeometryEffect", subtitle: "网格 → 详情共享元素")
                MatchedGeometryHeroSection()

                sectionHeader("2 · Transaction", subtitle: "同一次状态更新，子树不同动画/无动画")
                TransactionContrastSection()

                sectionHeader("3 · PhaseAnimator", subtitle: "多段相位 + 每段不同曲线")
                PhaseAnimatorToolbarSection()

                sectionHeader("4 · 自定义转场", subtitle: "asymmetric 进出场")
                CustomTransitionToastSection()

                sectionHeader("5 · 手势驱动", subtitle: "跟手拖动 + 松手弹簧吸附")
                GestureDrivenCardSection()

                sectionHeader("6 · 小综合", subtitle: "展开卡片 + 相位工具栏 + 拖动手势")
                ComposedCardSection()
            }
            .padding()
        }
        .navigationTitle("高级组合动画")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("如何用这些 API 做复杂界面")
                .font(.headline)
            Text(
                "把「几何匹配」负责空间连续性，Transaction 控制哪些子树参与动画，PhaseAnimator 管时间线上的多拍，转场管显隐，手势把交互变成连续量。下面每节可独立理解，最后一节拼在一起。"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(.blue.opacity(0.08)))
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - 1. Matched geometry

private struct MatchedGeometryHeroSection: View {
    @Namespace private var heroNS
    @State private var expandedID: Int?

    private let tiles: [(Int, Color)] = [
        (0, .orange),
        (1, .purple),
        (2, .green),
        (3, .cyan)
    ]

    var body: some View {
        ZStack {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(tiles, id: \.0) { id, gradient in
                    if expandedID != id {
                        tile(id: id, color: gradient, compact: true)
                            .matchedGeometryEffect(id: id, in: heroNS)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                    expandedID = id
                                }
                            }
                    } else {
                        Color.clear.frame(height: 100)
                    }
                }
            }

            if let id = expandedID, let color = tiles.first(where: { $0.0 == id })?.1 {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                            expandedID = nil
                        }
                    }

                tile(id: id, color: color, compact: false)
                    .matchedGeometryEffect(id: id, in: heroNS)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                            expandedID = nil
                        }
                    }
            }
        }
        .frame(minHeight: expandedID == nil ? 220 : 320)
    }

    private func tile(id: Int, color: Color, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("卡片 \(id + 1)")
                .font(compact ? .subheadline.weight(.semibold) : .title2.weight(.bold))
            Text(compact ? "点击展开" : "点击或背景关闭")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !compact {
                Spacer(minLength: 0)
                Label("共享 Namespace 与 id", systemImage: "link")
                    .font(.caption)
            }
        }
        .padding(compact ? 12 : 20)
        .frame(maxWidth: .infinity, minHeight: compact ? 100 : 220, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: compact ? 14 : 22).fill(color.gradient.opacity(0.35)))
        .overlay(RoundedRectangle(cornerRadius: compact ? 14 : 22).stroke(.white.opacity(0.25)))
    }
}

// MARK: - 2. Transaction

private struct TransactionContrastSection: View {
    @State private var highlight = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(highlight ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: highlight)

                VStack(alignment: .leading) {
                    Text("左侧：默认继承父级动画")
                        .font(.caption)
                    Text("右侧：transaction 关掉动画")
                        .font(.caption)
                }
            }

            HStack(spacing: 16) {
                Button("withAnimation（整块弹）") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                        highlight.toggle()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("withTransaction 无动画") {
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        highlight.toggle()
                    }
                }
                .buttonStyle(.bordered)
            }

            Text("父级若 `withAnimation`，仍可用 `.transaction { $0.animation = .linear(duration: 0.15) }` 在子视图上改曲线。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(.secondary.opacity(0.06)))
    }
}

// MARK: - 3. PhaseAnimator（工具栏逐项）

private enum ToolbarPhase: CaseIterable, Equatable {
    case hidden, share, favorite, more

    var shareOpacity: Double {
        switch self {
        case .hidden: return 0
        default: return 1
        }
    }

    var favoriteOpacity: Double {
        switch self {
        case .hidden, .share: return 0
        default: return 1
        }
    }

    var moreOpacity: Double {
        switch self {
        case .more: return 1
        default: return 0
        }
    }

    var barOffset: CGFloat {
        self == .hidden ? 24 : 0
    }
}

private struct PhaseAnimatorToolbarSection: View {
    @State private var pulse = 0

    var body: some View {
        VStack(spacing: 12) {
            Text("点按钮：hidden → share → favorite → more，每段不同 spring")
                .font(.caption)
                .foregroundStyle(.secondary)

            PhaseAnimator(ToolbarPhase.allCases, trigger: pulse) { phase in
                HStack(spacing: 18) {
                    Image(systemName: "square.and.arrow.up")
                        .opacity(phase.shareOpacity)
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .opacity(phase.favoriteOpacity)
                    Image(systemName: "ellipsis.circle")
                        .opacity(phase.moreOpacity)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .offset(y: phase.barOffset)
            } animation: { phase in
                switch phase {
                case .hidden:
                    return .easeOut(duration: 0.2)
                case .share:
                    return .spring(response: 0.32, dampingFraction: 0.72)
                case .favorite:
                    return .spring(response: 0.28, dampingFraction: 0.62)
                case .more:
                    return .spring(response: 0.38, dampingFraction: 0.78)
                }
            }

            Button("跑一遍工具栏相位") {
                pulse += 1
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(.indigo.opacity(0.06)))
    }
}

// MARK: - 4. Custom transition

private extension AnyTransition {
    static var ykToastSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .scale(scale: 0.92).combined(with: .opacity)
        )
    }
}

private struct CustomTransitionToastSection: View {
    @State private var showToast = false

    var body: some View {
        VStack(spacing: 12) {
            if showToast {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("自定义 asymmetric 转场")
                        .font(.subheadline.weight(.medium))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(.green.opacity(0.12)))
                .transition(.ykToastSlide)
            }

            Button(showToast ? "隐藏" : "显示 Toast") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    showToast.toggle()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(.green.opacity(0.05)))
    }
}

// MARK: - 5. Gesture-driven

private struct GestureDrivenCardSection: View {
    @State private var dragY: CGFloat = 0

    private let snapThreshold: CGFloat = 80

    var body: some View {
        VStack {
            Text("竖直拖动，超过阈值松手下移消失，否则弹簧回位")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: [.pink.opacity(0.6), .orange.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(height: 120)
                .overlay(Text("拖我").font(.headline))
                .offset(y: dragY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragY = max(0, value.translation.height)
                        }
                        .onEnded { value in
                            if value.translation.height > snapThreshold {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    dragY = 400
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    dragY = 0
                                }
                            } else {
                                withAnimation(.interpolatingSpring(stiffness: 280, damping: 22)) {
                                    dragY = 0
                                }
                            }
                        }
                )
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(.pink.opacity(0.06)))
    }
}

// MARK: - 6. Composed（综合）

private struct ComposedCardSection: View {
    @Namespace private var ns
    @State private var open = false
    @State private var toolbarPulse = 0
    @State private var dragY: CGFloat = 0

    var body: some View {
        ZStack {
            if !open {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.teal.gradient.opacity(0.4))
                    .frame(height: 88)
                    .overlay(alignment: .leading) {
                        HStack {
                            Image(systemName: "rectangle.expand.vertical")
                            Text("展开综合卡片")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, 16)
                    }
                    .matchedGeometryEffect(id: "composed", in: ns)
                    .onTapGesture {
                        dragY = 0
                        toolbarPulse += 1
                        withAnimation(.spring(response: 0.48, dampingFraction: 0.84)) {
                            open = true
                        }
                    }
            }

            if open {
                VStack(spacing: 0) {
                    PhaseAnimator(ToolbarPhase.allCases, trigger: toolbarPulse) { phase in
                        HStack(spacing: 14) {
                            Image(systemName: "square.and.arrow.up").opacity(phase.shareOpacity)
                            Image(systemName: "star.fill").opacity(phase.favoriteOpacity).foregroundStyle(.yellow)
                            Image(systemName: "ellipsis.circle").opacity(phase.moreOpacity)
                        }
                        .font(.title3)
                        .padding(.vertical, 8)
                    } animation: { phase in
                        switch phase {
                        case .hidden: return .easeOut(duration: 0.15)
                        case .share: return .spring(response: 0.3, dampingFraction: 0.7)
                        case .favorite: return .spring(response: 0.26, dampingFraction: 0.62)
                        case .more: return .spring(response: 0.34, dampingFraction: 0.75)
                        }
                    }
                    .padding(.bottom, 8)

                    RoundedRectangle(cornerRadius: 18)
                        .fill(.teal.gradient.opacity(0.35))
                        .frame(height: 160)
                        .overlay {
                            VStack(spacing: 8) {
                                Text("matchedGeometry + PhaseAnimator + 下拉")
                                    .font(.caption.weight(.semibold))
                                Text("下拉关闭（无动画位移用 transaction 仅作用于拖动）")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                        .matchedGeometryEffect(id: "composed", in: ns)
                        .offset(y: dragY)
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    var t = Transaction()
                                    t.disablesAnimations = true
                                    withTransaction(t) {
                                        dragY = max(0, v.translation.height)
                                    }
                                }
                                .onEnded { v in
                                    if v.translation.height > 70 {
                                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                                            open = false
                                            dragY = 0
                                        }
                                    } else {
                                        withAnimation(.interpolatingSpring(stiffness: 320, damping: 24)) {
                                            dragY = 0
                                        }
                                    }
                                }
                        )
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(minHeight: open ? 260 : 100)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdvancedCompositionAnimationDemo()
    }
}
