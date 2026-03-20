//
//  ThirdTabWaterfallDemo.swift
//  YKAnimationProbe
//
//  Created by Yakamoz on 2026/3/19.
//

import SwiftUI
import SmoothGradientUIKit

struct ThirdTabWaterfallDemo: View {
    private let columnGap: CGFloat = 12

    // 预计算：避免每次 body 刷新都重新生成随机数据
    private let items: [WaterfallItem] = Self.makeItems()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: columnGap) {
                    Waterfall2ColLayout(items: items, gap: columnGap)
                        .padding(.top, 4)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Smooth 瀑布流")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - SmoothGradient 水平分布瀑布流 Demo

private struct WaterfallItem: Identifiable {
    let id = UUID()
    let title: String
    let height: CGFloat

    // SmoothGradient 配置需要 UIColor 数组
    let colors: [UIColor]
    let directionAngle: CGFloat
    let altDirectionAngle: CGFloat
    let baseSteps: Int
}

private extension ThirdTabWaterfallDemo {
    static func makeItems() -> [WaterfallItem] {
        // 稳定的“伪随机”：用索引生成高度与配色，不依赖系统随机源
        let palettes: [[UIColor]] = [
            [UIColor(hex: 0xFF6B6B), UIColor(hex: 0xFFD93D), UIColor(hex: 0x6BCB77)],
            [UIColor(hex: 0x4D96FF), UIColor(hex: 0x7CFFCB), UIColor(hex: 0xEED2FF)],
            [UIColor(hex: 0xFF9F1C), UIColor(hex: 0x2EC4B6), UIColor(hex: 0xE71D36)],
            [UIColor(hex: 0x845EC2), UIColor(hex: 0x00C9A7), UIColor(hex: 0xF9F871)],
            [UIColor(hex: 0x00BBF9), UIColor(hex: 0xF15BB5), UIColor(hex: 0xFEE440)],
        ]

        let titles = [
            "平滑渐变 A",
            "平滑渐变 B",
            "平滑渐变 C",
            "平滑渐变 D",
            "平滑渐变 E",
            "平滑渐变 F",
            "平滑渐变 G",
            "平滑渐变 H",
        ]

        let totalCount: Int = 30
        
        let angleInt: Int = (1 * 23) % 360
        let altAngleInt: Int = (angleInt + 65 + (1 % 11) * 3) % 360
        let angle: CGFloat = CGFloat(angleInt)
        let altAngle: CGFloat = CGFloat(altAngleInt)
        
        let first = WaterfallItem(
            title: "测试",
            height: 200,
            colors: [.white.withAlphaComponent(0), .white.withAlphaComponent(0.5), .white.withAlphaComponent(1)],
            directionAngle: angle,
            altDirectionAngle: altAngle,
            baseSteps: 11
        )
        var result: [WaterfallItem] = [first]
        result.reserveCapacity(totalCount)

        for i in 0..<totalCount {
            let palette: [UIColor] = palettes[i % palettes.count]
            let h: CGFloat = CGFloat(140 + ((i * 37) % 150)) // 140...289

            // directionAngle: 0...359，altDirectionAngle: 互补角附近
            let angleInt: Int = (i * 23) % 360
            let altAngleInt: Int = (angleInt + 65 + (i % 11) * 3) % 360
            let angle: CGFloat = CGFloat(angleInt)
            let altAngle: CGFloat = CGFloat(altAngleInt)

            // steps: 用 10~24 之间的变化演示“平滑采样”
            let steps: Int = 10 + (i % 15)

            result.append(
                WaterfallItem(
                    title: titles[i % titles.count],
                    height: h,
                    colors: palette,
                    directionAngle: angle,
                    altDirectionAngle: altAngle,
                    baseSteps: steps
                )
            )
        }

        return result
    }
}

private struct Waterfall2ColLayout: View {
    let items: [WaterfallItem]
    let gap: CGFloat

    var body: some View {
        let columns = Self.assignGreedy(items: items, columns: 2)
        HStack(alignment: .top, spacing: gap) {
            LazyVStack(spacing: gap) {
                ForEach(columns[0]) { item in
                    WaterfallCell(item: item, widthFilling: true)
                }
            }
            LazyVStack(spacing: gap) {
                ForEach(columns[1]) { item in
                    WaterfallCell(item: item, widthFilling: true)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    /// 贪心分配：把当前“累计高度最小”的列放入新 item，近似瀑布流效果
    private static func assignGreedy(items: [WaterfallItem], columns: Int) -> [[WaterfallItem]] {
        var result = Array(repeating: [WaterfallItem](), count: columns)
        var heights = Array(repeating: CGFloat.zero, count: columns)

        for item in items {
            let idx = heights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            result[idx].append(item)
            heights[idx] += item.height
        }
        return result
    }
}

private struct WaterfallCell: View {
    let item: WaterfallItem
    let widthFilling: Bool

    @State private var toggled = false

    var body: some View {
        let direction = SmoothGradientDirection(angleDegrees: toggled ? item.altDirectionAngle : item.directionAngle)
        let steps = toggled ? max(2, item.baseSteps - 3) : item.baseSteps

        // 每个 cell 都“实际调用” SmoothGradientView 的配置能力
        let config = SmoothGradientConfiguration(
            colors: item.colors,
            steps: steps,
            smoothing: .high,
            direction: direction,
            fallbackMode: .automatic
        )

        ZStack(alignment: .bottomLeading) {
            // 底色要足够“深”，否则像 first 这种带透明度的白色渐变会显得很淡
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.22))

            SmoothGradientViewRepresentable(configuration: config)
                .frame(maxWidth: widthFilling ? .infinity : nil)
                .frame(height: item.height)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("steps \(steps) / tap 切换方向")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(content: {
            Image("test_background")
        })
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { toggled.toggle() }
        .accessibilityLabel(item.title)
        
    }
}

private struct SmoothGradientViewRepresentable: UIViewRepresentable {
    let configuration: SmoothGradientConfiguration

    func makeUIView(context: Context) -> SmoothGradientView {
        SmoothGradientView(configuration: configuration)
    }

    func updateUIView(_ uiView: SmoothGradientView, context: Context) {
        uiView.setConfiguration(configuration, animated: true)
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255
        let b = CGFloat(hex & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
