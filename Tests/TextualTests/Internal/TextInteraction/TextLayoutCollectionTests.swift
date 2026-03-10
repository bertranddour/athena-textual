#if os(iOS)
  import SwiftUI
  import Testing
  import SnapshotTesting

  import Textual

  @MainActor
  struct TextLayoutCollectionTests {
    @Test func simpleInlineTextLayout() {
      let view = InlineText(markdown: "Hello world!")
        .padding(.horizontal)

      assertSnapshot(of: view, as: .textLayoutCollection())
    }

    @Test func multilineInlineTextLayout() {
      let view = InlineText(markdown: "Hello\nworld!")
        .padding(.horizontal)

      assertSnapshot(of: view, as: .textLayoutCollection())
    }

    @Test func multilineWithNewlinesInlineTextLayout() {
      let view = InlineText(markdown: "Hello\n\nworld!")
        .padding(.horizontal)

      assertSnapshot(of: view, as: .textLayoutCollection())
    }

    @Test func twoParagraphsBidiStructuredTextLayout() {
      let view = StructuredText(
        markdown: """
          This is a **sample** paragraph with a [link](https://example.com) and \u{2067}مرحبا\u{2069}.

          Another *sample* paragraph with `code` and \u{2067}كيف حالك؟\u{2069}.
          """
      ).padding()

      assertSnapshot(of: view, as: .textLayoutCollection())
    }
  }
#endif

#if TEXTUAL_ENABLE_TEXT_SELECTION
  import Foundation
  import SwiftUI
  import Testing

  @testable import Textual

  @Suite("TextLayoutCollection bounds checking")
  struct TextLayoutCollectionBoundsTests {
    // A layout with one line that has empty runs
    private static func collectionWithEmptyRuns() -> CodableTextLayoutCollection {
      CodableTextLayoutCollection(
        _layouts: [
          CodableTextLayout(
            attributedString: NSAttributedString(string: ""),
            origin: .zero,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20),
            _lines: [
              CodableTextLine(
                origin: .zero,
                typographicBounds: CGRect(x: 0, y: 0, width: 100, height: 20),
                _runs: []
              ),
            ]
          ),
        ]
      )
    }

    // A normal single-line layout for testing invalid index paths against
    private static func singleLineCollection() -> CodableTextLayoutCollection {
      CodableTextLayoutCollection(
        _layouts: [
          CodableTextLayout(
            attributedString: NSAttributedString(string: "Hello"),
            origin: .zero,
            bounds: CGRect(x: 0, y: 0, width: 100, height: 20),
            _lines: [
              CodableTextLine(
                origin: .zero,
                typographicBounds: CGRect(x: 0, y: 0, width: 100, height: 20),
                _runs: [
                  CodableTextRun(
                    isRightToLeft: false,
                    typographicBounds: CGRect(x: 0, y: 0, width: 100, height: 20),
                    url: nil,
                    _slices: [
                      CodableTextRunSlice(
                        typographicBounds: CGRect(x: 0, y: 0, width: 100, height: 20),
                        characterRange: 0..<5
                      ),
                    ]
                  ),
                ]
              ),
            ]
          ),
        ]
      )
    }

    @Test("closestPosition returns nil for line with empty runs")
    func closestPositionEmptyRuns() {
      let collection = Self.collectionWithEmptyRuns()
      let result = collection.closestPosition(to: CGPoint(x: 50, y: 10))
      #expect(result == nil)
    }

    @Test("characterRange returns nil for line with empty runs")
    func characterRangeEmptyRuns() {
      let collection = Self.collectionWithEmptyRuns()
      let result = collection.characterRange(at: CGPoint(x: 50, y: 10))
      #expect(result == nil)
    }

    @Test("localCharacterRange returns empty range for out-of-bounds IndexPath")
    func localCharacterRangeOutOfBounds() {
      let collection = Self.singleLineCollection()
      let outOfBounds = IndexPath(runSlice: 0, run: 5, line: 0, layout: 0)
      let result = collection.localCharacterRange(at: outOfBounds)
      #expect(result == 0..<0)
    }

    @Test("layoutDirection returns leftToRight for out-of-bounds IndexPath")
    func layoutDirectionOutOfBounds() {
      let collection = Self.singleLineCollection()
      let outOfBounds = IndexPath(runSlice: 0, run: 5, line: 0, layout: 0)
      let result = collection.layoutDirection(at: outOfBounds)
      #expect(result == .leftToRight)
    }

    @Test("caretRect returns zero for out-of-bounds IndexPath")
    func caretRectOutOfBounds() {
      let collection = Self.singleLineCollection()
      let position = TextPosition(
        indexPath: IndexPath(runSlice: 0, run: 5, line: 0, layout: 0),
        affinity: .downstream
      )
      let result = collection.caretRect(for: position)
      #expect(result == .zero)
    }

    @Test("isValidIndexPath validates correctly")
    func isValidIndexPathTests() {
      let collection = Self.singleLineCollection()
      let valid = IndexPath(runSlice: 0, run: 0, line: 0, layout: 0)
      #expect(collection.isValidIndexPath(valid))

      let badLayout = IndexPath(runSlice: 0, run: 0, line: 0, layout: 5)
      #expect(!collection.isValidIndexPath(badLayout))

      let badRun = IndexPath(runSlice: 0, run: 5, line: 0, layout: 0)
      #expect(!collection.isValidIndexPath(badRun))

      let badSlice = IndexPath(runSlice: 5, run: 0, line: 0, layout: 0)
      #expect(!collection.isValidIndexPath(badSlice))
    }
  }
#endif
