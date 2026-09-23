import * as Turbo from "@hotwired/turbo"

// Turbo Drive は使わない。既存の JS はページを読み込んだときに1回だけ動く前提で書かれているため
// Turbo Frame で囲んだ範囲の中で、明示したものだけ Turbo で移動する
Turbo.config.drive.enabled = false

// Turbo の履歴の管理も使わない。Turbo は、戻る・進むで Frame の移動の前後に戻るとき、ページ全体を描き直そうとするため
// Frame の移動の履歴は、下で data-frame-history を付けた Frame について扱う
Turbo.session.history.stop()

// frame が指定されていれば、その id の Turbo Frame の中身だけを入れ替える
// 指定されていなければ、ページごと移動する
export function visit(url, frame) {
  if (frame) {
    Turbo.visit(url, { frame: frame })
  } else {
    location.href = url
  }
}

// data-frame-history を付けた Turbo Frame は、中身を入れ替えたら URL を履歴に積み、
// 戻る・進むのときは、その URL の内容に中身を入れ替える
const initialPath = pathOf(location.href)
let restoring = false

function pathOf(url) {
  const { pathname, search } = new URL(url, location.href)
  return pathname + search
}

document.addEventListener("turbo:frame-load", (event) => {
  const frame = event.target
  if (!frame.hasAttribute("data-frame-history")) return
  if (restoring) {
    restoring = false
    return
  }
  if (pathOf(frame.src) !== pathOf(location.href)) history.pushState(null, "", frame.src)
})

addEventListener("popstate", () => {
  const frame = document.querySelector("turbo-frame[data-frame-history]")
  if (!frame) return
  // URL の # だけが変わった場合（ページ内のアンカーへの移動）は、中身を入れ替えない
  const currentPath = frame.src ? pathOf(frame.src) : initialPath
  if (pathOf(location.href) === currentPath) return
  restoring = true
  frame.src = location.href
})
