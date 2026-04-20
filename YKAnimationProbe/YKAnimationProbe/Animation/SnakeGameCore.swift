import Foundation

struct SnakeGame {
    struct BoardSize: Equatable {
        let columns: Int
        let rows: Int

        static let classic = BoardSize(columns: 16, rows: 16)

        var cellCount: Int {
            columns * rows
        }
    }

    struct Cell: Hashable {
        let x: Int
        let y: Int

        func moved(by direction: Direction) -> Cell {
            Cell(x: x + direction.dx, y: y + direction.dy)
        }
    }

    enum Direction: CaseIterable {
        case up
        case down
        case left
        case right

        var dx: Int {
            switch self {
            case .left: return -1
            case .right: return 1
            case .up, .down: return 0
            }
        }

        var dy: Int {
            switch self {
            case .up: return -1
            case .down: return 1
            case .left, .right: return 0
            }
        }

        var opposite: Direction {
            switch self {
            case .up: return .down
            case .down: return .up
            case .left: return .right
            case .right: return .left
            }
        }
    }

    let boardSize: BoardSize
    private(set) var snake: [Cell]
    private(set) var direction: Direction
    private(set) var food: Cell
    private(set) var score: Int
    private(set) var isGameOver: Bool
    private(set) var isPaused: Bool

    private var queuedDirection: Direction?
    private var foodSeed: UInt64

    init(boardSize: BoardSize = .classic, seed: UInt64 = 1) {
        self.boardSize = boardSize
        self.snake = []
        self.direction = .right
        self.food = Cell(x: 0, y: 0)
        self.score = 0
        self.isGameOver = false
        self.isPaused = false
        self.queuedDirection = nil
        self.foodSeed = SnakeGame.normalizedSeed(seed)
        reset(seed: seed)
    }

    var head: Cell {
        snake[0]
    }

    var occupiedCells: Set<Cell> {
        Set(snake)
    }

    mutating func queueDirection(_ nextDirection: Direction) {
        guard !isGameOver else { return }
        guard queuedDirection == nil else { return }
        guard nextDirection != direction.opposite else { return }
        guard nextDirection != direction else { return }
        queuedDirection = nextDirection
    }

    mutating func togglePause() {
        guard !isGameOver else { return }
        isPaused.toggle()
    }

    mutating func restart(seed: UInt64? = nil) {
        reset(seed: seed ?? foodSeed)
    }

    mutating func step() {
        guard !isGameOver, !isPaused else { return }

        if let queuedDirection {
            direction = queuedDirection
            self.queuedDirection = nil
        }

        let nextHead = head.moved(by: direction)
        guard isWithinBounds(nextHead) else {
            isGameOver = true
            return
        }

        let willGrow = nextHead == food
        let blockingCells = willGrow ? snake[...] : snake.dropLast()
        if blockingCells.contains(nextHead) {
            isGameOver = true
            return
        }

        snake.insert(nextHead, at: 0)

        if willGrow {
            score += 1
            if snake.count == boardSize.cellCount {
                isGameOver = true
                return
            }
            spawnFood()
        } else {
            snake.removeLast()
        }
    }

    private mutating func reset(seed: UInt64) {
        foodSeed = SnakeGame.normalizedSeed(seed)
        direction = .right
        queuedDirection = nil
        score = 0
        isGameOver = false
        isPaused = false

        let startX = max(2, boardSize.columns / 2)
        let startY = boardSize.rows / 2
        snake = [
            Cell(x: startX, y: startY),
            Cell(x: startX - 1, y: startY),
            Cell(x: startX - 2, y: startY)
        ]

        spawnFood()
    }

    private mutating func spawnFood() {
        let occupied = Set(snake)
        let availableCells = allCells.filter { !occupied.contains($0) }

        guard !availableCells.isEmpty else {
            food = head
            return
        }

        foodSeed = SnakeGame.nextSeed(foodSeed)
        let index = Int(foodSeed % UInt64(availableCells.count))
        food = availableCells[index]
    }

    private var allCells: [Cell] {
        var cells: [Cell] = []
        cells.reserveCapacity(boardSize.cellCount)

        for y in 0..<boardSize.rows {
            for x in 0..<boardSize.columns {
                cells.append(Cell(x: x, y: y))
            }
        }

        return cells
    }

    private func isWithinBounds(_ cell: Cell) -> Bool {
        (0..<boardSize.columns).contains(cell.x) && (0..<boardSize.rows).contains(cell.y)
    }

    private static func normalizedSeed(_ seed: UInt64) -> UInt64 {
        seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    private static func nextSeed(_ seed: UInt64) -> UInt64 {
        seed &* 6364136223846793005 &+ 1442695040888963407
    }
}
