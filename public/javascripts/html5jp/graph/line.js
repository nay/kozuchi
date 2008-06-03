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
html5jp.graph.line = function (id) {
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
html5jp.graph.line.prototype.draw = function(items, inparams) {
	if( ! this.ctx ) {return;}
	/* パラメータの初期化 */
	var params = {
		x: [],
		y: [],
		yMax: null,
		yMin: 0,
		backgroundColor: "#ffffff",
		gbackgroundColor: "#dddddd",
		gGradation: true,
		lineWidth: 1,
		dotRadius: 3,
		dotType: "disc",
		hLineWidth: 2,
		hLineType: "dotted",
		hLineColor: "#aaaaaa",
		xAxisWidth: 2,
		xAxisColor: "#000000",
		yAxisWidth: 2,
		yAxisColor: "#000000",
		xScaleColor: "#000000",
		xScaleFontSize: "10px",
		xScaleFontFamily: "Arial,sans-serif",
		yScaleColor: "#000000",
		yScaleFontSize: "10px",
		yScaleFontFamily: "Arial,sans-serif",
		xCaptionColor: "#000000",
		xCaptionFontSize: "12px",
		xCaptionFontFamily: "Arial,sans-serif",
		yCaptionColor: "#000000",
		yCaptionFontSize: "12px",
		yCaptionFontFamily: "Arial,sans-serif",
		dLabel: true,
		dLabelColor: "#000000",
		dLabelFontSize: "10px",
		dLabelFontFamily: "Arial,sans-serif",
		legend: true,
		legendFontSize: "12px",
		legendFontFamily: "Arial,sans-serif",
		legendColor: "#000000"
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
	/* 折線グラフの軸のcanvas内座標 */
	var cpos = {
		x0: this.canvas.width * 0.1,
		y0: this.canvas.height * 0.9,
		x1: this.canvas.width * 0.9,
		y1: this.canvas.height * 0.1
	};
	if( typeof(params.x) == "object" && params.x.length > 0) {
		cpos.y0 = this.canvas.height * 0.8;
	}
	if( typeof(params.y) == "object" && params.y.length > 0) {
		cpos.x0 = this.canvas.width * 0.15;
		cpos.y1 = this.canvas.height * 0.15
	}
	if(params.legend == true) {
		cpos.x1 = this.canvas.width * 0.7;
	}
	cpos.w = cpos.x1 - cpos.x0;
	cpos.h = cpos.y0 - cpos.y1;
	/* 項目の数（最大10個）*/
	var item_num = items.length;
	if(item_num > 10) { item_num = 10; }
	/* 凡例の各種座標を算出 */
	if(params.legend == true) {
		/* DIV要素を仮に挿入してみて高さを調べる(1行分の高さ) */
		var legend_tmp_s = this._getTextBoxSize('あTEST', params.legendFontSize, params.legendFontFamily);
		/* 凡例の各種座標を算出 */
		var lpos = {
			x: Math.round( cpos.x1 + this.canvas.width * 0.03 ),
			y: Math.round( ( this.canvas.height - ( legend_tmp_s.h * item_num + legend_tmp_s.h * 0.2 * (item_num - 1) ) ) / 2 ),
			h: legend_tmp_s.h
		};
		lpos.cx = lpos.x + Math.round( lpos.h * 2.5 ); // 文字表示開始位置(x座標)
		lpos.cw = this.canvas.width - lpos.cx;       // 文字表示幅
	}
	/* グラフの背景を塗りつぶす */
	if(params.gGradation == true) {
		this.ctx.beginPath();
		this.ctx.moveTo(cpos.x0, cpos.y0);
		this.ctx.lineTo(cpos.x1, cpos.y0);
		this.ctx.lineTo(cpos.x1, cpos.y1);
		this.ctx.lineTo(cpos.x0, cpos.y1);
		this.ctx.closePath();
		var radgrad = this.ctx.createLinearGradient(cpos.x0,cpos.y1,cpos.x0,cpos.y0);
		var o_gbc = this._csscolor2rgb(params.gbackgroundColor);
		var gbc = o_gbc.r + "," + o_gbc.g + "," + o_gbc.b;
		radgrad.addColorStop(0, "rgb(" + gbc + ")");
		radgrad.addColorStop(1, "rgb(255,255,255)");
		this.ctx.fillStyle = radgrad;
		this.ctx.fill();
	} else {
		this.ctx.fillStyle = params.gbackgroundColor;
		this.ctx.fillRect(cpos.x0, cpos.y1, cpos.w, cpos.h);
	}
	/* 全項目の最大値・最小値と項目数を算出 */
	var max_v = null;
	var min_v = null;
	var max_n = 0;
	if(params.y.length > 1) {
		max = params.y[ params.y.length - 1 ];
	}
	for(var i=0; i<item_num; i++) {
		var n = items[i].length;
		if(n < 2) { continue; }
		for(var j=1; j<n; j++) {
			var v = items[i][j];
			if( isNaN(v) ) {
				throw new Error('invalid graph item data.' + n);
			}
			if(max_v == null) {
				max_v = v;
			} else if(v >= max_v) {
				max_v = v;
			}
			if(min_v == null) {
				min_v = v;
			} else if(v <= min_v) {
				min_v = v;
			}
		}
		if(n - 1 >= max_n) {
			max_n = n - 1;
		}
	}
	if( typeof(params.yMin) != "number" ) {
		params.yMin = 0;
	}
	if( typeof(params.yMax) != "number" ) {
		params.yMax = max_v + Math.abs(max_v - min_v) * 0.1;
	}
	var v_range = Math.abs( params.yMax - params.yMin );
	/* 水平補助線 */
	if( typeof(params.hLineWidth) == "number" && params.hLineWidth > 0 ) {
		var h_line_type = "dashed";
		if( params.hLineType.match(/^(solid|dashed|dotted)$/i) ) {
			h_line_type = params.hLineType;
		}
		for(var i=1; i<params.y.length; i++) {
			var aline_x0 = cpos.x0;
			var aline_y0 = Math.round( cpos.y0 - cpos.h * ( params.y[i] - params.yMin ) / v_range );
			var aline_x1 = cpos.x1;
			this._draw_h_aline(aline_x0, aline_y0, aline_x1, params.hLineWidth, h_line_type, params.hLineColor);
		}
	}
	/* 各項目のデフォルト色を定義 */
	var colors = ["24,41,206", "198,0,148", "214,0,0", "255,156,0", "33,156,0", "33,41,107", "115,0,90", "132,0,0", "165,99,0", "24,123,0"];
	/* 折線グラフを描写 */
	var plots = new Array();
	for(var i=0; i<item_num; i++) {
		this.ctx.beginPath();
		this.ctx.lineJoin = "round";
		plots[i] = new Array();
		var n = items[i].length;
		for(var j=1; j<n; j++) {
			/* 項目の値 */
			var v = items[i][j];
			/* canvas座標を算出 */
			var p = {
				x: Math.round( cpos.x0 + cpos.w * ( j - 0.5 ) / max_n ),
				y: Math.round( cpos.y0 - cpos.h * ( v - params.yMin ) / v_range ),
				v: v
			}
			plots[i].push(p);
			/* 線を描画 */
			if(j == 1) {
				this.ctx.moveTo(p.x, p.y);
			} else {
				this.ctx.lineTo(p.x, p.y);
			}
		}
		/* 線の太さを定義 */
		var line_width = 1;
		if( typeof(params.lineWidth) == "object" && ! isNaN(params.lineWidth[i])) {
			line_width = params.lineWidth[i];
		} else if( typeof(params.lineWidth) == "number" && ! isNaN(params.lineWidth)) {
			line_width = params.lineWidth;
		}
		this.ctx.lineWidth = line_width;
		/* 線の色を定義 */
		var line_color = "rgb(" + colors[i] + ")";
		this.ctx.strokeStyle = line_color;
		/* 線を描画 */
		this.ctx.stroke();
		/* ドットの半径を特定 */
		var dot_rad = null;
		if( typeof(params.dotRadius) == "object" && ! isNaN(params.dotRadius[i]) && params.dotRadius[i] > 0 ) {
			dot_rad = params.dotRadius[i];
		} else if( typeof(params.dotRadius) == "number" && ! isNaN(params.dotRadius) && params.dotRadius > 0 ) {
			dot_rad = params.dotRadius;
		}
		/* ドットのタイプを特定 */
		var dot_type = null;
		if( typeof(params.dotType) == "object" && typeof(params.dotType[i]) == "string" ) {
			dot_type = params.dotType[i];
		} else if( typeof(params.dotType) == "string" ) {
			dot_type = params.dotType;
		} else {
			dot_type = "disc";
		}
		/* ドットを描画 */
		if(dot_rad > 0) {
			for(var k=0; k<plots[i].length; k++) {
				this._draw_dot(plots[i][k].x, plots[i][k].y, dot_rad, dot_type, colors[i]);
			}
		}
		/* データラベルを描画 */
		if(params.dLabel == true) {
			for(var k=0; k<plots[i].length; k++) {
				if(plots[i][k].x < cpos.x0 || plots[i][k].x > cpos.x1 || plots[i][k].y > cpos.y0 || plots[i][k].y < cpos.y1) {
					continue;
				}
				var dlabel = plots[i][k].v.toString();
				var margin = 1;
				if(dot_rad != null && dot_rad > 0) {
					margin += dot_rad;
				}
				var s = this._getTextBoxSize(dlabel, params.dLabelFontSize, params.dLabelFontFamily);
				var dlabel_x = plots[i][k].x - Math.round( s.w / 2 );
				var dlabel_y = plots[i][k].y - Math.round( s.h ) - margin;
				this._drawText(dlabel_x, dlabel_y, dlabel, params.dLabelFontSize, params.dLabelFontFamily, params.dLabelColor);
			}
		}
		/* 凡例を描画 */
		if(params.legend == true) {
			/* 文字 */
			this._drawText(lpos.cx, lpos.y, items[i][0], params.legendFontSize, params.legendFontFamily, params.legendColor);
			/* 記号（罫線） */
			this._draw_h_aline(lpos.x, Math.round(lpos.y+lpos.h/2), lpos.x + lpos.h*2, line_width, "solid", line_color);
			/* 記号（ドット） */
			if(dot_rad > 0) {
				this._draw_dot(Math.round(lpos.x+lpos.h), Math.round(lpos.y+lpos.h/2), dot_rad, dot_type, colors[i]);
			}
			/* */
			lpos.y = lpos.y + lpos.h * 1.2;
		}
	}
	/* グラフ描画領域外の上下を背景色で塗りつぶす */
	this.ctx.fillStyle = params.backgroundColor;
	this.ctx.fillRect(cpos.x0, 0, cpos.w, cpos.y1);
	this.ctx.fillRect(cpos.x0, cpos.y0, cpos.w, this.canvas.height - cpos.y0);
	/* x軸 */
	if( typeof(params.xAxisWidth) == "number" && params.xAxisWidth > 0 ) {
		this._draw_h_aline(cpos.x0, cpos.y0, cpos.x1, params.xAxisWidth, "solid", params.xAxisColor);
	}
	/* y軸 */
	if( typeof(params.yAxisWidth) == "number" && params.yAxisWidth > 0 ) {
		this._draw_v_aline(cpos.x0, cpos.y0, cpos.y1, params.yAxisWidth, "solid", params.yAxisColor);
	}
	/* x軸の目盛文字列を描画 */
	var xscale_y_under = 0;
	for(var i=1; i<=max_n; i++) {
		if( typeof(params.x[i] ) != "string" ) { continue; }
		if(params.x[i] == "") { continue; }
		var s = this._getTextBoxSize(params.x[i], params.xScaleFontSize, params.xScaleFontFamily);
		var xscale_x = Math.round( cpos.x0 + cpos.w * ( i - 0.5 ) / max_n ) - Math.round( s.w / 2 );
		var xscale_y = cpos.y0 + 5;
		this._drawText(xscale_x, xscale_y, params.x[i], params.xScaleFontSize, params.xScaleFontFamily, params.xScaleColor);
		if(xscale_y + s.h >= xscale_y_under) {
			xscale_y_under = xscale_y + s.h;
		}
	}
	/* y軸の目盛数値を描画 */
	var yscale_y_top = this.canvas.height;
	for(var i=1; i<params.y.length; i++) {
		if( typeof(params.y[i] ) != "number" ) { continue; }
		var v = params.y[i].toString();
		if(v == "") { continue; }
		if(params.y[i] < params.yMin || params.y[i] > params.yMax) { continue; }
		var s = this._getTextBoxSize(v, params.yScaleFontSize, params.yScaleFontFamily);
		var yscale_y = Math.round( cpos.y0 - cpos.h * ( params.y[i] - params.yMin ) / v_range ) - Math.round( s.h / 2 );
		var yscale_x = Math.round( cpos.x0 - s.w ) - 5;
		this._drawText(yscale_x, yscale_y, v, params.yScaleFontSize, params.yScaleFontFamily, params.yScaleColor);
		if(yscale_y <= yscale_y_top) {
			yscale_y_top = yscale_y;
		}
	}
	/* x軸のキャプションを描画 */
	if( typeof(params.x[0]) == "string" && params.x[0] != "" ) {
		var s = this._getTextBoxSize(params.x[0], params.xCaptionFontSize, params.xCaptionFontFamily);
		var xcaption_y = cpos.y0 + 5;
		if(xscale_y_under > 0) {
			xcaption_y = xscale_y_under + 5;
		}
		var xcaption_x = Math.round( cpos.x0 + ( cpos.w / 2 ) - ( s.w / 2 ) );
		this._drawText(xcaption_x, xcaption_y, params.x[0], params.xCaptionFontSize, params.xCaptionFontFamily, params.xCaptionColor);
	}
	/* y軸のキャプションを描画 */
	if( typeof(params.y[0]) == "string" && params.y[0] != "" ) {
		var s = this._getTextBoxSize(params.y[0], params.yCaptionFontSize, params.yCaptionFontFamily);
		var ycaption_y = yscale_y_top - s.h - 5;
		if(yscale_y_top > cpos.y1) {
			ycaption_y = cpos.y1 - s.h - 5;
		}
		var ycaption_x = Math.round( cpos.x0 - ( s.w / 2 ) );
		if(ycaption_x < 5) {
			ycaption_x = 5;
		}
		this._drawText(ycaption_x, ycaption_y, params.y[0], params.yCaptionFontSize, params.yCaptionFontFamily, params.yCaptionColor);
	}
};

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
* 以下、内部関数
* ──────────────────────────────── */

/* ------------------------------------------------------------------
垂直補助線を描画
* ---------------------------------------------------------------- */
html5jp.graph.line.prototype._draw_v_aline = function(x0, y0, y1, width, type, color) {
	color = this._csscolor2rgb(color);
	this.ctx.beginPath();
	color = "rgb(" + color.r + "," + color.g + "," + color.b + ")"
	this.ctx.strokeStyle = color;
	this.ctx.lineWidth = width;
	if(type == "solid") {
		this.ctx.moveTo(x0, y0);
		this.ctx.lineTo(x0, y1);
		this.ctx.stroke();
	} else if( type == "dashed" || (type == "dotted" && width < 2) ) {
		var y = y0;
		while(1) {
			if(y - width*4 < y1) { break; }
			this.ctx.moveTo(x0, y);
			y = y - width * 4;
			this.ctx.lineTo(x0, y);
			this.ctx.stroke();
			if(y - width*2 < y1) { break; }
			y = y - width*2;
		}
	} else if(type == "dotted") {
		this.ctx.fillStyle = color;
		var y = y0;
		while(1) {
			if(y - width*2 < y1) { break; }
			this.ctx.arc(x0, y, width/2, 0, Math.PI*2, false);
			this.ctx.fill();
			if(y - width*2 < y1) { break; }
			y = y - width*2;
		}
	}
};
/* ------------------------------------------------------------------
水平補助線を描画
* ---------------------------------------------------------------- */
html5jp.graph.line.prototype._draw_h_aline = function(x0, y0, x1, width, type, color) {
	color = this._csscolor2rgb(color);
	this.ctx.beginPath();
	color = "rgb(" + color.r + "," + color.g + "," + color.b + ")"
	this.ctx.strokeStyle = color;
	this.ctx.lineWidth = width;
	if(type == "solid") {
		this.ctx.moveTo(x0, y0);
		this.ctx.lineTo(x1, y0);
		this.ctx.stroke();
	} else if( type == "dashed" || (type == "dotted" && width < 2) ) {
		var x = x0;
		while(1) {
			if(x + width*4 > x1) { break; }
			this.ctx.moveTo(x, y0);
			x = x + width * 4;
			this.ctx.lineTo(x, y0);
			this.ctx.stroke();
			if(x + width*2 > x1) { break; }
			x = x + width*2;
		}
	} else if(type == "dotted") {
		this.ctx.fillStyle = color;
		var x = x0;
		while(1) {
			if(x + width*2 > x1) { break; }
			this.ctx.arc(x, y0, width/2, 0, Math.PI*2, false);
			this.ctx.fill();
			if(x + width*2 > x1) { break; }
			x = x + width*2;
		}
	}
};
/* ------------------------------------------------------------------
折線のドットを描画
* ---------------------------------------------------------------- */
html5jp.graph.line.prototype._draw_dot = function(x, y, rad, type, color) {
	this.ctx.beginPath();
	this.ctx.fillStyle = "rgb(" + color + ")";
	if( type == "disc" ) {
		this.ctx.arc(x, y, rad, 0, Math.PI*2, false);
	} else if( type == "square" ) {
		this.ctx.moveTo(x-rad, y-rad);
		this.ctx.lineTo(x+rad, y-rad);
		this.ctx.lineTo(x+rad, y+rad);
		this.ctx.lineTo(x-rad, y+rad);
	} else if( type == "triangle" ) {
		this.ctx.moveTo(x, y-rad);
		this.ctx.lineTo(x+rad, y+rad);
		this.ctx.lineTo(x-rad, y+rad);
	} else if( type == "i-triangle" ) {
		this.ctx.moveTo(x, y+rad);
		this.ctx.lineTo(x+rad, y-rad);
		this.ctx.lineTo(x-rad, y-rad);
	} else if( type == "diamond" ) {
		this.ctx.moveTo(x, y-rad);
		this.ctx.lineTo(x+rad, y);
		this.ctx.lineTo(x, y+rad);
		this.ctx.lineTo(x-rad, y);
	} else {
		this.ctx.arc(x, y, rad, 0, Math.PI*2, false);
	}
	this.ctx.closePath();
	this.ctx.fill();
};

/* ------------------------------------------------------------------
文字列を描画
* ---------------------------------------------------------------- */
html5jp.graph.line.prototype._drawText = function(x, y, text, font_size, font_family, color) {
	var div = document.createElement('DIV');
	div.appendChild( document.createTextNode(text) );
	div.style.fontSize = font_size;
	div.style.fontFamily = font_family;
	div.style.color = color;
	div.style.margin = "0";
	div.style.padding = "0";
	div.style.position = "absolute";
	div.style.left = x.toString() + "px";
	div.style.top = y.toString() + "px";
	this.canvas.parentNode.appendChild(div);
}
/* ------------------------------------------------------------------
文字列表示領域のサイズを取得
* ---------------------------------------------------------------- */
html5jp.graph.line.prototype._getTextBoxSize = function(text, font_size, font_family) {
	var tmpdiv = document.createElement('DIV');
	tmpdiv.appendChild( document.createTextNode(text) );
	tmpdiv.style.fontSize = font_size;
	tmpdiv.style.fontFamily = font_family;
	tmpdiv.style.margin = "0";
	tmpdiv.style.padding = "0";
	tmpdiv.style.visible = "hidden";
	tmpdiv.style.position = "absolute";
	tmpdiv.style.left = "0px";
	tmpdiv.style.top = "0px";
	this.canvas.parentNode.appendChild(tmpdiv);
	var o = {
		w: tmpdiv.offsetWidth,
		h: tmpdiv.offsetHeight
	};
	tmpdiv.parentNode.removeChild(tmpdiv);
	return o;
}

/* ------------------------------------------------------------------
ブラウザー表示領域左上端を基点とする座標系におけるelmの左上端の座標
* ---------------------------------------------------------------- */
html5jp.graph.line.prototype._getElementAbsPos = function(elm) {
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
* CSS色文字列をRGBに変換
* ---------------------------------------------------------------- */
html5jp.graph.line.prototype._csscolor2rgb = function (c) {
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

