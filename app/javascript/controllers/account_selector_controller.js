import { Controller } from "@hotwired/stimulus"
import { visit } from "../turbo"

// 口座を選ぶと、その口座の一覧へ移動する。総合（選択なし）を選ぶと、総合の一覧へ移動する
// frame が指定されていれば、その id の Turbo Frame の中身だけを入れ替える
export default class extends Controller {
  static values = { accountUrlTemplate: String, allUrl: String, frame: String }

  navigate() {
    const accountId = this.element.value
    visit(accountId === "" ? this.allUrlValue : this.accountUrlTemplateValue.replace("_ACCOUNT_ID_", accountId), this.frameValue)
  }
}
