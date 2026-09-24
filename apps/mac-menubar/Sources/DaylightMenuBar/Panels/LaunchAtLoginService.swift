// Launch-at-login registration through ServiceManagement.
// Exports: LaunchAtLoginService
// Deps: ServiceManagement

import ServiceManagement

struct LaunchAtLoginService {
    private let statusProvider: () -> Bool
    private let registerAction: () throws -> Void
    private let unregisterAction: () throws -> Void

    init(
        statusProvider: @escaping () -> Bool = { SMAppService.mainApp.status == .enabled },
        registerAction: @escaping () throws -> Void = { try SMAppService.mainApp.register() },
        unregisterAction: @escaping () throws -> Void = { try SMAppService.mainApp.unregister() }
    ) {
        self.statusProvider = statusProvider
        self.registerAction = registerAction
        self.unregisterAction = unregisterAction
    }

    var isEnabled: Bool { statusProvider() }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try registerAction()
        } else {
            try unregisterAction()
        }
    }
}
