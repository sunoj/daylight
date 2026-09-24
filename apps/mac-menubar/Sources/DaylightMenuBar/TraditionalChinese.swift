// Traditional Chinese display conversion for product strings and calendar data.
// Generated from OpenCC s2tw, with calendar-specific corrections for 丑 and 干支.
import Foundation

enum TraditionalChinese {
    private static let simplified = Array("与两个为么义买于亏产仅从们众会传体储儿关内册写农决准击划则刚删别办务动区单厅历双发变台号后吗启周响国图圆块处备复实宽对导寿属带帮并广庆应开当录态总惊户托扩报择换据数无时昼显暂朴机权条来构标栏样档检榄残气没洁浅浏温湾溃满点状独现盘码确离种称笔签简类约级纪纬线组细经给络绝统绿缓网联腊节荐获蓝蛰补装见观视览计订认让议记许论设访证识译询详语误说请读调败账贴费踪转轮轻载输边过运还这进远连适选邮采里钟钮铁链锈错键闭问闰间阅阴际陆随隐页顶项顺频题颜饭验黄齿龄")
    private static let traditional = Array("與兩個為麼義買於虧產僅從們眾會傳體儲兒關內冊寫農決準擊劃則剛刪別辦務動區單廳歷雙發變臺號後嗎啟週響國圖圓塊處備復實寬對導壽屬帶幫並廣慶應開當錄態總驚戶託擴報擇換據數無時晝顯暫樸機權條來構標欄樣檔檢欖殘氣沒潔淺瀏溫灣潰滿點狀獨現盤碼確離種稱筆籤簡類約級紀緯線組細經給絡絕統綠緩網聯臘節薦獲藍蟄補裝見觀視覽計訂認讓議記許論設訪證識譯詢詳語誤說請讀調敗賬貼費蹤轉輪輕載輸邊過運還這進遠連適選郵採裡鍾鈕鐵鏈鏽錯鍵閉問閏間閱陰際陸隨隱頁頂項順頻題顏飯驗黃齒齡")
    private static let characters = Dictionary(uniqueKeysWithValues: zip(simplified, traditional))

    static func convert(_ value: String) -> String {
        let contextual = value
            .replacingOccurrences(of: "日历", with: "日曆")
            .replacingOccurrences(of: "农历", with: "農曆")
            .replacingOccurrences(of: "公历", with: "公曆")
            .replacingOccurrences(of: "阴历", with: "陰曆")
        return String(contextual.map { characters[$0] ?? $0 })
    }
}
