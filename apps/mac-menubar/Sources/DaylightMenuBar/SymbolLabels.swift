// Spoken names for SF Symbols used as icon-only controls.
// Exports: SymbolLabels
// Deps: Localization
//
// VoiceOver reads an image's accessibilityDescription verbatim, so passing the
// symbol name made it say "chevron.left". Purely decorative glyphs get nil.

enum SymbolLabels {
    static func description(for symbol: String) -> String? {
        switch symbol {
        case "chevron.left": return L("上一页")
        case "chevron.right": return L("下一页")
        case "chevron.up": return L("上移")
        case "chevron.down": return L("下移")
        case "minus.circle": return L("移除")
        case "plus.circle": return L("添加")
        case "calendar": return L("今天")
        case "gearshape": return L("设置")
        case "square.and.pencil": return L("记一笔")
        case "xmark": return L("关闭")
        default: return nil
        }
    }
}
