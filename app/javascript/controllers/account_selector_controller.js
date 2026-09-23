import { Controller } from "@hotwired/stimulus"

// 口座を選ぶと、その口座の一覧へ移動する。総合（選択なし）を選ぶと、総合の一覧へ移動する
export default class extends Controller {
  static values = { accountUrlTemplate: String, allUrl: String }

  navigate() {
    const accountId = this.element.value
    location.href = accountId === "" ? this.allUrlValue : this.accountUrlTemplateValue.replace("_ACCOUNT_ID_", accountId)
  }
}
