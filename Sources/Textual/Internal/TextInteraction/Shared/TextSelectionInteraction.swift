import SwiftUI

// MARK: - Overview
//
// `TextSelectionInteraction` manages the text selection model lifecycle for multiple `Text` fragments.
//
// Selection is opt-in through the `textSelection` environment value. When enabled, the modifier
// observes text layout changes via `onPreferenceChange(Text.LayoutKey.self)` and creates or
// updates a `TextSelectionModel`. The preference value is stored in `@State` and combined with
// a `GeometryReader` to resolve anchors, ensuring the model updates at most once per frame.
// The model is then passed to the platform-specific implementation
// (`PlatformTextSelectionInteraction`), which presents the appropriate selection UI for macOS
// or iOS. This separation keeps model management in shared code while platform interactions
// remain independent.

struct TextSelectionInteraction: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION
    @Environment(\.textSelection) private var textSelection
    @Environment(TextSelectionCoordinator.self) private var coordinator: TextSelectionCoordinator?

    @State private var model = TextSelectionModel()
    @State private var preferenceValue = Text.LayoutKey.defaultValue
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if textSelection.allowsSelection {
        content
          .onPreferenceChange(Text.LayoutKey.self) { value in
            preferenceValue = value
          }
          .background {
            GeometryReader { geometry in
              Color.clear
                .onChange(of: preferenceValue, initial: true) {
                  let collection = LiveTextLayoutCollection(
                    base: preferenceValue, geometry: geometry
                  )
                  model.setCoordinator(coordinator)
                  model.setLayoutCollection(collection)
                }
            }
          }
          .modifier(PlatformTextSelectionInteraction(model: model))
      } else {
        content
      }
    #else
      content
    #endif
  }
}

#if TEXTUAL_ENABLE_TEXT_SELECTION
  extension EnvironmentValues {
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @usableFromInline
    @Entry var textSelection: any TextSelectability.Type = DisabledTextSelectability.self
  }
#endif
