import SwiftUI

enum Theme {
    static let ink = Color.black
    static let paper = Color.white
    static let line = Color.black.opacity(0.15)
    static let subtleText = Color.black.opacity(0.5)
    static let placeholder = Color.black.opacity(0.35)
    static let cornerRadius: CGFloat = 2
}

struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDisabled ? Theme.ink.opacity(0.3) : Theme.ink)
            .foregroundColor(Theme.paper)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct MonoTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Theme.paper)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.line, lineWidth: 1)
            )
    }
}

extension View {
    func monoField() -> some View { modifier(MonoTextFieldStyle()) }
}
