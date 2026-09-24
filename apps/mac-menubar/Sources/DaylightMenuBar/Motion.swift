// Motion tokens and animation helpers for restrained UI transitions.
// Exports: Motion
// Deps: AppKit, QuartzCore

import AppKit
import QuartzCore

enum Motion {
    /// Test hook — when set, overrides the system reduce-motion preference.
    static var reduceMotionOverride: Bool?

    static var isReduced: Bool {
        if let reduceMotionOverride { return reduceMotionOverride }
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    static let micro: CFTimeInterval = 0.12
    static let quick: CFTimeInterval = 0.18
    static let base: CFTimeInterval = 0.24

    static let easeOut = CAMediaTimingFunction(controlPoints: 0.22, 0.61, 0.36, 1)
    static let easeInOut = CAMediaTimingFunction(controlPoints: 0.4, 0, 0.2, 1)
    static let emphasis = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)

    static func duration(_ value: CFTimeInterval) -> CFTimeInterval {
        isReduced ? 0 : value
    }

    static func animate(
        _ layer: CALayer?,
        keyPath: String,
        from: Any?,
        to: Any?,
        duration: CFTimeInterval,
        timing: CAMediaTimingFunction
    ) {
        let resolved = Self.duration(duration)
        guard resolved > 0 else { return }
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = resolved
        animation.timingFunction = timing
        layer?.add(animation, forKey: keyPath)
    }

    static func run(
        duration: CFTimeInterval,
        timing: CAMediaTimingFunction,
        _ body: () -> Void,
        completion: (() -> Void)? = nil
    ) {
        let resolved = Self.duration(duration)
        if resolved == 0 {
            body()
            completion?()
            return
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = resolved
            context.timingFunction = timing
            context.allowsImplicitAnimation = true
            body()
        }, completionHandler: completion)
    }
}
