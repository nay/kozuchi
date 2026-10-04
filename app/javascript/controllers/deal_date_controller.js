import { Controller } from "@hotwired/stimulus"
import { visit } from "../turbo"

// 登録フォームの日付の欄
// 年月日を変えたら、その一覧に Turbo Frame の中身を切り替える。日が入っていればその日で絞った一覧、空なら月の一覧
// 入力した年月日はそのまま残す。ただし月にない日（9月31日など）は、移動先で直された日（9月30日）に合わせる
// カレンダーなど、ほかの操作で Frame の中身が切り替わるときや、戻る・進むでページが描き直されるときは、
// 移動先の日付の欄の年月日に合わせる
export default class extends Controller {
  static targets = ["year", "month", "day"]
  // urlTemplate - 月の一覧の URL。_YEAR_, _MONTH_ を置き換えて使う。日で絞った一覧の URL は、その後ろに日を付けたもの
  // day - 表示中の一覧で絞っている日。月の一覧なら 0
  static values = { frame: String, urlTemplate: String, year: Number, month: Number, day: Number }

  // 年が4桁、月が1〜12、日が空か1〜2桁の数字で、表示中の一覧と違うときだけ切り替える（入力の途中の値では切り替えない）
  // 月にない日は、移動先のサーバーで近い日に直る
  navigate() {
    const year = this.yearTarget.value.trim()
    const month = this.monthTarget.value.trim()
    const day = this.dayTarget.value.trim()
    if (!/^\d{4}$/.test(year) || !/^\d{1,2}$/.test(month) || !/^\d{0,2}$/.test(day)) return
    const y = parseInt(year, 10)
    const m = parseInt(month, 10)
    const d = day === "" ? 0 : parseInt(day, 10)
    if (m < 1 || m > 12) return
    if (y === this.yearValue && m === this.monthValue && d === this.dayValue) return

    this.navigating = true
    let url = this.urlTemplateValue.replace("_YEAR_", y).replace("_MONTH_", m)
    if (day !== "") url += "/" + d
    visit(url, this.frameValue)
  }

  // クリアボタン。表示中の年月の月の一覧をページごと読み込み直して、日付の欄と登録フォームを、その月を最初に開いたときの状態に戻す
  // 日付の欄と登録フォームは Frame の中身を入れ替えても残る作りなので、Frame ではなくページごと移動する
  clear() {
    location.href = this.urlTemplateValue.replace("_YEAR_", this.yearValue).replace("_MONTH_", this.monthValue)
  }

  // Turbo のページ単位の移動が始まるときに呼ばれる。戻る・進む（restore）かどうかを覚えておく
  visitStarted(event) {
    this.restoring = event.detail.action === "restore"
  }

  // Frame の中身を入れ替える直前（turbo:before-frame-render）と、ページを描き直す直前（turbo:before-render）に呼ばれる
  // この日付の欄は入れ替えずに残るので、移動先の画面の年月日を、入れ替えられる側の要素（#new_deal_datebox_source）から受け取る
  // ページの描き直しは、戻る・進むのときだけ対象にする（Frame の移動の後始末でも起きるが、そこでは合わせない）
  follow(event) {
    const { newFrame, newBody } = event.detail
    if (newFrame && event.target.id !== this.frameValue) return
    if (newBody && !this.restoring) return
    const source = (newFrame || newBody).querySelector(`#${this.element.id}_source`)
    if (!source) return

    this.yearValue = source.dataset.year
    this.monthValue = source.dataset.month
    this.dayValue = source.dataset.day || 0
    if (this.navigating) {
      this.navigating = false
      // 自分の入力で移動したときは入力をそのまま残す。ただし、月にない日が移動先で直されていたら、直された日に合わせる
      if (this.dayTarget.value.trim() !== "" && parseInt(this.dayTarget.value, 10) !== this.dayValue) {
        this.dayTarget.value = source.dataset.day
      }
      return
    }
    this.yearTarget.value = source.dataset.year
    this.monthTarget.value = source.dataset.month
    this.dayTarget.value = source.dataset.day || ""
  }
}
