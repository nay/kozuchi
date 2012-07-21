// Copyright 2007 futomi  http://www.html5.jp/
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

if( typeof html5jp == 'undefined' ) {
	html5jp = new Object();
}
if( typeof html5jp.graph == 'undefined' ) {
	html5jp.graph = new Object();
}

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
* コンストラクタ
* ---------------------------------------------------------------- */
html5jp.graph.circle = function (id) {
	var elm = document.getElementById(id);
	if(! elm) { return; }
	if(elm.nodeName != "CANVAS") { return; }
	if(elm.parentNode.nodeName != "DIV") { return; };
	this.canvas = elm;
	/* CANVAS要素 */
	if ( ! this.canvas ){ return; }
	if ( ! this.canvas.getContext ){ return; }
	/* 2D コンテクストの生成 */
	this.ctx = this.canvas.getContext('2d');
	this.canvas.style.margin = "0";
	this.canvas.parentNode.style.position = "relative";
	this.canvas.parentNode.style.padding = "0";
};
/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
* 描画
* ---------------------------------------------------------------- */
html5jp.graph.circle.prototype.draw = function(items, inparams) {
	if( ! this.ctx ) {return;}
	/* パラメータの初期化 */
	var params = {
		backgroundColor: null,
		shadow: true,
		border: false,
		caption: false,
		captionNum: true,
		captionRate: true,
		fontSize: "12px",
		fontFamily: "Arial,sans-serif",
		textShadow: true,
		captionColor: "#ffffff",
		startAngle: -90,
		legend: true,
		legendFontSize: "12px",
		legendFontFamily: "Arial,sans-serif",
		legendColor: "#000000",
		otherCaption: "other"
	};
	if( inparams && typeof(inparams) == 'object' ) {
		for( var key in inparams ) {
			params[key] = inparams[key];
		}
	}
	this.params = params;
	/* CANVASの背景を塗る */
	if( params.backgroundColor ) {
		this.ctx.beginPath();
		this.ctx.fillStyle = params.backgroundColor;
		this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
	}
	/* CANVAS要素の横幅が縦幅の1.5倍未満、または縦幅が200未満であれば凡例は強制的に非表示 */
	if(this.canvas.width / this.canvas.height < 1.5 || this.canvas.height < 200) {
		params.legend == false;
	}
	/* CANVAS要素の座標 */
	var canvas_pos = this._getElementAbsPos(this.canvas);
	/* 円グラフの中心座標と半径 */
	var cpos = {
		x: this.canvas.width / 2,
		y: this.canvas.height / 2,
		r: Math.min(this.canvas.width, this.canvas.height) * 0.8 / 2
	};
	/* 10項目を超えていれば、10項目目以降を"その他"に統合 */
	items = this._fold_items(items);
	var item_num = items.length;
	/* 凡例表示の場合の円グラフ中心x座標と、凡例の各種座標を算出 */
	if(params.legend == true) {
		/* 円グラフ中心x座標 */
		cpos.x = this.canvas.height * 0.1 + cpos.r;
		/* DIV要素を仮に挿入してみて高さを調べる(1行分の高さ) */
		var tmpdiv = document.createElement('DIV');
		tmpdiv.appendChild( document.createTextNode('あTEST') );
		tmpdiv.style.fontSize = params.legendFontSize;
		tmpdiv.style.fontFamily = params.legendFontFamily;
		tmpdiv.style.color = params.legendColor;
		tmpdiv.style.margin = "0";
		tmpdiv.style.padding = "0";
		tmpdiv.style.visible = "hidden";
		tmpdiv.style.position = "absolute";
		tmpdiv.style.left = canvas_pos.x.toString() + "px";
		tmpdiv.style.top = canvas_pos.y.toString() + "px";
		this.canvas.parentNode.appendChild(tmpdiv);
		/* 凡例の各種座標を算出 */
		var lpos = {
			x: this.canvas.height * 0.2 + cpos.r * 2,
			y: ( this.canvas.height - ( tmpdiv.offsetHeight * item_num + tmpdiv.offsetHeight * 0.2 * (item_num - 1) ) ) / 2,
			h: tmpdiv.offsetHeight
		};
		lpos.cx = lpos.x + lpos.h * 1.4; // 文字表示開始位置(x座標)
		lpos.cw = this.canvas.width - lpos.cx;       // 文字表示幅
		/* 仮に挿入したDIV要素を削除 */
		tmpdiv.parentNode.removeChild(tmpdiv);
	}
	/* 外円の影 */
	if( params.shadow == true ) {
		this._make_shadow(cpos);
	}
	/* 外円を黒で塗りつぶす */
	this.ctx.beginPath();
	this.ctx.arc(cpos.x, cpos.y, cpos.r, 0, Math.PI*2, false)
	this.ctx.closePath();
	this.ctx.fillStyle = "black";
	this.ctx.fill();
	/* 全項目の値の合計を算出 */
	var sum = 0;
	for(var i=0; i<item_num; i++) {
		var n = items[i][1];
		if( isNaN(n) || n <=0 ) {
			throw new Error('invalid graph item data.' + n);
		}
		sum += n;
	}
	if(sum <= 0) {
		throw new Error('invalid graph item data.');
	}
	/* 各項目のデフォルト色を定義 */
	var colors = ["24,41,206", "198,0,148", "214,0,0", "255,156,0", "33,156,0", "33,41,107", "115,0,90", "132,0,0", "165,99,0", "24,123,0"];
	/* 円グラフを描写 */
	var rates = new Array();
	var startAngle = this._degree2radian(params.startAngle);
	for(var i=0; i<item_num; i++) {
		/* 項目の名前 */
		var cap = items[i][0];
		/* 項目の値 */
		var n = items[i][1];
		/* 比率 */
		var r = n / sum;
		/* パーセント */
		var p = Math.round(r * 1000) / 10;
		/* 描写角度（ラジアン） */
		var rad = this._degree2radian(360*r);
		/* 円弧終点角度 */
		endAngle = startAngle + rad;
		/* 円弧を描画 */
		this.ctx.beginPath();
		this.ctx.moveTo(cpos.x,cpos.y);
		this.ctx.lineTo(
			cpos.x + cpos.r * Math.cos(startAngle),
			cpos.y + cpos.r * Math.sin(startAngle)
		);
		this.ctx.arc(cpos.x, cpos.y, cpos.r, startAngle, endAngle, false);
		this.ctx.closePath();
		/* 円グラフの色を特定 */
		var rgb = colors[i];
		var rgbo = this._csscolor2rgb(items[i][2]);
		if(rgbo) {
			rgb = rgbo.r + "," + rgbo.g + "," + rgbo.b;
		}
		/* 円グラフのグラデーションをセット */
		var radgrad = this.ctx.createRadialGradient(cpos.x,cpos.y,0,cpos.x,cpos.y,cpos.r);
		radgrad.addColorStop(0, "rgba(" + rgb + ",1)");
		radgrad.addColorStop(0.7, "rgba(" + rgb + ",0.85)");
		radgrad.addColorStop(1, "rgba(" + rgb + ",0.75)");
		this.ctx.fillStyle = radgrad;
		this.ctx.fill();
		/* 円弧の枠線 */
		if(params.border == true) {
			this.ctx.stroke();
		}
		/* キャプション */
		var drate;
		var fontSize;
		if(r <= 0.03) {
			drate = 1.1;
		} else if(r <= 0.05) {
			drate = 0.9;
		} else if(r <= 0.1) {
			drate = 0.8;
		} else if(r <= 0.15) {
			drate = 0.7;
		} else {
			drate = 0.6;
		}
		var cp = {
			x: cpos.x + (cpos.r * drate) * Math.cos( (startAngle + endAngle) / 2 ),
			y: cpos.y + (cpos.r * drate) * Math.sin( (startAngle + endAngle) / 2 )
		};
		var div = document.createElement('DIV');
		if(r <= 0.05) {
			if(params.captionRate == true) {
				div.appendChild( document.createTextNode( p + "%") );
			}
		} else {
			if(params.caption == true) {
				div.appendChild( document.createTextNode(cap) );
				if(params.captionNum == true || params.captionRate == true) {
					div.appendChild( document.createElement('BR') );
				}
			}
			if(params.captionRate == true) {
				div.appendChild( document.createTextNode( p + "%" ) );
			}
			if(params.captionNum == true) {
				var numCap = n;
				if(params.caption == true || params.captionRate == true) {
					numCap = "(" + numCap + ")";
				}
				div.appendChild( document.createTextNode( numCap ) );
			}
		}
		div.style.position = 'absolute';
		div.style.textAlign = 'center';
		div.style.color = params.captionColor;
		div.style.fontSize = params.fontSize;
		div.style.fontFamily = params.fontFamily;
		div.style.margin = "0";
		div.style.padding = "0";
		div.style.visible = "hidden";
		if( params.textShadow == true ) {
			var dif = [ [ 0,  1], [ 0, -1], [ 1,  0], [ 1,  1], [ 1, -1], [-1,  0], [-1,  1], [-1, -1] ];
			for(var j=0; j<8; j++) {
				var s = div.cloneNode(true);
				this.canvas.parentNode.appendChild(s);
				s.style.color = "black";
				s.style.left = (parseFloat(cp.x - s.offsetWidth / 2 + dif[j][0])).toString() + "px";
				s.style.top = (cp.y - s.offsetHeight / 2 + dif[j][1]).toString() + "px";
			}
		}
		this.canvas.parentNode.appendChild(div);
		div.style.left = (cp.x - div.offsetWidth / 2).toString() + "px";
		div.style.top = (cp.y - div.offsetHeight / 2).toString() + "px";
		/* 凡例 */
		if(params.legend == true) {
			/* 文字 */
			var ltxt = document.createElement('DIV');
			ltxt.appendChild( document.createTextNode(cap) );
			ltxt.style.position = "absolute";
			ltxt.style.fontSize = params.legendFontSize;
			ltxt.style.fontFamily = params.legendFontFamily;
			ltxt.style.color = params.legendColor;
			ltxt.style.margin = "0";
			ltxt.style.padding = "0";
			ltxt.style.left = lpos.cx.toString() + "px";
			ltxt.style.top = lpos.y.toString() + "px";
			ltxt.style.width = (lpos.cw).toString() + "px";
			ltxt.style.whiteSpace = "nowrap";
			ltxt.style.overflow = "hidden";
			this.canvas.parentNode.appendChild(ltxt);
			/* 記号の影 */
			if( params.shadow == true ) {
				this.ctx.beginPath();
				this.ctx.rect(lpos.x+1, lpos.y+1, lpos.h, lpos.h);
				this.ctx.fillStyle = "#222222";
				this.ctx.fill();
			}
			/* 記号 */
			this.ctx.beginPath();
			this.ctx.rect(lpos.x, lpos.y, lpos.h, lpos.h);
			this.ctx.fillStyle = "black";
			this.ctx.fill();
			this.ctx.beginPath();
			this.ctx.rect(lpos.x, lpos.y, lpos.h, lpos.h);
			var symbolr = {
				x: lpos.x + lpos.h / 2,
				y: lpos.y + lpos.h / 2,
				r: Math.sqrt(lpos.h * lpos.h * 2) / 2
			};
			var legend_radgrad = this.ctx.createRadialGradient(symbolr.x,symbolr.y,0,symbolr.x,symbolr.y,symbolr.r);
			legend_radgrad.addColorStop(0, "rgba(" + rgb + ",1)");
			legend_radgrad.addColorStop(0.7, "rgba(" + rgb + ",0.85)");
			legend_radgrad.addColorStop(1, "rgba(" + rgb + ",0.75)");
			this.ctx.fillStyle = legend_radgrad;
			this.ctx.fill();
			/* */
			lpos.y = lpos.y + lpos.h * 1.2;
		}
		/* */
		startAngle = endAngle;
	}
};

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
* 以下、内部関数
* ──────────────────────────────── */

/* ------------------------------------------------------------------
項目を10項目以内にまとめる
* ---------------------------------------------------------------- */
html5jp.graph.circle.prototype._fold_items = function(items) {
	var len = items.length;
	if(len <= 10) { return items; }
	var n = 0;
	for( var i=9; i<len; i++ ) {
		n += items[i][1];
	}
	var newitems = items.slice(0, 10);
	newitems[9] = [this.params.otherCaption, n];
	return newitems;
};

/* ------------------------------------------------------------------
ブラウザー表示領域左上端を基点とする座標系におけるelmの左上端の座標
* ---------------------------------------------------------------- */
html5jp.graph.circle.prototype._getElementAbsPos = function(elm) {
	var obj = new Object();
	obj.x = elm.offsetLeft;
	obj.y = elm.offsetTop;
	while(elm.offsetParent) {
		elm = elm.offsetParent;
		obj.x += elm.offsetLeft;
		obj.y += elm.offsetTop;
	}
	return obj;
};

/* ------------------------------------------------------------------
* シャドーの生成
* ---------------------------------------------------------------- */
html5jp.graph.circle.prototype._make_shadow = function (cpos) {
	this.ctx.beginPath();
	this.ctx.arc(cpos.x+5, cpos.y+5, cpos.r, 0, Math.PI*2, false)
	this.ctx.closePath();
	var radgrad = this.ctx.createRadialGradient(cpos.x+5,cpos.y+5,0,cpos.x+5,cpos.y+5,cpos.r);
	if(document.uniqueID) {
		radgrad.addColorStop(0, '#555555');
	} else {
		radgrad.addColorStop(0, 'rgba(0,0,0,1)');
		radgrad.addColorStop(0.93, 'rgba(0,0,0,1)');
		radgrad.addColorStop(1, 'rgba(0,0,0,0)');
	}
	this.ctx.fillStyle = radgrad;
	this.ctx.fill();
};

/* ------------------------------------------------------------------
* 角度の度をラジアンに変換
* ---------------------------------------------------------------- */
html5jp.graph.circle.prototype._degree2radian = function (degree) {
	return (Math.PI/180) * degree;
};

/* ------------------------------------------------------------------
* CSS色文字列をRGBに変換
* ---------------------------------------------------------------- */
html5jp.graph.circle.prototype._csscolor2rgb = function (c) {
	if( ! c ) { return null; }
	var color_map = {
		black: "#000000",
		gray: "#808080",
		silver: "#c0c0c0",
		white: "#ffffff",
		maroon: "#800000",
		red: "#ff0000",
		purple: "#800080",
		fuchsia: "#ff00ff",
		green: "#008000",
		lime: "#00FF00",
		olive: "#808000",
		yellow: "#FFFF00",
		navy: "#000080",
		blue: "#0000FF",
		teal: "#008080",
		aqua: "#00FFFF"
	};
	c = c.toLowerCase();
	var o = new Object();
	if( c.match(/^[a-zA-Z]+$/) && color_map[c] ) {
		c = color_map[c];
	}
	var m = null;
	if( m = c.match(/^\#([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i) ) {
		o.r = parseInt(m[1], 16);
		o.g = parseInt(m[2], 16);
		o.b = parseInt(m[3], 16);
	} else if( m = c.match(/^\#([a-f\d]{1})([a-f\d]{1})([a-f\d]{1})$/i) ) {
		o.r = parseInt(m[1]+"0", 16);
		o.g = parseInt(m[2]+"0", 16);
		o.b = parseInt(m[3]+"0", 16);
	} else if( m = c.match(/^rgba*\(\s*(\d+),\s*(\d+),\s*(\d+)/i) ) {
		o.r = m[1];
		o.g = m[2];
		o.b = m[3];
	} else if( m = c.match(/^rgba*\(\s*(\d+)\%,\s*(\d+)\%,\s*(\d+)\%/i) ) {
		o.r = Math.round(m[1] * 255 / 100);
		o.g = Math.round(m[2] * 255 / 100);
		o.b = Math.round(m[3] * 255 / 100);
	} else {
		return null;
	}
	return o;
};

