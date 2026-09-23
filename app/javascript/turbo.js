import * as Turbo from "@hotwired/turbo"

// Turbo Drive は使わない。既存の JS はページを読み込んだときに1回だけ動く前提で書かれているため
// Turbo Frame で囲んだ範囲の中で、明示したものだけ Turbo で移動する
Turbo.config.drive.enabled = false

// frame が指定されていれば、その id の Turbo Frame の中身だけを入れ替えて、URL を履歴に積む
// 指定されていなければ、ページごと移動する
export function visit(url, frame) {
  if (frame) {
    Turbo.visit(url, { frame: frame, action: "advance" })
  } else {
    location.href = url
  }
}
