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
html5jp.graph.radar = function (id) {
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
html5jp.graph.radar.prototype.draw = function(items, inparams) {
	if( ! this.ctx ) {return;}
	/* パラメータの初期化 */
	var params = {
		aCap: [],
		aCapColor: "#000000",
		aCapFontSize: "12px",
		aCapFontFamily: "Arial,sans-serif",
		aMax: null,
		aMin: 0,
		backgroundColor: "#ffffff",
		cBackgroundColor: "#eeeeee",
		cBackgroundGradation: true,
		chartShape: "polygon",
		faceColors: null,
		_faceColors: ["rgb(24,41,206)", "rgb(198,0,148)", "rgb(214,0,0)", "rgb(255,156,0)", "rgb(33,156,0)", "rgb(33,41,107)", "rgb(115,0,90)", "rgb(132,0,0)", "rgb(165,99,0)", "rgb(24,123,0)"],
		faceAlpha: 0.1,
		borderAlpha: 0.5,
		borderWidth: 1,
		axisColor: "#aaaaaa",
		axisWidth: 1,
		aLinePositions: "auto",
		aLineWidth: 1,
		aLineColor: "#cccccc",
		sLabel: true,
		sLabelColor: "#000000",
		sLabelFontSize: "10px",
		sLabelFontFamily: "Arial,sans-serif",
		legend: true,
		legendFontSize: "12px",
		legendFontFamily: "Arial,sans-serif",
		legendColor: "#000000"
	};
	if( inparams && typeof(inparams) == 'object' ) {
		for( var key in inparams ) {
			if( key.match(/^_/) ) { continue; }
			params[key] = inparams[key];
		}
	}
	if( params.faceColors != null && params.faceColors.length > 0 ) {
		for( var i=0; i<params._faceColors.length; i++ ) {
			var c = params.faceColors[i];
			var co = this._csscolor2rgb(c);
			if( co == null ) {
				params.faceColors[i] = params._faceColors[i];
			} else {
				params.faceColors[i] = c;
			}
		}
	} else {
		params.faceColors = params._faceColors;
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
	/* チャートの中心座標と半径 */
	var cpos = {
		x: this.canvas.width / 2,
		y: this.canvas.height / 2,
		r: Math.min(this.canvas.width, this.canvas.height) * 0.75 / 2
	};
	if(params.legend == true) {
		cpos.r = Math.min(this.canvas.width, this.canvas.height) * 0.7 / 2
		cpos.x = this.canvas.height * 0.1 + cpos.r;
	}
	/* 項目の数（最大10個）*/
	var item_num = items.length;
	if(item_num > 10) { item_num = 10; }
	params.itemNum = item_num;
	/* 指標の最大数を算出（多角形の角数） 最小3角・最大24角*/
	var angle_num = 0;
	for(var i=0; i<items.length; i++) {
		var n = items[i].length;
		if(angle_num <= n - 1) {
			angle_num = n - 1;
		}
	}
	if(angle_num < 3) {
		angle_num = 3;
	} else if(angle_num > 24) {
		angle_num = 24;
	}
	params.angleNum = angle_num;
	/* 各軸の角度（ラジアン）を算出（右方向を0度とし反時計回りの角度） */
	var axis_angles = [Math.PI/2];
	for(var i=1; i<angle_num; i++) {
		axis_angles.push( Math.PI / 2 - Math.PI * 2 * i / angle_num );
	}
	/* チャートの形状を描画 */
	this._draw_chart_shape(params, cpos, axis_angles);
	/* 全項目の最大値・最小値と項目数を算出 */
	var max_v = null;
	var min_v = null;
	var max_n = 0;
	for(var i=0; i<item_num; i++) {
		var n = items[i].length;
		for(var j=1; j<n; j++) {
			var v = items[i][j];
			if( isNaN(v) ) {
				throw new Error('Item data is invalid. : ' + n);
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
	if( typeof(params.aMin) != "number" ) {
		params.aMin = 0;
	}
	if( typeof(params.aMax) != "number" ) {
		params.aMax = max_v;
	}
	/* 補助線の位置を自動算出 */
	if( typeof(params.aLinePositions) == "string" && params.aLinePositions == "auto" ) {
		params.aLinePositions = this._aline_positions_auto_calc(params.aMin, params.aMax);
	}
	/* 補助線を描画 */
	this._draw_aline(params, cpos, axis_angles);
	/* 軸を描画 */
	this._draw_axis(params, cpos, axis_angles);
	/* スケールラベルを描画 */
	this._draw_scale_label(params, cpos);
	/* 各項目のデフォルト色を定義 */
	/* チャートを描写 */
	for(var i=0; i<items.length; i++) {
		this._draw_radar_chart(params, cpos, axis_angles, items[i], params.faceColors[i]);
	}
	/* キャプションを描画 */
	this._draw_caption(params, cpos, axis_angles);
	/* 凡例を描画 */
	this._draw_legend(items, params, cpos);
};

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
* 以下、内部関数
* ──────────────────────────────── */

/* ------------------------------------------------------------------
補助線の位置を自動算出
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._aline_positions_auto_calc = function(min, max) {
	var range = max - min;
	var power10 = Math.floor( Math.log(range) / Math.log(10) );
	var unit = Math.pow( 10,  power10);
	if( (Math.log(range) / Math.log(10)) % 1 == 0 ) {
		unit = unit / 10;
	}
	var keta_age = 1;
	if(unit < 1) {
		keta_age += Math.abs(power10);
	}
	var p = Math.pow(10, keta_age);
	range = range * p;
	unit = unit * p;
	min = min * p;
	max = max * p;
	var array = [min];
	var unum = range / unit;
	if( unum > 5 ) {
		unit = unit * 2;
	} else if( unum <= 2 ) {
		unit = unit * 3 / 10
	}
	var i = 1;
	while(min+unit*i<=max) {
		array.push(min+unit*i);
		i++;
	}
	for(var i=0; i<array.length; i++) {
		array[i] = array[i] / p;
	}
	return array;
};
/* ------------------------------------------------------------------
凡例を描画
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._draw_legend = function(items, params, cpos) {
	if(params.legend != true) { return; }
	/* DIV要素を仮に挿入してみて高さを調べる(1行分の高さ) */
	var s = this._getTextBoxSize('あTEST', params.legendFontSize, params.legendFontFamily);
	/* 凡例の各種座標を算出 */
	var lpos = {
		x: Math.round( cpos.x + cpos.r + this.canvas.width * 0.15 ),
		y: Math.round( ( this.canvas.height - ( s.h * params.itemNum + s.h * 0.2 * (params.itemNum - 1) ) ) / 2 ),
		h: s.h
	};
	lpos.cx = lpos.x + Math.round( lpos.h * 1.5 ); // 文字表示開始位置(x座標)
	lpos.cw = this.canvas.width - lpos.cx;         // 文字表示幅
	/* 描画 */
	for(var i=0; i<params.itemNum; i++) {
		/* 文字 */
		this._drawText(lpos.cx, lpos.y, items[i][0], params.legendFontSize, params.legendFontFamily, params.legendColor);
		/* 記号（背景） */
		this._make_path_legend_mark(lpos.x, lpos.y, s.h, s.h);
		this.ctx.fillStyle = params.cBackgroundColor;
		this.ctx.fill();
		/* 記号（塗り） */
		this._make_path_legend_mark(lpos.x, lpos.y, s.h, s.h);
		this.ctx.fillStyle = params.faceColors[i];
		this.ctx.globalAlpha = params.faceAlpha;
		this.ctx.fill();
		/* 枠線 */
		this._make_path_legend_mark(lpos.x, lpos.y, s.h, s.h);
		this.ctx.strokeStyle = params.faceColors[i];
		this.ctx.globalAlpha = params.borderAlpha;
		this.ctx.stroke();
		/* */
		lpos.y = lpos.y + lpos.h * 1.2;
	}
};
html5jp.graph.radar.prototype._make_path_legend_mark = function(x,y,w,h) {
	this.ctx.beginPath();
	this.ctx.moveTo(x, y);
	this.ctx.lineTo(x+w, y);
	this.ctx.lineTo(x+w, y+h);
	this.ctx.lineTo(x, y+h);
	this.ctx.closePath();
};
/* ------------------------------------------------------------------
キャプションを描画
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._draw_caption = function(params, cpos, axis_angles) {
	if( typeof(params.aCap) != "object" || params.aCap.length < 1 ) { return; }
	var n = params.aCap.length;
	if(n > params.angleNum) { n = params.angleNum; }
	for(var i=0; i<n; i++) {
		var text = params.aCap[i];
		/* テキスト領域のサイズを算出 */
		var s = this._getTextBoxSize(text, params.aCapFontSize, params.aCapFontFamily);
		/* テキストを描画すべき左上端の座標を算出 */
		var ang = axis_angles[i];
		var x = cpos.x + cpos.r * 1.15 * Math.cos(ang) - s.w / 2;
		var y = cpos.y - cpos.r * 1.15 * Math.sin(ang) - s.h / 2;
		if( x < this.canvas.width * 0.02 ) { x = this.canvas.width * 0.02; }
		if( x + s.w > this.canvas.width * 0.98 ) { x = this.canvas.width * 0.98 - s.w; }
		if( y < this.canvas.height * 0.02 ) { y = this.canvas.height * 0.02; }
		if( y + s.h > this.canvas.height * 0.98 ) { y = this.canvas.height * 0.98 - s.h; }
		x = Math.round(x);
		y = Math.round(y);
		/* テキストを描画 */
		this._drawText(x, y, text, params.aCapFontSize, params.aCapFontFamily, params.aCapColor);
	}
};
/* ------------------------------------------------------------------
スケールラベルを描画
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._draw_scale_label = function(params, cpos) {
	if( params.sLabel != true) { return; }
	if( typeof(params.aLinePositions) != "object" || params.aLinePositions.length < 1 ) { return; }
	for(var i=0; i<params.aLinePositions.length; i++) {
		if( typeof(params.aLinePositions[i]) != "number" ) { continue; }
		if( params.aLinePositions[i] < params.aMin ) { continue; }
		var text = params.aLinePositions[i].toString();
		/* テキスト領域のサイズを算出 */
		var s = this._getTextBoxSize(text, params.sLabelFontSize, params.sLabelFontFamily);
		/* テキストを描画すべき左上端の座標を算出 */
		var x = Math.round( cpos.x - s.w - 3 );
		var y = Math.round( cpos.y - ( ( params.aLinePositions[i] - params.aMin ) * cpos.r / ( params.aMax - params.aMin ) ) - ( s.h / 2 ) );
		/* テキストを描画 */
		this._drawText(x, y, text, params.sLabelFontSize, params.sLabelFontFamily, params.sLabelColor);
	}
};
/* ------------------------------------------------------------------
チャートを描画
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._draw_radar_chart = function(params, cpos, axis_angles, values, color) {
	/* チャート面を塗りつぶす */
	this._make_path_for_radar_chart(params, cpos, axis_angles, values);
	this.ctx.globalAlpha = params.faceAlpha;
	this.ctx.fillStyle = color;
	this.ctx.fill();
	/* チャート境界線を引く */
	this._make_path_for_radar_chart(params, cpos, axis_angles, values);
	this.ctx.globalAlpha = params.borderAlpha;
	this.ctx.lineWidth = params.borderWidth;
	this.ctx.strokeStyle = color;
	this.ctx.stroke();
	/* this.ctx.globalAlpha の値を初期値に戻す */
	this.ctx.globalAlpha = 1;
};
html5jp.graph.radar.prototype._make_path_for_radar_chart = function(params, cpos, axis_angles, values) {
	var r0 = 0;
	if( typeof(values[1]) == "number" ) {
		r0 = cpos.r * (values[1] - params.aMin ) / (params.aMax - params.aMin);
		if( r0 < 0 ) { r0 = 0; }
	}
	this.ctx.beginPath();
	this.ctx.moveTo( Math.round( cpos.x + r0 * Math.cos(axis_angles[0]) ), Math.round( cpos.y - r0 * Math.sin(axis_angles[0]) ) );
	for(var i=1; i<axis_angles.length; i++) {
		var r = 0;
		if( typeof(values[i+1]) == "number" ) {
			r = cpos.r * ( values[i+1] - params.aMin ) / (params.aMax - params.aMin);
			if( r < 0 ) { r = 0; }
		}
		this.ctx.lineTo( Math.round( cpos.x + r * Math.cos(axis_angles[i]) ), Math.round( cpos.y - r * Math.sin(axis_angles[i]) ) );
	}
	this.ctx.closePath();
};
/* ------------------------------------------------------------------
軸を描画
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._draw_axis = function(params, cpos, axis_angles) {
	if( typeof(params.axisWidth) != "number" || params.axisWidth <= 0 ) {
		return;
	}
	for(var i=0; i<axis_angles.length; i++) {
		this.ctx.beginPath();
		this.ctx.lineWidth = params.axisWidth;
		this.ctx.strokeStyle = params.axisColor;
		this.ctx.moveTo(cpos.x, cpos.y);
		this.ctx.lineTo( Math.round( cpos.x + cpos.r * Math.cos(axis_angles[i]) ), Math.round( cpos.y - cpos.r * Math.sin(axis_angles[i]) ) );
		this.ctx.stroke();
	}
};
/* ------------------------------------------------------------------
補助線を描画
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._draw_aline = function(params, cpos, axis_angles) {
	if( typeof(params.aLineWidth) != "number" || params.aLineWidth <= 0 ) {
		return;
	}
	if( typeof(params.aLinePositions) != "object" || params.aLinePositions.length < 1 ) {
		return;
	}
	for(var i=0; i<params.aLinePositions.length; i++) {
		if(params.aLinePositions[i] < params.aMin) { continue; }
		var r = cpos.r * ( params.aLinePositions[i] - params.aMin ) / (params.aMax - params.aMin);
		if( r <= 0 ) { continue; }
		this.ctx.beginPath();
		this.ctx.lineWidth = params.aLineWidth;
		this.ctx.strokeStyle = params.aLineColor;
		if(params.chartShape == "polygon") {
			this.ctx.moveTo( Math.round( cpos.x + r * Math.cos(axis_angles[0]) ), Math.round( cpos.y - r * Math.sin(axis_angles[0]) ) );
			for(var j=1; j<axis_angles.length; j++) {
				this.ctx.lineTo( Math.round( cpos.x + r * Math.cos(axis_angles[j]) ), Math.round( cpos.y - r * Math.sin(axis_angles[j]) ) );
			}
			this.ctx.closePath();
		} else if(params.chartShape == "circle") {
			this.ctx.arc(cpos.x, cpos.y, r, 0, Math.PI*2, false);
		} else {
			throw new Error('Option parameter [chartChape] is invalid. : ' + params.chartShape);
		}
		this.ctx.stroke();
	}
};
/* ------------------------------------------------------------------
チャートの形状を描画
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._draw_chart_shape = function(params, cpos, axis_angles) {
	/* チャート形状の塗り */
	this._make_path_chart_shape(params, cpos, axis_angles);
	this.ctx.fillStyle = params.cBackgroundColor;
	this.ctx.fill();
	/* チャート形状のグラデーション */
	if( params.cBackgroundGradation == true && ! document.uniqueID ) {
		this._make_path_chart_shape(params, cpos, axis_angles);
		var radgrad = this.ctx.createRadialGradient(cpos.x,cpos.y,0,cpos.x,cpos.y,cpos.r);
		radgrad.addColorStop(0, "rgba(0,0,0,0)");
		radgrad.addColorStop(0.8, "rgba(0,0,0,0.01)");
		radgrad.addColorStop(1, "rgba(0,0,0,0.1)");
		this.ctx.fillStyle = radgrad;
		this.ctx.fill();
	}
};
html5jp.graph.radar.prototype._make_path_chart_shape = function(params, cpos, axis_angles) {
	this.ctx.beginPath();
	if(params.chartShape == "circle") {
		this.ctx.arc(cpos.x, cpos.y, cpos.r, 0, Math.PI*2, false);
	} else if(params.chartShape == "polygon") {
		this.ctx.moveTo(cpos.x, cpos.y-cpos.r);
		for(var i=0; i<axis_angles.length; i++) {
			var edge_x = Math.round( cpos.x + cpos.r * Math.cos(axis_angles[i]) );
			var edge_y = Math.round( cpos.y - cpos.r * Math.sin(axis_angles[i]) );
			this.ctx.lineTo(edge_x, edge_y);
		}
		this.ctx.closePath();
	} else {
		throw new Error('Option parameter [chartChape] is invalid. : ' + params.chartShape);
	}
};
/* ------------------------------------------------------------------
文字列を描画
* ---------------------------------------------------------------- */
html5jp.graph.radar.prototype._drawText = function(x, y, text, font_size, font_family, color) {
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
html5jp.graph.radar.prototype._getTextBoxSize = function(text, font_size, font_family) {
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
html5jp.graph.radar.prototype._getElementAbsPos = function(elm) {
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
html5jp.graph.radar.prototype._csscolor2rgb = function (c) {
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

