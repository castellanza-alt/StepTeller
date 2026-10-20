// Stampa i testi che iOS genera nell'app per la lingua di avvio (-AppleLanguages/-AppleLocale): date delle
// Impostazioni e dei record, titoli dei periodi, nomi e iniziali di mesi e giorni, numeri. Usa gli stessi
// formattatori dell'app (`HistoryLabels.current`, `LocalFormat`, `DateFormatter`). Lo compila `font_asia.py`
// insieme al nucleo, a `Shared/Localization.swift` e ad `App/HistoryLabels+System.swift`.
import Foundation

var cal = Calendar.current
cal.firstWeekday = 2
cal.minimumDaysInFirstWeek = 4
let labels = HistoryLabels.current
var out = Set<String>()
func add(_ s: String) { out.insert(s) }

labels.weekdayLetters.forEach(add)
labels.monthLetters.forEach(add)
let settings = DateFormatter()
settings.locale = .current
settings.setLocalizedDateFormatFromTemplate("dMMMMyyyy")

func day(_ y: Int, _ m: Int, _ d: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d))! }
for y in 2025...2027 {
    for m in 1...12 {
        let first = day(y, m, 1)
        add(labels.month(first, cal))
        let days = cal.range(of: .day, in: .month, for: first)!.count
        for d in 1...days {
            let date = day(y, m, d)
            add(labels.day(date, cal))
            add(settings.string(from: date))
            let end = cal.date(byAdding: .day, value: 6, to: date)!
            add(labels.week(date, end, cal))
            add(labels.weekRange(date, end, cal))
            add(labels.span(date, end, cal))
        }
        for m2 in 1...12 {
            add(labels.span(first, day(y, m2, 15), cal))
            add(labels.span(first, day(y + 1, m2, 15), cal))
        }
    }
}
for v in [0, 7, 42, 815, 3_465, 10_000, 24_318, 1_234_567] { add(LocalFormat.integer(v)) }
for v in [0.0, 1.9, 6.7, 8.3, 16.0, 123.4] { add(LocalFormat.number(v, decimals: 1)) }
print(out.sorted().joined(separator: "\n"))
