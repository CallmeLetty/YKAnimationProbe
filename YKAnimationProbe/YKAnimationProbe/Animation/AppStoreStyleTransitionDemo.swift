//
//  AppStoreStyleTransitionDemo.swift
//  YKAnimationProbe
//
//  App Store 风格：首页卡片点击放大进详情，图片 / 标题 / 按钮共享元素过渡；
//  关闭时用略低阻尼的 spring，让缩回网格带一点反向过冲（回弹感）。
//

import SwiftUI

// MARK: - Model

private struct StoreItem: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let accent: Color
}

// MARK: - Demo root

struct AppStoreStyleTransitionDemo: View {
    @Namespace private var storeNS
    @State private var expanded: StoreItem?

    private let items: [StoreItem] = [
        StoreItem(id: "a", title: "极光笔记", subtitle: "写作与灵感同步", symbolName: "pencil.and.scribble", accent: .indigo),
        StoreItem(id: "b", title: "像素天气", subtitle: "每分钟更新预报", symbolName: "cloud.sun.fill", accent: .cyan),
        StoreItem(id: "c", title: "节拍实验室", subtitle: "鼓点与循环器", symbolName: "waveform", accent: .orange),
        StoreItem(id: "d", title: "正念时刻", subtitle: "呼吸与专注", symbolName: "leaf.fill", accent: .mint)
    ]

    /// 进入详情：略紧、顺滑（接近系统卡片展开）
    private var expandAnimation: Animation {
        .spring(response: 0.52, dampingFraction: 0.86)
    }

    /// 退出：稍快 + 阻尼略低 → 回到网格时有一点过冲回弹
    private var collapseAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.68)
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                    spacing: 14
                ) {
                    ForEach(items) { item in
                        if expanded?.id != item.id {
                            compactCard(item)
                                .onTapGesture {
                                    withAnimation(expandAnimation) {
                                        expanded = item
                                    }
                                }
                        } else {
                            // 占位，避免与详情页同一 id 双源
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.clear)
                                .frame(height: 200)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .allowsHitTesting(expanded == nil)

            if let item = expanded {
                detailOverlay(item: item)
                    .transition(.opacity)
            }
        }
        .navigationTitle("App Store 转场")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(expanded == nil ? .visible : .hidden, for: .navigationBar)
    }

    // MARK: Compact card（三处 matched）

    private func compactCard(_ item: StoreItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            heroImageBlock(item: item, size: 120, cornerRadius: 14)
                .matchedGeometryEffect(id: "hero-\(item.id)", in: storeNS)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .matchedGeometryEffect(id: "title-\(item.id)", in: storeNS)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 8)

            HStack {
                Spacer(minLength: 0)
                getButton(compact: true, accent: item.accent)
                    .matchedGeometryEffect(id: "cta-\(item.id)", in: storeNS)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }

    // MARK: Detail

    private func detailOverlay(item: StoreItem) -> some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(collapseAnimation) {
                        expanded = nil
                    }
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(collapseAnimation) {
                                expanded = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary, .quaternary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                    HStack {
                        Spacer(minLength: 0)
                        heroImageBlock(item: item, size: 280, cornerRadius: 22)
                            .matchedGeometryEffect(id: "hero-\(item.id)", in: storeNS)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.title.bold())
                            .matchedGeometryEffect(id: "title-\(item.id)", in: storeNS)

                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // 非共享元素：仅在详情出现，用淡入
                        Text(detailBlurb)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.top, 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    getButton(compact: false, accent: item.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                        .matchedGeometryEffect(id: "cta-\(item.id)", in: storeNS)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func heroImageBlock(item: StoreItem, size: CGFloat, cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(item.accent.gradient.opacity(0.55))
            Image(systemName: item.symbolName)
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .frame(width: size, height: size)
    }

    private func getButton(compact: Bool, accent: Color) -> some View {
        Text("获取")
            .font(compact ? .caption.weight(.bold) : .headline)
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 18 : 120)
            .padding(.vertical, compact ? 6 : 14)
            .background(
                Capsule().fill(accent.gradient)
            )
    }

    private var detailBlurb: String {
        """
        这里是不参与 matchedGeometryEffect 的说明文案，仅在详情展示。\
        共享的图像、标题与按钮会沿原轨迹插值回到网格卡片，关闭动画使用更低阻尼的 spring，缩回时略带过冲，更接近 App Store 的「弹回」手感。
        """
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppStoreStyleTransitionDemo()
    }
}
