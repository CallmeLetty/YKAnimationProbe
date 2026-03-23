//
//  AdvancedReaderRendererDemo.swift
//  YKAnimationProbe
//
//  「高级阅读器 / AI 聊天消息渲染器」演示：
//  Markdown 富文本、代码块（简易语法高亮）、MathML 数学公式、逐段显现动画、
//  引用块、表格、可折叠长文。
//
//  MARK: ─── 深挖：SwiftUI 文本与自定义渲染边界 ───────────────────────────────
//
//  【SwiftUI 文本布局】
//  - `Text` 由 TextLayout 引擎排版，底层走 CoreText / TextKit 2（系统版本相关）。
//  - 多段 `Text` 可用 `+` 拼接为单一视图，参与统一换行与基线对齐。
//  - `lineLimit`、`minimumScaleFactor`、`truncationMode` 控制溢出；`fixedSize` 避免被父级压缩。
//  - 复杂版式（多列、绕排）需 `Layout` 协议或 UIKit `UITextView` 桥接。
//
//  【AttributedString】
//  - `AttributedString(markdown:)` / `MarkdownParsingOptions` 将 MD 转为带 runs 的富文本；
//    支持范围随 Swift 版本扩展（链接、行内代码、列表等），**不等于**完整 CommonMark + GFM。
//  - `AttributeContainer` 合并策略：`.inlineOnlyPreservingWhitespace` 等选项影响解析。
//  - 与 UIKit：`NSAttributedString(attributedString)` 双向桥接，便于用 TextKit 测量。
//
//  【测量与截断】
//  - SwiftUI 无公开「单行像素宽」API；常用：`UIView`/`UILabel` 的 `systemLayoutSizeFitting`、
//    或 `Text` 外包 `GeometryReader` 读布局后帧（近似）。
//  - `ViewThatFits` 在多个候选中选首个放得下者，属于声明式「软测量」。
//  - 截断：`lineLimit` + `truncationMode`；自定义「展开全文」需自行切换 lineLimit 与状态。
//
//  【自定义 renderer 能力边界】
//  - 纯 `Text(AttributedString)`：**无法**在段落中间插入任意 `View`（按钮、图表）；
//    仅能通过附件图、链接（openURL）等有限扩展。
//  - **块级**结构（代码、公式、表格）在实践里常拆成 `VStack` 子视图，而非单一 Text ——
//    本 Demo 即该模式：「迷你 AST + 多块视图」。
//  - 真正 LaTeX：MathML（本页 WebKit）、或 KaTeX/MathJax、或第三方原生排版库。
//  - 完整 Markdown：考虑 Swift Markdown AST + 自建视图，或社区 MarkdownUI 等。
//
//  MARK: ───────────────────────────────────────────────────────────────────────

import Foundation
import SwiftUI
import UIKit
import WebKit

// MARK: - Root

struct AdvancedReaderRendererDemo: View {
    @State private var revealToken = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                deepDiveDisclosure

                aiMessageChrome {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(RenderBlock.sampleConversation.enumerated()), id: \.offset) { index, block in
                            RenderBlockView(block: block, index: index, revealToken: revealToken)
                        }
                    }
                }

                HStack {
                    Button {
                        revealToken += 1
                    } label: {
                        Label("重播逐段显现", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }

                truncationPlayground

                UILabelMeasurementHint()
            }
            .padding()
        }
        .navigationTitle("阅读器 / AI 渲染")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var deepDiveDisclosure: some View {
        DisclosureGroup("深挖：布局 · AttributedString · 测量 · 渲染边界") {
            Text(deepDiveCopy)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.08)))
    }

    private var deepDiveCopy: String {
        """
        SwiftUI 的 Text 适合连续富文本；块级元素（代码、公式、表）更适合拆成独立子视图组合。
        AttributedString 的 Markdown 解析有方言与版本差异，生产环境建议锁定选项并做快照测试。
        精确测量可桥接 UILabel/TextView；截断用 lineLimit + 自定义「展开」状态机。
        """
    }

    private func aiMessageChrome<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.indigo)
                Text("助手 · 结构化回复")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        }
    }

    private var truncationPlayground: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("截断与测量（示意）")
                .font(.headline)
            Text(
                "这是一段用于演示 lineLimit 与 truncationMode 的长文本。SwiftUI 在布局阶段决定可见行数；若需要「展开全文」，用 @State 切换 lineLimit(nil) 与动画。"
            )
            .font(.subheadline)
            .lineLimit(3)
            .truncationMode(.tail)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(.orange.opacity(0.08)))

            Text("UIKit 测量示意：`UILabel.preferredLayoutSize` 与 SwiftUI `Text` 同宽约束下的估算高度（用于「展开」、气泡高度等）。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - UILabel 测量（与 Text 对照）

private struct UILabelMeasurementHint: View {
    private let sample = "多行示例文本。\n用于演示在固定宽度下，通过 TextKit 计算内容高度。"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UILabel 测量")
                .font(.headline)
            GeometryReader { geo in
                let w = geo.size.width
                VStack(alignment: .leading, spacing: 6) {
                    Text("SwiftUI Text（同宽）")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(sample)
                        .font(.subheadline)
                        .frame(width: w, alignment: .leading)
                    Text("估算高度（UIKit）: \(measureHeight(width: w), specifier: "%.1f") pt")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.indigo)
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(.indigo.opacity(0.06)))
    }

    private func measureHeight(width: CGFloat) -> CGFloat {
        let w = max(width, 1)
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.text = sample
        let size = label.sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude))
        return size.height
    }
}

// MARK: - 块模型（迷你 AST）

private enum RenderBlock: Identifiable {
    case markdown(String)
    case code(language: String?, String)
    case mathML(String)
    case blockquote(String)
    case table(headers: [String], rows: [[String]])
    case collapsible(title: String, blocks: [RenderBlock])

    var id: String {
        switch self {
        case .markdown(let s): return "md-\(s.hashValue)"
        case .code(_, let s): return "code-\(s.hashValue)"
        case .mathML(let s): return "math-\(s.hashValue)"
        case .blockquote(let s): return "bq-\(s.hashValue)"
        case .table(let h, _): return "tbl-\(h.joined().hashValue)"
        case .collapsible(let t, _): return "fold-\(t.hashValue)"
        }
    }

    /// 扁平化后用于逐段显现的顶层步数（折叠块算 1 步，展开后内部另计可选）
    static var sampleConversation: [RenderBlock] {
        [
            .markdown(sampleMarkdownIntro),
            .blockquote("> 引用：SwiftUI 中块级与行内样式常常需要拆分视图，而不是塞进单个 `Text`。"),
            .markdown("下面是一段 **Swift** 示例（简易高亮，非完整编译器前端）："),
            .code(language: "swift", sampleSwiftCode),
            .markdown("二次方程求根公式（**MathML** + `WKWebView`，无需外联 CDN）："),
            .mathML(Self.quadraticMathML),
            .markdown("GFM 风格表格用 `Grid` 自建（AttributedString Markdown 对表格支持因系统而异）："),
            .table(
                headers: ["API", "用途", "局限"],
                rows: [
                    ["Text(AttributedString)", "连续富文本", "不能内嵌任意 View"],
                    ["WKWebView + MathML", "公式排版", "需处理高度与暗色"],
                    ["VStack 多块", "代码/表/图", "自建 AST 与样式"]
                ]
            ),
            .markdown("更多说明见折叠区："),
            .collapsible(
                title: "展开：长说明与链接",
                blocks: [
                    .markdown(
                        """
                        - [Apple AttributedString](https://developer.apple.com/documentation/foundation/attributedstring)
                        - 列表与 **粗体** 仍走 Markdown 解析
                        - 行内 `code` 也支持
                        """
                    ),
                    .code(language: "text", "echo \"折叠内代码块\""),
                ]
            ),
        ]
    }

    private static let sampleMarkdownIntro = """
    ## 小节标题

    这是 **Markdown** 渲染的段落，含 *斜体*、`行内代码` 与 [链接示例](https://www.swift.org)。
    """

    private static let sampleSwiftCode = """
    struct Counter {
        var n: Int = 0
        mutating func tick() {
            n += 1  // 自增
        }
    }
    """

    private static let quadraticMathML = #"""
    <math xmlns="http://www.w3.org/1998/Math/MathML" display="block">
      <mi>x</mi>
      <mo>=</mo>
      <mfrac>
        <mrow>
          <mo>−</mo><mi>b</mi>
          <mo>±</mo>
          <msqrt>
            <msup><mi>b</mi><mn>2</mn></msup>
            <mo>−</mo><mn>4</mn><mi>a</mi><mi>c</mi>
          </msqrt>
        </mrow>
        <mrow><mn>2</mn><mi>a</mi></mrow>
      </mfrac>
    </math>
    """#
}

// MARK: - 单块视图 + 逐段显现

private struct RenderBlockView: View {
    let block: RenderBlock
    let index: Int
    let revealToken: Int

    @State private var visible = false

    var body: some View {
        Group {
            switch block {
            case .markdown(let raw):
                MarkdownRichText(raw: raw)
            case .code(let lang, let code):
                CodeBlockCard(language: lang, code: code)
            case .mathML(let xml):
                MathMLWebCard(mathML: xml)
            case .blockquote(let raw):
                BlockquoteCard(raw: raw)
            case .table(let headers, let rows):
                MarkdownTableCard(headers: headers, rows: rows)
            case .collapsible(let title, let inner):
                CollapsibleBlockCard(title: title, inner: inner, baseIndex: index, revealToken: revealToken)
            }
        }
        .padding(.vertical, 6)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 10)
        .onAppear { scheduleReveal() }
        .onChange(of: revealToken) { _, _ in
            visible = false
            scheduleReveal()
        }
    }

    private func scheduleReveal() {
        let delay = Double(index) * 0.11 + 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                visible = true
            }
        }
    }
}

// MARK: - Markdown 富文本

private struct MarkdownRichText: View {
    let raw: String

    var body: some View {
        Group {
            if let attributed = try? AttributedString(
                markdown: raw,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .full,
                    failurePolicy: .returnPartiallyParsedIfPossible
                )
            ) {
                Text(attributed)
                    .font(.body)
                    .tint(.indigo)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(raw)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - 代码块 + 简易高亮

private struct CodeBlockCard: View {
    let language: String?
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text((language ?? "text").uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(swiftHighlightIfNeeded(code))
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func swiftHighlightIfNeeded(_ source: String) -> AttributedString {
        guard language?.lowercased() == "swift" else {
            var plain = AttributedString(source)
            plain.foregroundColor = .primary
            return plain
        }
        return highlightSwift(source)
    }
}

/// 极简词法着色：注释、字符串、关键字 —— 演示用，非严谨 lexer
private func highlightSwift(_ source: String) -> AttributedString {
    var s = AttributedString(source)
    s.foregroundColor = .primary
    s.font = .system(.callout, design: .monospaced)

    let keywords: Set<String> = [
        "struct", "class", "enum", "protocol", "extension", "import", "let", "var", "func",
        "return", "if", "else", "guard", "self", "mutating", "static", "init", "true", "false", "nil", "in"
    ]

    func colorRange(_ range: Range<String.Index>, color: Color) {
        guard let lower = AttributedString.Index(range.lowerBound, within: s),
              let upper = AttributedString.Index(range.upperBound, within: s) else { return }
        s[lower..<upper].foregroundColor = color
    }

    // // 注释
    let comment = try? NSRegularExpression(pattern: "//.*", options: [])
    let ns = source as NSString
    comment?.enumerateMatches(in: source, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
        guard let r = match?.range, let sr = Range(r, in: source) else { return }
        colorRange(sr, color: .secondary)
    }

    // "..." 字符串
    let strRe = try? NSRegularExpression(pattern: #""[^"\\]*(\\.[^"\\]*)*""#, options: [])
    strRe?.enumerateMatches(in: source, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
        guard let r = match?.range, let sr = Range(r, in: source) else { return }
        colorRange(sr, color: .orange)
    }

    // 关键字（单词边界）
    for kw in keywords {
        let pat = "\\b\(NSRegularExpression.escapedPattern(for: kw))\\b"
        guard let re = try? NSRegularExpression(pattern: pat, options: []) else { continue }
        re.enumerateMatches(in: source, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let r = match?.range, let sr = Range(r, in: source) else { return }
            colorRange(sr, color: .pink)
        }
    }

    // 数字
    let num = try? NSRegularExpression(pattern: #"\b\d+\b"#, options: [])
    num?.enumerateMatches(in: source, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
        guard let r = match?.range, let sr = Range(r, in: source) else { return }
        colorRange(sr, color: .cyan)
    }

    return s
}

// MARK: - MathML（WKWebView）

private struct MathMLWebCard: View {
    let mathML: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        MathMLWebView(mathML: mathML, isDark: colorScheme == .dark)
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemGroupedBackground)))
    }
}

private struct MathMLWebView: UIViewRepresentable {
    let mathML: String
    var isDark: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        w.isOpaque = false
        w.backgroundColor = .clear
        w.scrollView.isScrollEnabled = false
        w.scrollView.bounces = false
        return w
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let key = mathML + (isDark ? "D" : "L")
        if context.coordinator.lastKey == key { return }
        context.coordinator.lastKey = key

        let fg = isDark ? "#EBEBF5" : "#1C1C1E"
        let html = """
        <!DOCTYPE html>
        <html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
          body { margin:0; padding:10px 8px; background:transparent; color:\(fg); font-family: -apple-system; }
          math { color: \(fg); }
        </style>
        </head><body>
        \(mathML)
        </body></html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator {
        var lastKey: String?
    }
}

// MARK: - 引用块

private struct BlockquoteCard: View {
    let raw: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.indigo.opacity(0.6))
                .frame(width: 4)
            MarkdownRichText(raw: trimmedQuote(raw))
                .font(.callout)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.indigo.opacity(0.06))
        )
    }

    private func trimmedQuote(_ s: String) -> String {
        s.split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                var l = String(line)
                if l.hasPrefix("> ") { l.removeFirst(2) }
                else if l.hasPrefix(">") { l.removeFirst() }
                return l
            }
            .joined(separator: "\n")
    }
}

// MARK: - 表格

private struct MarkdownTableCard: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                ForEach(Array(headers.enumerated()), id: \.offset) { _, h in
                    Text(h)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(.tertiarySystemFill))
                }
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { ri, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { ci, cell in
                        Text(cell)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(ri % 2 == 0 ? Color.clear : Color.primary.opacity(0.03))
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 折叠

private struct CollapsibleBlockCard: View {
    let title: String
    let inner: [RenderBlock]
    let baseIndex: Int
    let revealToken: Int

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(inner.enumerated()), id: \.offset) { i, b in
                    RenderBlockView(block: b, index: baseIndex + 1 + i, revealToken: revealToken)
                }
            }
            .padding(.top, 6)
        } label: {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .tint(.indigo)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemGroupedBackground)))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdvancedReaderRendererDemo()
    }
}
