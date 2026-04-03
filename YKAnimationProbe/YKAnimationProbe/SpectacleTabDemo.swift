//
//  SpectacleTabDemo.swift
//  YKAnimationProbe
//
//  Created by Codex on 2026/4/1.
//

import SwiftUI

struct SpectacleTabDemo: View {
    @State private var selectedScene: SpectacleScene = .aurora
    @State private var pulseTrigger = 0
    @State private var isPulseActive = false
    @State private var pulseResetTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                TimelineView(.animation(minimumInterval: 1.0 / 40.0, paused: false)) { context in
                    let time = context.date.timeIntervalSinceReferenceDate

                    ZStack {
                        AnimatedBackdrop(scene: selectedScene, time: time)
                        FloatingOrbs(scene: selectedScene, time: time)

                        VStack(spacing: 24) {
                            header
                            heroCard(time: time)
                            scenePicker
                            metricsStrip(time: time)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 28)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onDisappear {
            pulseResetTask?.cancel()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Spectacle")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("一个独立 tab，用流光、粒子、玻璃卡片和节奏化位移做出更有舞台感的动画页。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))

            HStack(spacing: 10) {
                Label("60fps 风格", systemImage: "sparkles")
                Label("多层合成", systemImage: "circle.hexagongrid.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroCard(time: TimeInterval) -> some View {
        let bob = CGFloat(sin(time * 1.1)) * 12
        let tilt = Angle.degrees(sin(time * 0.7) * 6)

        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.white.opacity(0.08))
                .background {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: selectedScene.cardColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 4)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    Capsule()
                        .fill(.white.opacity(0.14))
                        .frame(width: 112, height: 36)
                        .overlay {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(selectedScene.accent)
                                    .frame(width: 10, height: 10)
                                Text(selectedScene.badgeTitle)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(18)
                }

            VStack(alignment: .leading, spacing: 12) {
                Text(selectedScene.heroTitle)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(selectedScene.heroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button {
                        triggerPulse()
                    } label: {
                        Label("Pulse", systemImage: "bolt.fill")
                    }
                    .buttonStyle(GlassCapsuleButtonStyle())

                    Text(selectedScene.footnote)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.76))
                }
            }
            .padding(24)
        }
        .frame(height: 290)
        .rotation3DEffect(tilt, axis: (x: 1, y: 0, z: 0))
        .offset(y: bob)
        .scaleEffect(isPulseActive ? 1.03 : 1.0)
        .shadow(color: selectedScene.accent.opacity(0.28), radius: 40, y: 18)
        .overlay {
            HeroEnergyRings(accent: selectedScene.accent, pulseTrigger: pulseTrigger, isPulseActive: isPulseActive)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.62), value: isPulseActive)
    }

    private var scenePicker: some View {
        HStack(spacing: 12) {
            ForEach(SpectacleScene.allCases) { scene in
                Button {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                        selectedScene = scene
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(scene.rawValue)
                            .font(.subheadline.weight(.bold))
                        Text(scene.shortDescription)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .foregroundStyle(.white)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(scene == selectedScene ? .white.opacity(0.16) : .white.opacity(0.07))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(scene == selectedScene ? scene.accent.opacity(0.95) : .white.opacity(0.08), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func metricsStrip(time: TimeInterval) -> some View {
        let values: [(String, String)] = [
            ("Glow", String(format: "%.0f%%", 60 + (sin(time * 0.9) + 1) * 20)),
            ("Flux", String(format: "%.1f", 1.8 + (cos(time * 0.7) + 1) * 0.9)),
            ("Lift", String(format: "%.0f px", 18 + (sin(time * 1.3) + 1) * 11))
        ]

        return HStack(spacing: 12) {
            ForEach(values, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(item.1)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
            }
        }
    }

    private func triggerPulse() {
        pulseResetTask?.cancel()
        pulseTrigger += 1
        isPulseActive = true

        // 只保留最后一次 pulse 的复位任务，避免快速连点时旧任务截断新动画。
        pulseResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(520))
            isPulseActive = false
        }
    }
}

private enum SpectacleScene: String, CaseIterable, Identifiable {
    case aurora = "Aurora"
    case solar = "Solar"
    case tide = "Tide"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .aurora: return Color(red: 0.45, green: 0.98, blue: 0.86)
        case .solar: return Color(red: 1.0, green: 0.73, blue: 0.32)
        case .tide: return Color(red: 0.52, green: 0.76, blue: 1.0)
        }
    }

    var backgroundColors: [Color] {
        switch self {
        case .aurora:
            return [Color(red: 0.03, green: 0.06, blue: 0.13), Color(red: 0.05, green: 0.18, blue: 0.19), Color(red: 0.16, green: 0.07, blue: 0.22)]
        case .solar:
            return [Color(red: 0.15, green: 0.06, blue: 0.03), Color(red: 0.34, green: 0.13, blue: 0.07), Color(red: 0.55, green: 0.21, blue: 0.08)]
        case .tide:
            return [Color(red: 0.02, green: 0.06, blue: 0.12), Color(red: 0.05, green: 0.12, blue: 0.24), Color(red: 0.09, green: 0.24, blue: 0.31)]
        }
    }

    var blobColors: [Color] {
        switch self {
        case .aurora:
            return [.mint.opacity(0.8), .cyan.opacity(0.7), .purple.opacity(0.65)]
        case .solar:
            return [.orange.opacity(0.9), .yellow.opacity(0.75), .pink.opacity(0.55)]
        case .tide:
            return [.blue.opacity(0.85), .cyan.opacity(0.6), .indigo.opacity(0.5)]
        }
    }

    var cardColors: [Color] {
        switch self {
        case .aurora:
            return [Color(red: 0.07, green: 0.32, blue: 0.28), Color(red: 0.22, green: 0.08, blue: 0.31)]
        case .solar:
            return [Color(red: 0.44, green: 0.18, blue: 0.06), Color(red: 0.19, green: 0.05, blue: 0.04)]
        case .tide:
            return [Color(red: 0.05, green: 0.17, blue: 0.34), Color(red: 0.06, green: 0.08, blue: 0.22)]
        }
    }

    var heroTitle: String {
        switch self {
        case .aurora: return "Northern Drift"
        case .solar: return "Solar Bloom"
        case .tide: return "Neon Tide"
        }
    }

    var heroSubtitle: String {
        switch self {
        case .aurora: return "多层渐变沿不同速度轻微漂移，配合轨道粒子和能量环，形成一块持续呼吸的光幕。"
        case .solar: return "暖色调更强调冲击感和高光拉伸，整体节奏更偏强拍。"
        case .tide: return "蓝色系偏冷静，用更长周期的位移和柔和 blur 做出流体感。"
        }
    }

    var badgeTitle: String {
        switch self {
        case .aurora: return "AURORA LIVE"
        case .solar: return "SOLAR PEAK"
        case .tide: return "TIDE FLOW"
        }
    }

    var footnote: String {
        switch self {
        case .aurora: return "轻点场景卡片可切换主配色"
        case .solar: return "橙红高光会让深色背景更有体积"
        case .tide: return "更长的位移周期让动效看起来更平稳"
        }
    }

    var shortDescription: String {
        switch self {
        case .aurora: return "冷暖交叠流光"
        case .solar: return "高亮热浪"
        case .tide: return "深海霓虹"
        }
    }
}

private struct AnimatedBackdrop: View {
    let scene: SpectacleScene
    let time: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    colors: scene.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(Array(scene.blobColors.enumerated()), id: \.offset) { index, color in
                    let speed = 0.18 + Double(index) * 0.09
                    let x = size.width * (0.25 + CGFloat(index) * 0.26) + CGFloat(cos(time * speed + Double(index))) * 70
                    let y = size.height * (0.24 + CGFloat(index) * 0.18) + CGFloat(sin(time * (speed + 0.07) + Double(index) * 1.4)) * 85

                    Circle()
                        .fill(color)
                        .frame(width: size.width * 0.72, height: size.width * 0.72)
                        .blur(radius: 80)
                        .position(x: x, y: y)
                        .blendMode(.screen)
                }

                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.18), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 360
                        )
                    )
                    .rotationEffect(.degrees(time * 7))
                    .blendMode(.softLight)
            }
            .ignoresSafeArea()
        }
    }
}

private struct FloatingOrbs: View {
    let scene: SpectacleScene
    let time: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let particles = makeParticles(in: size)

            Canvas { context, _ in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.point.x,
                        y: particle.point.y,
                        width: particle.diameter,
                        height: particle.diameter
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(scene.accent.opacity(particle.opacity))
                    )
                }
            }
            .blur(radius: 1)
        }
        .ignoresSafeArea()
    }

    private func makeParticles(in size: CGSize) -> [OrbParticle] {
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
        var particles: [OrbParticle] = []
        particles.reserveCapacity(18)

        for index in 0..<18 {
            let progress = Double(index) / 18.0
            let orbit = min(size.width, size.height) * (0.23 + progress * 0.42)
            let angle = time * (0.25 + progress * 0.5) + progress * .pi * 2.6
            let horizontalScale = 0.9 + 0.12 * sin(time + progress * 4)
            let verticalScale = 0.48 + 0.18 * cos(time * 0.7 + progress * 5)
            let x = center.x + cos(angle) * orbit * horizontalScale
            let y = center.y + sin(angle) * orbit * verticalScale
            let point = CGPoint(
                x: x,
                y: y
            )

            particles.append(
                OrbParticle(
                    point: point,
                    diameter: 6 + progress * 12,
                    opacity: 0.14 + progress * 0.18
                )
            )
        }

        return particles
    }
}

private struct OrbParticle {
    let point: CGPoint
    let diameter: Double
    let opacity: Double
}

private struct HeroEnergyRings: View {
    let accent: Color
    let pulseTrigger: Int
    let isPulseActive: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.75, y: size.height * 0.38)
            let baseScale: CGFloat = isPulseActive ? 1.12 : 0.78

            for index in 0..<4 {
                let radius = CGFloat(36 + index * 26) * baseScale
                let opacity = 0.16 - Double(index) * 0.025 + (isPulseActive ? 0.16 : 0)
                var path = Path()
                path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                context.stroke(path, with: .color(accent.opacity(opacity)), lineWidth: isPulseActive ? 2.2 : 1.2)
            }
        }
        .scaleEffect(isPulseActive ? 1.18 : 1.0)
        .opacity(isPulseActive ? 1.0 : 0.72)
        .animation(.easeOut(duration: 0.5), value: pulseTrigger)
    }
}

private struct GlassCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white.opacity(configuration.isPressed ? 0.2 : 0.12), in: Capsule())
            .overlay {
                Capsule().stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

#Preview {
    SpectacleTabDemo()
}
