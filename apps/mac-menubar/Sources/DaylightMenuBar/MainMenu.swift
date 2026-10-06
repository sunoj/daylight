// Hidden main menu for the accessory (menu bar) app.
// Exports: MainMenu
// Deps: AppKit, Localization
//
// An LSUIElement app never shows a menu bar, but AppKit still routes key
// equivalents through NSApp.mainMenu. Without one, ⌘C/⌘V/⌘A/⌘Z do nothing in
// the popover's text fields and ⌘Q cannot quit.

import AppKit

enum MainMenu {
    static func make() -> NSMenu {
        let main = NSMenu()
        main.addItem(submenuItem(NSMenu(title: "Daylight"), items: [
            item(L("退出 Daylight"), #selector(NSApplication.terminate(_:)), "q")
        ]))
        main.addItem(submenuItem(NSMenu(title: L("编辑")), items: [
            item(L("撤销"), Selector(("undo:")), "z"),
            item(L("重做"), Selector(("redo:")), "Z"),
            .separator(),
            item(L("剪切"), #selector(NSText.cut(_:)), "x"),
            item(L("复制"), #selector(NSText.copy(_:)), "c"),
            item(L("粘贴"), #selector(NSText.paste(_:)), "v"),
            item(L("全选"), #selector(NSText.selectAll(_:)), "a")
        ]))
        return main
    }

    private static func submenuItem(_ menu: NSMenu, items: [NSMenuItem]) -> NSMenuItem {
        items.forEach(menu.addItem)
        let holder = NSMenuItem(title: menu.title, action: nil, keyEquivalent: "")
        holder.submenu = menu
        return holder
    }

    private static func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        NSMenuItem(title: title, action: action, keyEquivalent: key)
    }
}
