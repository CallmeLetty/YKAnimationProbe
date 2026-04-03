//
//  ChartVisualizationDemo.swift
//  YKAnimationProbe
//
//  SwiftUI Charts：折线 / 柱状 / 扇形、手势与动画、大数据降采样、无障碍说明
//

import Accessibility
import Charts
import SwiftUI

// MARK: - ═══════════════════════════════════════════════════════════════════
// MARK: 理论深挖（Chart API · 手势 · 性能 · 无障碍）
// MARK: ═══════════════════════════════════════════════════════════════════
//
// 【1】Chart API 高级与自定义
//
//   - `LineMark` + `AreaMark` 叠层、`interpolationMethod`（linear / catmullRom / stepStart）
//   - `BarMark`、`SectorMark`（环形饼图用 innerRadius）、`RuleMark` 参考线
//   - `chartForegroundStyleScale`、`chartSymbolScale` 统一配色与图例
//   - `AxisMarks`、`AxisGridLine`、`AxisValueLabel` 自定义刻度与格式
//   - `chartPlotStyle` 控制绘图区背景；`chartXScale` / `chartYScale` 动态 domain
//
// 【2】手势 + 动画
//
//   - `chartXSelection`、`chartYSelection`、`chartAngleSelection`：绑定可选值，随拖移高亮
//   - 与 `withAnimation` 配合可动画化 domain 或选中态；`animation(.easeInOut)` 作用于数据变化
//   - 外层可再包 `DragGesture` / `MagnificationGesture` 做缩放平移（需同步改 scale domain）
//
// 【3】大量数据时的渲染
//
//   - 点数过多时优先「降采样」：等距抽样、分桶平均/最大最小包络，避免上万 Mark 同屏
//   - 仅需概览时用 `stride` 或 LTTB 类算法；细节用 drill-down 另页全量
//   - 动画开启时减少同时变化的系列数；必要时 `drawingGroup()` 慎用（位图缓存代价）
//
// 【4】无障碍（视力障碍与旁白）
//
//   - 图表旁提供「文字摘要」：`accessibilitySummary` 或独立 `Text` + `accessibilityAddTraits(.isSummaryElement)`
//   - iOS 17+：`accessibilityChartDescriptor` 把序列转为 VoiceOver 可浏览的数据表
//   - 每个可交互段：`accessibilityLabel` + `accessibilityValue`；勿仅用颜色区分信息（配图案/说明）
//
// ═══════════════════════════════════════════════════════════════════════════

// MARK: - 数据模型（天气 / 健康 / App 使用）

private struct WeatherSample: Identifiable {
    var id: Date { date }
    let day: String
    let date: Date
    let highC: Double
    let lowC: Double
    let humidity: Double
}

private struct HourlyHealth: Identifiable {
    let id = UUID()
    let hour: Int
    let steps: Int
    let heartRateAvg: Int
}

private struct AppUsageSlice: Identifiable {
    let id = UUID()
    let name: String
    let minutes: Double
    let symbol: String
}

private struct HourlyScreenRow: Identifiable {
    let id: Int
    var hour: Int { id }
    let minutes: Int
}

// MARK: - 入口（从列表导航）

struct ChartVisualizationDemo: View {
    @State private var selectedWeatherDate: Date?
    @State private var weatherReveal: CGFloat = 1
    @State private var weatherReplayTask: Task<Void, Never>?
    @State private var selectedHour: Int?
    @State private var selectedAppCategory: String?
    @State private var piePulse = false
    @State private var piePulseTask: Task<Void, Never>?
    @State private var useDownsample = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                chartTheoryCard()

                weatherLineSection()
                appBarSection()
                appPieSection()
                largeDataSection()
                a11ySection()
            }
            .padding()
        }
        .navigationTitle("Charts 可视化")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if weatherReveal == 1 {
                replayWeatherAnimation()
            }
        }
        .onDisappear {
            weatherReplayTask?.cancel()
            piePulseTask?.cancel()
        }
    }

    // MARK: 天气：折线 + 区域 + 横向选中

    @ViewBuilder
    private func weatherLineSection() -> some View {
        let samples = Self.weatherWeekData()
        VStack(alignment: .leading, spacing: 8) {
            Label("一周气温（折线 + 区域）", systemImage: "cloud.sun.fill")
                .font(.headline)
            Text("横向拖动可选中某日，查看高低温与湿度。")
                .font(.caption)
                .foregroundStyle(.secondary)

            let avgHigh = samples.map(\.highC).reduce(0, +) / Double(max(samples.count, 1))
            GeometryReader { proxy in
                Chart {
                    RuleMark(y: .value("均高", avgHigh))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("周均高 \(Int(avgHigh))°")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    ForEach(samples) { s in
                        AreaMark(
                            x: .value("日", s.date),
                            y: .value("最高", s.highC)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange.opacity(0.45), .orange.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("日", s.date),
                            y: .value("最高", s.highC)
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)
                        .symbol(.circle)
                        .symbolSize(selectedWeatherDate.map { Calendar.current.isDate($0, inSameDayAs: s.date) ? 120 : 40 } ?? 40)

                        LineMark(
                            x: .value("日", s.date),
                            y: .value("最低", s.lowC)
                        )
                        .foregroundStyle(.cyan)
                        .interpolationMethod(.catmullRom)
                    }
                }
                // 遮罩宽度随状态增长，做出真正的“从左到右重绘”。
                .mask(alignment: .leading) {
                    Rectangle()
                        .frame(width: max(1, proxy.size.width * weatherReveal))
                }
                .chartXSelection(value: $selectedWeatherDate)
                .chartXAxis {
                    AxisMarks(values: samples.map(\.date)) { val in
                        if let d = val.as(Date.self) {
                            AxisValueLabel {
                                Text(d, format: .dateTime.weekday(.narrow))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { v in
                        AxisGridLine()
                        AxisValueLabel {
                            if let n = v.as(Double.self) {
                                Text("\(Int(n))°")
                            }
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "最高": Color.orange,
                    "最低": Color.cyan
                ])
                .accessibilityLabel("一周气温趋势图")
                .accessibilityHint("左右滑动可选中某一天")
            }
            .frame(height: 220)

            if let d = selectedWeatherDate,
               let hit = samples.first(where: { Calendar.current.isDate($0.date, inSameDayAs: d) }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(hit.day).font(.subheadline.weight(.semibold))
                        Text("高 \(Int(hit.highC))° / 低 \(Int(hit.lowC))° · 湿度 \(Int(hit.humidity))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button("重播线条动画") {
                replayWeatherAnimation()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: App 使用：柱状 + 选中动画

    @ViewBuilder
    private func appBarSection() -> some View {
        let hours = Self.hourlyAppLikeData()
        VStack(alignment: .leading, spacing: 8) {
            Label("屏幕时间分布（柱状）", systemImage: "chart.bar.fill")
                .font(.headline)
            Text("点按或拖动选择小时，柱形会高亮。")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(hours) { h in
                BarMark(
                    x: .value("时", h.hour),
                    y: .value("分钟", h.minutes)
                )
                .foregroundStyle(by: .value("时段", hourLabel(h.hour)))
                .cornerRadius(4)
                .opacity(selectedHour.map { $0 == h.hour ? 1 : 0.35 } ?? 1)
            }
            .frame(height: 200)
            .chartXSelection(value: $selectedHour)
            .chartXScale(domain: 0...23)
            .chartYAxis { AxisMarks(position: .leading) }
            .chartLegend(position: .bottom, spacing: 8)
            .animation(.easeInOut(duration: 0.25), value: selectedHour)
            .accessibilityLabel("按小时的 App 使用分钟数")

            if let h = selectedHour, let row = hours.first(where: { $0.hour == h }) {
                Text("\(h) 点：约 \(row.minutes) 分钟")
                    .font(.caption.monospacedDigit())
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: 饼图 / 扇区 + 角度选中

    @ViewBuilder
    private func appPieSection() -> some View {
        let slices = Self.appCategorySlices()
        let totalMin = slices.reduce(0.0) { $0 + $1.minutes }
        VStack(alignment: .leading, spacing: 8) {
            Label("应用类别占比（扇形）", systemImage: "chart.pie.fill")
                .font(.headline)

            Chart(slices) { s in
                SectorMark(
                    angle: .value("分钟", s.minutes),
                    innerRadius: .ratio(0.52),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("应用", s.name))
                .opacity(selectedAppCategory.map { $0 == s.name ? 1 : 0.45 } ?? 1)
                .annotation(position: .overlay) {
                    if totalMin > 0, s.minutes / totalMin > 0.12 {
                        Text(s.symbol)
                            .font(.title3)
                    }
                }
            }
            .frame(height: 260)
            .chartAngleSelection(value: $selectedAppCategory)
            .chartLegend(position: .bottom)
            .scaleEffect(piePulse ? 1.03 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: piePulse)
            .onChange(of: selectedAppCategory) { _, new in
                piePulseTask?.cancel()
                piePulse = new != nil
                guard new != nil else { return }

                piePulseTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(180))
                    piePulse = false
                }
            }
            .accessibilityLabel("应用类别使用时长占比")

            if let name = selectedAppCategory, let sl = slices.first(where: { $0.name == name }) {
                Text("\(sl.symbol) \(name)：\(Int(sl.minutes)) 分钟")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: 大数据：降采样对比
    private static let rawSeriesLength = 4_000

    @ViewBuilder
    private func largeDataSection() -> some View {
        let raw = Self.syntheticNoisySeries(count: Self.rawSeriesLength)
        let display: [(Int, Double)] = useDownsample
            ? Self.bucketAverage(series: raw, maxBuckets: 320)
            : raw.enumerated().map { ($0.offset, $0.element) }

        VStack(alignment: .leading, spacing: 8) {
            Label("大量数据（性能）", systemImage: "waveform.path.ecg")
                .font(.headline)
            Text("原始 \(Self.rawSeriesLength) 点 vs 分桶平均至 \(display.count) 点。生产环境可换 LTTB 等算法保留峰值。")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("启用降采样（推荐）", isOn: $useDownsample)
                .accessibilityHint("关闭后渲染全部数据点，可能掉帧")

            Chart {
                ForEach(Array(display.enumerated()), id: \.offset) { _, pair in
                    LineMark(
                        x: .value("序", pair.0),
                        y: .value("值", pair.1)
                    )
                    .foregroundStyle(.indigo)
                }
            }
            .frame(height: 160)
            .chartYScale(domain: .automatic(includesZero: true))
            .accessibilityLabel("合成时序数据，展示降采样效果")
            .accessibilityValue(useDownsample ? "降采样，\(display.count) 点" : "全量 \(raw.count) 点")

            Text("点数：\(display.count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: 无障碍示例

    @ViewBuilder
    private func a11ySection() -> some View {
        let health = Self.hourlyStepsData()
        VStack(alignment: .leading, spacing: 8) {
            Label("无障碍设计", systemImage: "accessibility")
                .font(.headline)
            Text(healthA11ySummary(health))
                .font(.subheadline)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("图表文字摘要")
                .accessibilityAddTraits(.isSummaryElement)

            Chart(health) { h in
                BarMark(
                    x: .value("时", h.hour),
                    y: .value("步数", h.steps)
                )
                .foregroundStyle(.green.gradient)
                .accessibilityLabel("\(h.hour) 点")
                .accessibilityValue("\(h.steps) 步，平均心率约 \(h.heartRateAvg)")
            }
            .frame(height: 180)
            .chartXScale(domain: 6...22)
            .accessibilityChartDescriptor(
                HourlyStepsChartAccessibility(health: health, summary: healthA11ySummary(health))
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func chartTheoryCard() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("本页涵盖")
                .font(.caption.weight(.semibold))
            Text("Chart 自定义 · 选中手势 · 动画 · 降采样 · VoiceOver 摘要与 AXChartDescriptor")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func replayWeatherAnimation() {
        weatherReplayTask?.cancel()
        weatherReveal = 0

        weatherReplayTask = Task { @MainActor in
            await Task.yield()
            withAnimation(.easeOut(duration: 0.9)) {
                weatherReveal = 1
            }
        }
    }

    // MARK: - 静态数据与工具

    private static func weatherWeekData() -> [WeatherSample] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        let highs = [22.0, 24.0, 21.0, 19.0, 23.0, 26.0, 25.0]
        let lows = [14.0, 15.0, 13.0, 12.0, 14.0, 17.0, 16.0]
        let hum = [65.0, 58.0, 72.0, 80.0, 62.0, 55.0, 60.0]
        return (0..<7).map { i in
            WeatherSample(
                day: days[i],
                date: cal.date(byAdding: .day, value: i - 6, to: today)!,
                highC: highs[i],
                lowC: lows[i],
                humidity: hum[i]
            )
        }
    }

    private static func hourlyAppLikeData() -> [HourlyScreenRow] {
        let base = [2, 1, 1, 1, 2, 8, 25, 35, 28, 22, 18, 25, 30, 20, 18, 22, 28, 35, 42, 38, 25, 15, 8, 4]
        return (0..<24).map { HourlyScreenRow(id: $0, minutes: base[$0]) }
    }

    private static func appCategorySlices() -> [AppUsageSlice] {
        [
            AppUsageSlice(name: "社交", minutes: 95, symbol: "💬"),
            AppUsageSlice(name: "视频", minutes: 72, symbol: "▶️"),
            AppUsageSlice(name: "效率", minutes: 38, symbol: "📋"),
            AppUsageSlice(name: "游戏", minutes: 45, symbol: "🎮"),
            AppUsageSlice(name: "其他", minutes: 28, symbol: "⋯")
        ]
    }

    private static func hourlyStepsData() -> [HourlyHealth] {
        let steps = [0, 0, 0, 0, 120, 450, 1200, 2100, 800, 600, 500, 700, 400, 350, 600, 900, 1500, 2200, 1800, 900, 400, 200, 50, 0]
        let hr = [58, 56, 55, 54, 62, 72, 78, 85, 80, 76, 74, 73, 75, 72, 78, 82, 88, 92, 85, 78, 72, 68, 62, 60]
        return (0..<24).map { HourlyHealth(hour: $0, steps: steps[$0], heartRateAvg: hr[$0]) }
    }

    private static func syntheticNoisySeries(count: Int) -> [Double] {
        (0..<count).map { i in
            let t = Double(i) * 0.02
            return sin(t) * 12 + sin(t * 3.1) * 4 + Double(i % 17) * 0.08
        }
    }

    /// 分桶平均：适合折线图概览，比纯 stride 更平滑
    private static func bucketAverage(series: [Double], maxBuckets: Int) -> [(Int, Double)] {
        guard series.count > maxBuckets else {
            return series.enumerated().map { ($0.offset, $0.element) }
        }
        let bucketSize = max(1, series.count / maxBuckets)
        var out: [(Int, Double)] = []
        out.reserveCapacity(maxBuckets)
        var start = 0
        while start < series.count {
            let end = min(start + bucketSize, series.count)
            let slice = series[start..<end]
            let avg = slice.reduce(0, +) / Double(slice.count)
            out.append((start + (end - start) / 2, avg))
            start = end
        }
        return out
    }

    private func hourLabel(_ h: Int) -> String {
        switch h {
        case 0..<6: return "深夜"
        case 6..<12: return "上午"
        case 12..<18: return "下午"
        default: return "晚间"
        }
    }

    private func healthA11ySummary(_ health: [HourlyHealth]) -> String {
        let total = health.reduce(0) { $0 + $1.steps }
        let peak = health.max(by: { $0.steps < $1.steps })
        if let p = peak {
            return "今日累计步行约 \(total) 步。步数高峰在 \(p.hour) 点，约 \(p.steps) 步。"
        }
        return "今日步数数据。"
    }
}

// MARK: - VoiceOver：AXChartDescriptorRepresentable

private struct HourlyStepsChartAccessibility: AXChartDescriptorRepresentable {
    let health: [HourlyHealth]
    let summary: String

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXNumericDataAxisDescriptor(
            title: "小时",
            range: 0...23,
            gridlinePositions: health.map { Double($0.hour) },
            valueDescriptionProvider: { "\(Int($0))点" }
        )
        let maxSteps = max(health.map(\.steps).max() ?? 1, 1)
        let yAxis = AXNumericDataAxisDescriptor(
            title: "步数",
            range: 0...Double(maxSteps * 11 / 10 + 1),
            gridlinePositions: [],
            valueDescriptionProvider: { "\(Int($0))步" }
        )
        let points = health.map { h in
            AXDataPoint(
                x: Double(h.hour),
                y: Double(h.steps),
                label: "\(h.hour)时，\(h.steps)步，心率约\(h.heartRateAvg)"
            )
        }
        let series = AXDataSeriesDescriptor(
            name: "步数",
            isContinuous: false,
            dataPoints: points
        )
        return AXChartDescriptor(
            title: "今日步数按小时",
            summary: summary,
            xAxis: xAxis,
            yAxis: yAxis,
            series: [series]
        )
    }
}
