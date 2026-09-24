// Coalesces synchronous render requests into one follow-up pass.
// Exports: RenderCoalescer
// Deps: none

final class RenderCoalescer {
    private let render: () -> Void
    private var isRendering = false
    private var needsRerender = false

    init(render: @escaping () -> Void) {
        self.render = render
    }

    func request() {
        guard !isRendering else {
            needsRerender = true
            return
        }

        isRendering = true
        repeat {
            needsRerender = false
            render()
        } while needsRerender
        isRendering = false
    }
}
