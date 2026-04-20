import Combine
import SwiftUI
import UIKit

struct SnakeGameDemo: View {
    private let tickInterval = 0.18

    @State private var game = SnakeGame(boardSize: .classic, seed: 1)
    @State private var restartSeed: UInt64 = 1
    @State private var timer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            header
            boardSection
            controlsSection
            footer
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Snake")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            SnakeKeyboardCapture(
                onDirection: handleDirectionInput,
                onPause: togglePause,
                onRestart: restartGame
            )
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
        }
        .onReceive(timer) { _ in
            game.step()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            statCard(title: "Score", value: "\(game.score)")
            statCard(title: "State", value: statusText)
        }
    }

    private var boardSection: some View {
        ZStack {
            SnakeBoardView(game: game)
                .aspectRatio(1, contentMode: .fit)

            if game.isGameOver || game.isPaused {
                overlayCard
            }
        }
    }

    private var overlayCard: some View {
        VStack(spacing: 10) {
            Text(game.isGameOver ? "Game Over" : "Paused")
                .font(.title3.weight(.bold))

            Text(game.isGameOver ? "Hit restart to play again." : "Press pause again or tap a direction to continue.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                if game.isPaused {
                    Button("Resume", action: togglePause)
                        .buttonStyle(.borderedProminent)
                }

                if game.isPaused {
                    Button("Restart", action: restartGame)
                        .buttonStyle(.bordered)
                } else {
                    Button("Restart", action: restartGame)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(radius: 12, y: 6)
    }

    private var controlsSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Button(game.isPaused ? "Resume" : "Pause", action: togglePause)
                    .buttonStyle(.bordered)
                    .disabled(game.isGameOver)
                Button("Restart", action: restartGame)
                    .buttonStyle(.borderedProminent)
            }

            VStack(spacing: 10) {
                controlButton(systemImage: "arrow.up", direction: .up)

                HStack(spacing: 10) {
                    controlButton(systemImage: "arrow.left", direction: .left)
                    controlButton(systemImage: "arrow.down", direction: .down)
                    controlButton(systemImage: "arrow.right", direction: .right)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        Text("Arrow keys or WASD move the snake. Space pauses. R restarts.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }

    private var statusText: String {
        if game.isGameOver { return "Over" }
        if game.isPaused { return "Paused" }
        return "Running"
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func controlButton(systemImage: String, direction: SnakeGame.Direction) -> some View {
        Button {
            handleDirectionInput(direction)
        } label: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 58, height: 58)
        }
        .buttonStyle(.bordered)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .disabled(game.isGameOver)
    }

    private func togglePause() {
        game.togglePause()
    }

    private func restartGame() {
        restartSeed &+= 1
        game.restart(seed: restartSeed)
        timer = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
    }

    private func handleDirectionInput(_ direction: SnakeGame.Direction) {
        if game.isPaused {
            game.togglePause()
        }
        game.queueDirection(direction)
    }
}

private struct SnakeBoardView: View {
    let game: SnakeGame

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let boardWidth = CGFloat(game.boardSize.columns)
            let boardHeight = CGFloat(game.boardSize.rows)
            let cellSide = side / max(boardWidth, boardHeight)
            let boardSize = CGSize(width: cellSide * boardWidth, height: cellSide * boardHeight)

            Canvas { context, _ in
                let boardRect = CGRect(origin: .zero, size: boardSize)
                let backgroundPath = Path(roundedRect: boardRect, cornerRadius: 18)
                context.fill(backgroundPath, with: .color(Color(.secondarySystemGroupedBackground)))
                context.stroke(backgroundPath, with: .color(Color.black.opacity(0.08)), lineWidth: 1)

                var grid = Path()
                for row in 1..<game.boardSize.rows {
                    let y = CGFloat(row) * cellSide
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: boardSize.width, y: y))
                }
                for column in 1..<game.boardSize.columns {
                    let x = CGFloat(column) * cellSide
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: boardSize.height))
                }
                context.stroke(grid, with: .color(Color.black.opacity(0.08)), lineWidth: 0.5)

                let foodRect = rect(for: game.food, cellSide: cellSide).insetBy(dx: cellSide * 0.18, dy: cellSide * 0.18)
                context.fill(Path(ellipseIn: foodRect), with: .color(.red))

                for segment in game.snake.dropFirst() {
                    context.fill(
                        Path(roundedRect: rect(for: segment, cellSide: cellSide).insetBy(dx: 1.5, dy: 1.5), cornerRadius: 5),
                        with: .color(Color.green.opacity(0.78))
                    )
                }

                context.fill(
                    Path(roundedRect: rect(for: game.head, cellSide: cellSide).insetBy(dx: 1, dy: 1), cornerRadius: 6),
                    with: .color(Color.green)
                )
            }
            .frame(width: boardSize.width, height: boardSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func rect(for cell: SnakeGame.Cell, cellSide: CGFloat) -> CGRect {
        CGRect(
            x: CGFloat(cell.x) * cellSide,
            y: CGFloat(cell.y) * cellSide,
            width: cellSide,
            height: cellSide
        )
    }
}

private struct SnakeKeyboardCapture: UIViewRepresentable {
    let onDirection: (SnakeGame.Direction) -> Void
    let onPause: () -> Void
    let onRestart: () -> Void

    func makeUIView(context: Context) -> SnakeKeyInputView {
        let view = SnakeKeyInputView()
        view.onDirection = onDirection
        view.onPause = onPause
        view.onRestart = onRestart
        DispatchQueue.main.async {
            view.becomeFirstResponder()
        }
        return view
    }

    func updateUIView(_ uiView: SnakeKeyInputView, context: Context) {
        uiView.onDirection = onDirection
        uiView.onPause = onPause
        uiView.onRestart = onRestart

        DispatchQueue.main.async {
            if uiView.window != nil, !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        }
    }
}

private final class SnakeKeyInputView: UIView {
    var onDirection: ((SnakeGame.Direction) -> Void)?
    var onPause: (() -> Void)?
    var onRestart: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            becomeFirstResponder()
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            keyCommand(UIKeyCommand.inputUpArrow, action: #selector(moveUp)),
            keyCommand(UIKeyCommand.inputDownArrow, action: #selector(moveDown)),
            keyCommand(UIKeyCommand.inputLeftArrow, action: #selector(moveLeft)),
            keyCommand(UIKeyCommand.inputRightArrow, action: #selector(moveRight)),
            keyCommand("w", action: #selector(moveUp)),
            keyCommand("a", action: #selector(moveLeft)),
            keyCommand("s", action: #selector(moveDown)),
            keyCommand("d", action: #selector(moveRight)),
            keyCommand(" ", action: #selector(togglePause)),
            keyCommand("r", action: #selector(restartGame))
        ]
    }

    private func keyCommand(_ input: String, action: Selector) -> UIKeyCommand {
        UIKeyCommand(input: input, modifierFlags: [], action: action)
    }

    @objc private func moveUp() {
        onDirection?(.up)
    }

    @objc private func moveDown() {
        onDirection?(.down)
    }

    @objc private func moveLeft() {
        onDirection?(.left)
    }

    @objc private func moveRight() {
        onDirection?(.right)
    }

    @objc private func togglePause() {
        onPause?()
    }

    @objc private func restartGame() {
        onRestart?()
    }
}

#Preview {
    NavigationStack {
        SnakeGameDemo()
    }
}
