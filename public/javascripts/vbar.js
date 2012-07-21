// Copyright 2007 futomi  http://www.html5.jp/
// graph_vbar ver 1.0.1  2007-12-17
// since 2007-10-17
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
html5jp.graph.vbar = function (id) {
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
html5jp.graph.vbar.prototype.draw = function(items, inparams) {
	if( ! this.ctx ) {return;}
	this.items = items;
	/* パラメータの初期化 */
	var params = {
		x: [],
		y: [],
		yMax: null,
		yMin: 0,
		backgroundColor: "#ffffff",
		gBackgroundColor: "#dddddd",
		gGradation: true,
		barShape: "square",
		barColors: null,
		_barColors: ["rgb(24,41,206)", "rgb(198,0,148)", "rgb(214,0,0)", "rgb(255,156,0)", "rgb(33,156,0)", "rgb(33,41,107)", "rgb(115,0,90)", "rgb(132,0,0)", "rgb(165,99,0)", "rgb(24,123,0)"],
		barGradation: true,
		barAlpha: 0.7,
		borderAlpha: 0.2,
		xAxisWidth: 1,
		xAxisColor: "#aaaaaa",
		yAxisWidth: 1,
		yAxisColor: "#aaaaaa",
		xScale: true,
		xScaleColor: "#000000",
		xScaleFontSize: "10px",
		xScaleFontFamily: "Arial,sans-serif",
		yScale: true,
		yScaleColor: "#000000",
		yScaleFontSize: "10px",
		yScaleFontFamily: "Arial,sans-serif",
		xCaptionColor: "#000000",
		xCaptionFontSize: "12px",
		xCaptionFontFamily: "Arial,sans-serif",
		yCaptionColor: "#000000",
		yCaptionFontSize: "12px",
		yCaptionFontFamily: "Arial,sans-serif",
		aLineWidth: 1,
		aLineAlpha: 0.2,
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
			if( key.match(/^_/) ) { continue; }
			params[key] = inparams[key];
		}
	}
	if( params.barColors != null && params.barColors.length > 0 ) {
		for( var i=0; i<params._barColors.length; i++ ) {
			var c = params.barColors[i];
			var co = this._csscolor2rgb(c);
			if( co == null ) {
				params.barColors[i] = params._barColors[i];
			} else {
				params.barColors[i] = c;
			}
		}
	} else {
		params.barColors = params._barColors;
	}
	this.params = params;
	/* CANVAS要素の横幅が縦幅の1.5倍未満、または縦幅が200未満であれば凡例は強制的に非表示 */
	if(this.canvas.width / this.canvas.height < 1.5 || this.canvas.height < 200) {
		params.legend == false;
	}
	/* 項目の数（最大10個） */
	var item_num = items.length;
	if(item_num > 10) { item_num = 10; }
	/* 最大項目数を算出 */
	var max_n = 0;
	for(var i=0; i<item_num; i++) {
		var n = items[i].length;
		if(n < 2) { continue; }
		if(n - 1 >= max_n) {
			max_n = n - 1;
		}
	}
	params.max_n = max_n;
	if(max_n == 0) {
		throw new Error('no graph item data.' + n);
	}
	/* 最大値を算出 */
	var max_v = 0;
	for(var i=1; i<=max_n; i++) {
		var n = items.length;
		var sum = 0;
		for(var j=0; j<n; j++) {
			var v = items[j][i];
			if( isNaN(v) || v < 0 ) {
				throw new Error('invalid graph item data.' + n);
			}
			sum += v;
		}
		if(sum >= max_v) {
			max_v = sum;
		}
	}
	if( typeof(params.yMin) != "number" ) {
		params.yMin = 0;
	}
	if( typeof(params.yMax) != "number" ) {
		params.yMax = max_v * 1.1
	} else if( params.yMax <= max_v) {
		params.yMax = max_v;
	}
	/* 補助線の位置を自動算出 */
	if( params.y.length < 2 ) {
		params.aLinePositions = this._aline_positions_auto_calc(params.yMin, params.yMax);
	} else {
		params.aLinePositions = params.y.slice(1);
	}
	/* グラフの軸のcanvas内座標 */
	var cpos = {
		x0: this.canvas.width * 0.05,
		y0: this.canvas.height * 0.95,
		x1: this.canvas.width * 0.95,
		y1: this.canvas.height * 0.05
	};
	if(params.legend == true) {
		cpos.x1 = this.canvas.width * 0.7;
	}
	if(params.x.length > 0) {
		var x_caption_text_size = this._getTextBoxSize("あa", params.xCaptionFontSize, params.xCaptionFontFamily);
		cpos.y0 -= x_caption_text_size.h * 1.5;
		cpos.x_caption_y = cpos.y0 + x_caption_text_size.h/2;
	}
	if(params.xScale == true || params.x.length > 1) {
		var x_scale_text_size = this._getTextBoxSize("あa", params.xScaleFontSize, params.xScaleFontFamily);
		cpos.y0 -= x_scale_text_size.h * 1.5;
		cpos.x_scale_y = cpos.y0 + x_scale_text_size.h * 0.7;
	}
	if(params.y.length > 0) {
		var y_caption_text_size = this._getTextBoxSize("あa", params.yCaptionFontSize, params.yCaptionFontFamily);
		cpos.y1 += y_caption_text_size.h * 1.5;
		cpos.y_caption_y = cpos.y1 - y_caption_text_size.h * 1.5;
	}
	if(params.yScale == true || params.y.length > 1) {
		var y_scale_text_size = this._getTextBoxSize(params.aLinePositions[params.aLinePositions.length-1].toString(), params.yScaleFontSize, params.yScaleFontFamily);
		cpos.x0 += y_scale_text_size.w * 1.1;
	}
	cpos.w = cpos.x1 - cpos.x0;
	cpos.h = cpos.y0 - cpos.y1;
	/* 棒の幅の半径を算出 */
	if(params.barShape == "square") {
		cpos.r = 0.6 * cpos.w / max_n / 2;
	} else {
		cpos.r = 0.7 * cpos.w / max_n / 2;
	}
	if(cpos.r < 5 && cpos.r >=3) {
		params.barShape = "line";
	}
	params.cpos = cpos;
	/* */
	this.params = params;
	/* CANVASの背景を塗る */
	this._draw_canvas_background();
	/* グラフの背景を描画 */
	this._draw_graph_background();
	/* 棒グラフを描写 */
	var x_scale_positions = new Array();
	var d_labels = new Array();
	for(var i=1; i<=max_n; i++) {
		var sum = 0;
		/* x軸座標 */
		var x = cpos.x0 + (i - 0.5) * ( cpos.w / max_n );
		x_scale_positions.push(x);
		/* */
		for(var j=0; j<items.length; j++) {
			/* 項目の値 */
			var v = items[j][i];
			/* 棒の底辺の位置 */
			var y = cpos.y0 - sum * cpos.h / params.yMax;
			/* 棒の高さ */
			var h = v * cpos.h / params.yMax;
			/* 棒を描画 */
			if( params.barShape == "line" ) {
				this._draw_vertical_bar_line(this.ctx, x, y, h, cpos.r, params.barColors[j], params.barAlpha);
			} else if( params.barShape == "flat" ) {
				this._draw_vertical_bar_flat(this.ctx, x, y, h, cpos.r, params.barColors[j], params.barAlpha, params.borderAlpha, params.barGradation);
			} else if( params.barShape == "square" ) {
				this._draw_vertical_bar_square(this.ctx, x, y, h, cpos.r, cpos.r/3, params.barColors[j], params.barAlpha, params.borderAlpha, params.barGradation);
			} else if( params.barShape == "cylinder" ) {
				this._draw_vertical_bar_cylinder(this.ctx, x, y, h, cpos.r, cpos.r/3, params.barColors[j], params.barAlpha, params.borderAlpha, params.barGradation);
			}
			/* 値の和を算出 */
			sum += v;
		}
		d_labels.push( { x:x, v:sum } );
	}
	/* データラベルを描画 */
	this._draw_data_label(d_labels);
	/* x軸目盛とキャプションを表示 */
	this._draw_x_scale_label(x_scale_positions);
	/* y軸目盛とキャプションを表示 */
	this._draw_y_scale_label();
	/* 凡例を描画 */
	this._draw_legend();
};

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
* 以下、内部関数
* ──────────────────────────────── */

/* ------------------------------------------------------------------
データラベルを描画
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_data_label = function(labels) {
	var p = this.params;
	if( p.dLabel != true ) { return; }
	var n = labels.length;
	var pos = new Array();
	var max_w = 0;
	for( var i=0; i<n; i++ ) {
		var text = labels[i].v.toString();
		var s = this._getTextBoxSize(text, p.dLabelFontSize, p.dLabelFontFamily);
		max_w = Math.max(s.w, max_w);
		var dx = labels[i].x - s.w / 2;
		var dy = p.cpos.y0 - labels[i].v * p.cpos.h / p.yMax - s.h * 1.3;
		pos.push( { x:dx, y:dy, text:text } );
	}
	if( max_w < p.cpos.w / n ) {
		for( var i=0; i<n; i++ ) {
			this._drawText(pos[i].x, pos[i].y, pos[i].text, p.dLabelFontSize, p.dLabelFontFamily, p.dLabelColor);
		}
	}
};
/* ------------------------------------------------------------------
凡例を描画
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_legend = function() {
	var p = this.params;
	if(p.legend != true) { return; }
	/* DIV要素を仮に挿入してみて高さを調べる(1行分の高さ) */
	var s = this._getTextBoxSize('あTEST', p.legendFontSize, p.legendFontFamily);
	/* 凡例の各種座標を算出 */
	var item_num = this.items.length;
	var lpos = {
		x: Math.round( p.cpos.x1 + this.canvas.width * 0.05 ),
		y: Math.round( ( this.canvas.height - ( s.h * item_num + s.h * 0.2 * (item_num - 1) ) ) / 2 ),
		h: s.h
	};
	lpos.cx = lpos.x + Math.round( lpos.h * 1.5 ); // 文字表示開始位置(x座標)
	lpos.cw = this.canvas.width - lpos.cx;         // 文字表示幅
	/* 描画 */
	for(var i=0; i<item_num; i++) {
		/* 文字 */
		this._drawText(lpos.cx, lpos.y, this.items[i][0], p.legendFontSize, p.legendFontFamily, p.legendColor);
		/* 記号（背景） */
		this.ctx.save();
		this._make_path_legend_mark(lpos.x, lpos.y, s.h, s.h);
		this.ctx.fillStyle = p.gBackgroundColor;
		this.ctx.fill();
		this.ctx.restore();
		/* 記号（塗り） */
		this.ctx.save();
		this._make_path_legend_mark(lpos.x, lpos.y, s.h, s.h);
		this.ctx.fillStyle = p.barColors[i];
		this.ctx.globalAlpha = p.barAlpha;
		this.ctx.fill();
		this.ctx.restore();
		/* 枠線 */
		this.ctx.save();
		this._make_path_legend_mark(lpos.x, lpos.y, s.h, s.h);
		this.ctx.strokeStyle = p.barColors[i];
		this.ctx.globalAlpha = p.borderAlpha;
		this.ctx.stroke();
		this.ctx.restore();
		/* グラデーション */
		if( ! document.uniqueID && p.barGradation == true ) {
			this.ctx.save();
			this._make_path_legend_mark(lpos.x, lpos.y, s.h, s.h);
			var grad = this.ctx.createLinearGradient(lpos.x, lpos.y, lpos.x+s.h, lpos.y+s.h);
			grad.addColorStop(0, "rgba(0, 0, 0, 0.1)");
			grad.addColorStop(0.3, "rgba(255, 255, 255, 0.1)");
			grad.addColorStop(1, "rgba(0, 0, 0, 0.4)");
			this.ctx.fillStyle = grad;
			this.ctx.fill();
			this.ctx.restore();
		}
		lpos.y = lpos.y + lpos.h * 1.2;
	}
};
html5jp.graph.vbar.prototype._make_path_legend_mark = function(x,y,w,h) {
	this.ctx.beginPath();
	this.ctx.moveTo(x, y);
	this.ctx.lineTo(x+w, y);
	this.ctx.lineTo(x+w, y+h);
	this.ctx.lineTo(x, y+h);
	this.ctx.closePath();
};
/* ------------------------------------------------------------------
補助線の位置を自動算出
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._aline_positions_auto_calc = function(min, max) {
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
y軸目盛とキャプションを表示
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_y_scale_label = function(pos) {
	var p = this.params;
	if( p.y.length > 0 ) {
		/* y軸キャプションテキスト */
		var text = p.y[0].toString();
		if(text != "") {
			/* y軸キャプションテキスト領域のサイズを算出 */
			var s = this._getTextBoxSize(text, p.yCaptionFontSize, p.yCaptionFontFamily);
			/* y軸キャプションテキストを描画すべき左上端の座標を算出 */
			var x = p.cpos.x0 - s.w/2;
			if(x < this.canvas.width*0.05) {
				x = this.canvas.width*0.05;
			}
			/* y軸キャプションテキストを描画 */
			this._drawText(x, p.cpos.y_caption_y, text, p.yCaptionFontSize, p.yCaptionFontFamily, p.yCaptionColor);
		}
	}
	if( p.yScale == true && p.aLinePositions.length > 0 ) {
		for( var i=0; i<p.aLinePositions.length; i++ ) {
			var v = p.aLinePositions[i];
			if(v > p.yMax) { continue; }
			var text = v.toString();
			var s = this._getTextBoxSize(text, p.yScaleFontSize, p.yScaleFontFamily);
			var x = p.cpos.x0 - p.cpos.r/2 - s.w*1.1;
			var y = p.cpos.y0 - v * p.cpos.h / (p.yMax - p.yMin) - s.h/2;
			if( p.barShape == "cylinder" || p.barShape == "square" ) {
				var d = p.cpos.r / 3;
				y += d;
			}
			this._drawText(x, y, text, p.yScaleFontSize, p.yScaleFontFamily, p.yScaleColor);
		}
	}
};
/* ------------------------------------------------------------------
x軸目盛とキャプションを表示
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_x_scale_label = function(pos) {
	var p = this.params;
	if( p.x.length > 0 ) {
		/* x軸キャプションテキスト */
		var text = p.x[0].toString();
		if(text != "") {
			/* x軸キャプションテキスト領域のサイズを算出 */
			var s = this._getTextBoxSize(text, p.xCaptionFontSize, p.xCaptionFontFamily);
			/* x軸キャプションテキストを描画すべき左上端の座標を算出 */
			var x = Math.round( p.cpos.x0 + p.cpos.w/2 - s.w/2 );
			/* x軸キャプションテキストを描画 */
			this._drawText(x, p.cpos.x_caption_y, text, p.xCaptionFontSize, p.xCaptionFontFamily, p.xCaptionColor);
		}
	}
	if( p.xScale == true && p.x.length > 1 ) {
		for(var i=0; i<pos.length; i++) {
			if(i + 1 > p.x.length - 1) { break; }
			/* x軸目盛テキスト */
			var text = p.x[i+1].toString();
			if(text == "") { continue; }
			/* x軸目盛テキスト領域のサイズを算出 */
			var s = this._getTextBoxSize(text, p.xScaleFontSize, p.xScaleFontFamily);
			/* x軸目盛テキストを描画すべき左上端の座標を算出 */
			var x = Math.round( pos[i] - s.w / 2 );
			/* x軸目盛テキストを描画 */
			this._drawText(x, p.cpos.x_scale_y, text, p.xScaleFontSize, p.xScaleFontFamily, p.xScaleColor);
		}
	}
};
/* ------------------------------------------------------------------
グラフの背景を描画
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_graph_background = function() {
	var p = this.params;
	var d = p.cpos.r / 3;
	if(p.barShape == "line" || p.barShape == "flat") {
		this._draw_graph_background_back(p.cpos.x0, p.cpos.y0, p.cpos.w, p.cpos.h);
		/* 軸を描画 */
		this._draw_graph_axis(p.cpos.x0, p.cpos.y0, p.cpos.w, p.cpos.h);
	} else {
		/* 背面 */
		this._draw_graph_background_back(p.cpos.x0+d, p.cpos.y0-d, p.cpos.w, p.cpos.h);
		/* 底面 */
		this.ctx.save();
		this.ctx.beginPath();
		this.ctx.moveTo(p.cpos.x0+d, p.cpos.y0-d);
		this.ctx.lineTo(p.cpos.x0+d+p.cpos.w, p.cpos.y0-d);
		this.ctx.lineTo(p.cpos.x0-d+p.cpos.w, p.cpos.y0+d);
		this.ctx.lineTo(p.cpos.x0-d, p.cpos.y0+d);
		this.ctx.closePath();
		this.ctx.fillStyle = p.gBackgroundColor;
		this.ctx.fill();
		this.ctx.restore();
		/* 底面グラデーション（明） */
		this.ctx.save();
		this.ctx.beginPath();
		this.ctx.moveTo(p.cpos.x0+d, p.cpos.y0-d);
		this.ctx.lineTo(p.cpos.x0+d+p.cpos.w, p.cpos.y0-d);
		this.ctx.lineTo(p.cpos.x0-d+p.cpos.w, p.cpos.y0+d);
		this.ctx.lineTo(p.cpos.x0-d, p.cpos.y0+d);
		this.ctx.closePath();
		this.ctx.fillStyle = "rgba(255,255,255,0.3)";
		this.ctx.fill();
		this.ctx.restore();
		/* 側面 */
		this.ctx.save();
		this.ctx.beginPath();
		this.ctx.moveTo(p.cpos.x0+d, p.cpos.y0-d);
		this.ctx.lineTo(p.cpos.x0-d, p.cpos.y0+d);
		this.ctx.lineTo(p.cpos.x0-d, p.cpos.y0+d-p.cpos.h);
		this.ctx.lineTo(p.cpos.x0+d, p.cpos.y0-d-p.cpos.h);
		this.ctx.closePath();
		this.ctx.fillStyle = p.gBackgroundColor;
		this.ctx.fill();
		this.ctx.restore();
		/* 側面補助線 */
		if(p.aLineWidth > 0) {
			this.ctx.save();
			for( var i=0; i<p.aLinePositions.length; i++ ) {
				if(p.aLinePositions[i] > p.yMax) { continue; }
				var aY = p.cpos.y0 -  p.cpos.h * p.aLinePositions[i] / ( p.yMax - p.yMin );
				aY = Math.round(aY);
				//
				this.ctx.beginPath();
				this.ctx.strokeStyle = "rgba(0,0,0," + p.aLineAlpha + ")";
				this.ctx.lineWidth = p.aLineWidth;
				this.ctx.moveTo(p.cpos.x0+d, aY-d-p.aLineWidth/2);
				this.ctx.lineTo(p.cpos.x0-d, aY+d-p.aLineWidth/2);
				this.ctx.stroke();
				//
				this.ctx.beginPath();
				this.ctx.strokeStyle = "rgba(255,255,255," + p.aLineAlpha + ")";
				this.ctx.lineWidth = p.aLineWidth;
				this.ctx.moveTo(p.cpos.x0+d, aY-d+p.aLineWidth/2);
				this.ctx.lineTo(p.cpos.x0-d, aY+d+p.aLineWidth/2);
				this.ctx.stroke();
			}
			this.ctx.restore();
		}
		/* 側面グラデーション（暗） */
		this.ctx.save();
		this.ctx.beginPath();
		this.ctx.moveTo(p.cpos.x0+d, p.cpos.y0-d);
		this.ctx.lineTo(p.cpos.x0-d, p.cpos.y0+d);
		this.ctx.lineTo(p.cpos.x0-d, p.cpos.y0+d-p.cpos.h);
		this.ctx.lineTo(p.cpos.x0+d, p.cpos.y0-d-p.cpos.h);
		this.ctx.closePath();
		this.ctx.fillStyle = "rgba(0,0,0,0.1)";
		this.ctx.fill();
		this.ctx.restore();
		/* 軸を描画 */
		this._draw_graph_axis(p.cpos.x0-d, p.cpos.y0+d, p.cpos.w, p.cpos.h);
	}
};
html5jp.graph.vbar.prototype._draw_graph_axis = function(x, y, w, h) {
	this.ctx.save();
	var p = this.params;
	/* x軸 */
	this.ctx.beginPath();
	this.ctx.lineWidth = p.xAxisWidth;
	this.ctx.strokeStyle = p.xAxisColor;
	this.ctx.moveTo(x, y);
	this.ctx.lineTo(x+w, y);
	this.ctx.stroke();
	/* y軸 */
	this.ctx.beginPath();
	this.ctx.lineWidth = p.yAxisWidth;
	this.ctx.strokeStyle = p.yAxisColor;
	this.ctx.moveTo(x, y);
	this.ctx.lineTo(x, y-h);
	this.ctx.stroke();
	//
	this.ctx.restore();
};
html5jp.graph.vbar.prototype._draw_graph_background_back = function(x, y, w, h) {
	var p = this.params;
	/* 背景 */
	this.ctx.save();
	this.ctx.fillStyle = p.gBackgroundColor;
	this.ctx.fillRect(x, y-h, w, h);
	this.ctx.beginPath();
	this.ctx.moveTo(x, y);
	this.ctx.lineTo(x+w, y);
	this.ctx.lineTo(x+w, y-h);
	this.ctx.lineTo(x, y-h);
	this.ctx.closePath();
	this.ctx.fill();
	this.ctx.restore();
	/* グラデーション */
	if( p.gGradation == true) {
		this.ctx.save();
		var grad = this.ctx.createLinearGradient(x, y-h, x+w, y);
		grad.addColorStop(0, "rgba(0, 0, 0, 0.1)");
		grad.addColorStop(0.3, "rgba(255, 255, 255, 0.2)");
		if(document.uniqueID ) { grad.addColorStop(0.5, "rgba(255, 255, 255, 0.2)"); }
		grad.addColorStop(1, "rgba(0, 0, 0, 0.3)");
		this.ctx.fillStyle = grad;
		this.ctx.beginPath();
		this.ctx.moveTo(x, y);
		this.ctx.lineTo(x+w, y);
		this.ctx.lineTo(x+w, y-h);
		this.ctx.lineTo(x, y-h);
		this.ctx.closePath();
		if(document.uniqueID ) { this.ctx.globalAlpha = 0.3; }
		this.ctx.fill();
		if(document.uniqueID ) { this.ctx.globalAlpha = 1; }
		this.ctx.restore();
	}
	/* 補助線 */
	if(p.aLineWidth > 0) {
		this.ctx.save();
		for( var i=0; i<p.aLinePositions.length; i++ ) {
			if(p.aLinePositions[i] > p.yMax) { continue; }
			var aY = y -  h * p.aLinePositions[i] / ( p.yMax - p.yMin );
			aY = Math.round(aY);
			//
			this.ctx.beginPath();
			this.ctx.strokeStyle = "rgba(0,0,0," + p.aLineAlpha + ")";
			this.ctx.lineWidth = p.aLineWidth;
			this.ctx.moveTo(x, aY-p.aLineWidth/2);
			this.ctx.lineTo(x+w, aY-p.aLineWidth/2);
			this.ctx.stroke();
			//
			this.ctx.beginPath();
			this.ctx.strokeStyle = "rgba(255,255,255," + p.aLineAlpha + ")";
			this.ctx.lineWidth = p.aLineWidth;
			this.ctx.moveTo(x, aY+p.aLineWidth/2);
			this.ctx.lineTo(x+w, aY+p.aLineWidth/2);
			this.ctx.stroke();
		}
		this.ctx.restore();
	}
};
/* ------------------------------------------------------------------
CANVASの背景を塗る
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_canvas_background = function() {
	var c = this._csscolor2rgb(this.params.backgroundColor);
	if( c != null ) {
		this.ctx.save();
		this.ctx.beginPath();
		this.ctx.fillStyle = this.params.backgroundColor;
		this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
		this.ctx.restore();
	}
};

/* ------------------------------------------------------------------
文字列を描画
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._drawText = function(x, y, text, font_size, font_family, color) {
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
html5jp.graph.vbar.prototype._getTextBoxSize = function(text, font_size, font_family) {
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
html5jp.graph.vbar.prototype._getElementAbsPos = function(elm) {
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
html5jp.graph.vbar.prototype._csscolor2rgb = function (c) {
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
/* ------------------------------------------------------------------
* 垂直棒フラフ（角柱）を描画
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_vertical_bar_square = function(ctx, x, y, h, xr, yr, color, alpha, balpha, bgradation) {
	if( typeof(alpha) != "number" || alpha < 0 || alpha > 1 ) {
		alpha = 1;
	}
	if( typeof(balpha) != "number" || balpha < 0 || balpha > 1 ) {
		balpha = 1;
	}
	var p = {
		f: {
			tl: { x:x-xr-yr, y:y-h+yr },
			tr: { x:x+xr-yr, y:y-h+yr },
			bl: { x:x-xr-yr, y:y+yr },
			br: { x:x+xr-yr, y:y+yr }
		},
		b: {
			tl: { x:x-xr+yr, y:y-h-yr },
			tr: { x:x+xr+yr, y:y-h-yr },
			bl: { x:x-xr+yr, y:y-yr },
			br: { x:x+xr+yr, y:y-yr }
		}
	}
	/* ------------------------------------------------------
	* 背面の境界線
	* ---------------------------------------------------- */
	ctx.save();
	ctx.strokeStyle = "black";
	ctx.globalAlpha = balpha;
	ctx.lineWidth = 1;
	//
	ctx.beginPath();
	ctx.moveTo(p.f.bl.x, p.f.bl.y);
	ctx.lineTo(p.b.bl.x, p.b.bl.y);
	ctx.lineTo(p.b.br.x, p.b.br.y);
	ctx.stroke();
	//
	ctx.beginPath();
	ctx.moveTo(p.b.bl.x, p.b.bl.y);
	ctx.lineTo(p.b.tl.x, p.b.tl.y);
	ctx.stroke();
	//
	ctx.restore();
	/* ------------------------------------------------------
	* 面塗り
	* ---------------------------------------------------- */
	ctx.save();
	ctx.fillStyle = color;
	ctx.globalAlpha = alpha;
	//
	ctx.beginPath();
	ctx.moveTo(p.f.bl.x, p.f.bl.y);
	ctx.lineTo(p.f.tl.x, p.f.tl.y);
	ctx.lineTo(p.b.tl.x, p.b.tl.y);
	ctx.lineTo(p.b.tr.x, p.b.tr.y);
	ctx.lineTo(p.b.br.x, p.b.br.y);
	ctx.lineTo(p.f.br.x, p.f.br.y);
	ctx.closePath();
	ctx.fill();
	//
	ctx.restore();
	/* ------------------------------------------------------
	* 前面の境界線
	* ---------------------------------------------------- */
	ctx.save();
	ctx.strokeStyle = "white";
	ctx.globalAlpha = balpha;
	ctx.lineWidth = 1;
	//
	ctx.beginPath();
	ctx.moveTo(p.f.bl.x, p.f.bl.y);
	ctx.lineTo(p.f.tl.x, p.f.tl.y);
	ctx.lineTo(p.b.tl.x, p.b.tl.y);
	ctx.lineTo(p.b.tr.x, p.b.tr.y);
	ctx.lineTo(p.b.br.x, p.b.br.y);
	ctx.lineTo(p.f.br.x, p.f.br.y);
	ctx.closePath();
	ctx.stroke();
	//
	ctx.beginPath();
	ctx.moveTo(p.f.tl.x, p.f.tl.y);
	ctx.lineTo(p.f.tr.x, p.f.tr.y);
	ctx.lineTo(p.b.tr.x, p.b.tr.y);
	ctx.stroke();
	//
	ctx.beginPath();
	ctx.moveTo(p.f.tr.x, p.f.tr.y);
	ctx.lineTo(p.f.br.x, p.f.br.y);
	ctx.stroke();
	//
	ctx.restore();
	/* ------------------------------------------------------
	* グラデーション
	* ---------------------------------------------------- */
	if( bgradation == true ) {
		/* 正面 */
		ctx.save();
		var grad = ctx.createLinearGradient(p.f.tl.x, p.f.tl.y, p.f.br.x, p.f.br.y);
		if(document.uniqueID) {
			grad.addColorStop(0, color);
			grad.addColorStop(0.3, "rgba(255, 255, 255, 0.1)");
			grad.addColorStop(1, color);
		} else {
			grad.addColorStop(0, "rgba(0, 0, 0, 0.1)");
			grad.addColorStop(0.3, "rgba(255, 255, 255, 0.1)");
			grad.addColorStop(1, "rgba(0, 0, 0, 0.4)");
		}
		ctx.fillStyle = grad;
		ctx.beginPath();
		ctx.moveTo(p.f.tl.x, p.f.tl.y);
		ctx.lineTo(p.f.tr.x, p.f.tr.y);
		ctx.lineTo(p.f.br.x, p.f.br.y);
		ctx.lineTo(p.f.bl.x, p.f.bl.y);
		ctx.closePath();
		if(document.uniqueID) { ctx.globalAlpha = 0; }
		ctx.fill();
		if(document.uniqueID) { ctx.globalAlpha = 1; }
		ctx.restore();
		/* 右側面 */
		ctx.save();
		if(document.uniqueID ) {
			ctx.fillStyle = "#000000";
			ctx.globalAlpha = 0.4;
		} else {
			var grad3 = ctx.createLinearGradient(p.f.tr.x, p.f.tr.y, p.b.tr.x, p.f.tr.y);
			grad3.addColorStop(0, "rgba(0, 0, 0, 0.3)");
			grad3.addColorStop(1, "rgba(0, 0, 0, 0.5)");
			ctx.fillStyle = grad3;
		}
		ctx.beginPath();
		ctx.moveTo(p.f.tr.x, p.f.tr.y);
		ctx.lineTo(p.b.tr.x, p.b.tr.y);
		ctx.lineTo(p.b.br.x, p.b.br.y);
		ctx.lineTo(p.f.br.x, p.f.br.y);
		ctx.closePath();
		ctx.fill();
		ctx.restore();
		/* 上面 */
		ctx.save();
		var grad2 = ctx.createLinearGradient(x-xr/5, y-h+yr, x+xr/5, y-h-yr);
		if(document.uniqueID) {
			grad2.addColorStop(0, "rgba(255, 255, 255, 0.2)");
			grad2.addColorStop(1, color);
		} else {
			grad2.addColorStop(0, "rgba(255, 255, 255, 0.2)");
			grad2.addColorStop(1, "rgba(0, 0, 0, 0.1)");
		}
		ctx.fillStyle = grad2;
		ctx.beginPath();
		ctx.moveTo(p.f.tl.x, p.f.tl.y);
		ctx.lineTo(p.f.tr.x, p.f.tr.y);
		ctx.lineTo(p.b.tr.x, p.b.tr.y);
		ctx.lineTo(p.b.tl.x, p.b.tl.y);
		ctx.closePath();
		if(document.uniqueID ) { ctx.globalAlpha = 0.1; }
		ctx.fill();
		if(document.uniqueID ) { ctx.globalAlpha = 1; }
		ctx.restore();
	} else {
		/* 側面 */
		ctx.save();
		ctx.fillStyle = "rgba(0,0,0,0.4)";
		ctx.beginPath();
		ctx.moveTo(p.f.tr.x, p.f.tr.y);
		ctx.lineTo(p.b.tr.x, p.b.tr.y);
		ctx.lineTo(p.b.br.x, p.b.br.y);
		ctx.lineTo(p.f.br.x, p.f.br.y);
		ctx.closePath();
		ctx.fill();
		ctx.restore();
		/* 上面 */
		ctx.save();
		ctx.fillStyle = "rgba(255,255,255,0.2)";
		ctx.beginPath();
		ctx.moveTo(p.f.tl.x, p.f.tl.y);
		ctx.lineTo(p.f.tr.x, p.f.tr.y);
		ctx.lineTo(p.b.tr.x, p.b.tr.y);
		ctx.lineTo(p.b.tl.x, p.b.tl.y);
		ctx.closePath();
		ctx.fill();
		ctx.restore();
	}
};
/* ------------------------------------------------------------------
* 垂直棒フラフ（線）を描画
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_vertical_bar_line = function(ctx, x, y, h, xr, color, alpha) {
	if( typeof(alpha) != "number" || alpha < 0 || alpha > 1 ) {
		alpha = 1;
	}
	if( typeof(xr) != "number" || xr <= 0 ) {
		xr = 0.5;
	}
	ctx.save();
	ctx.strokeStyle = color;
	ctx.globalAlpha = alpha;
	ctx.lineCap = "butt";
	ctx.lineWidth = Math.round( xr * 2 );
	ctx.beginPath();
	ctx.moveTo(x, y);
	ctx.lineTo(x, y-h);
	ctx.stroke();
	ctx.restore();
};
/* ------------------------------------------------------------------
* 垂直棒フラフ（平坦）を描画
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_vertical_bar_flat = function(ctx, x, y, h, xr, color, alpha, balpha, bgradation) {
	if( typeof(alpha) != "number" || alpha < 0 || alpha > 1 ) {
		alpha = 1;
	}
	if( typeof(balpha) != "number" || balpha < 0 || balpha > 1 ) {
		balpha = 1;
	}
	/* ------------------------------------------------------
	* 面塗り
	* ---------------------------------------------------- */
	ctx.save();
	ctx.fillStyle = color;
	ctx.globalAlpha = alpha;
	ctx.beginPath();
	ctx.moveTo(x+xr, y);
	ctx.lineTo(x-xr, y);
	ctx.lineTo(x-xr, y-h);
	ctx.lineTo(x+xr, y-h);
	ctx.closePath();
	ctx.fill();
	ctx.restore();
	/* ------------------------------------------------------
	* 境界線
	* ---------------------------------------------------- */
	ctx.save();
	ctx.globalAlpha = balpha;
	ctx.strokeStyle = "black";
	ctx.lineWidth = 1;
	ctx.beginPath();
	ctx.moveTo(x-xr, y);
	ctx.lineTo(x+xr, y);
	ctx.lineTo(x+xr, y-h);
	ctx.lineTo(x-xr, y-h);
	ctx.closePath();
	ctx.stroke();
	ctx.restore();
	/* ------------------------------------------------------
	* シャドー
	* ---------------------------------------------------- */
	ctx.save();
	ctx.lineWidth = 1;
	ctx.globalAlpha = 0.3;
	//
	ctx.beginPath();
	ctx.strokeStyle = "black";
	ctx.moveTo(x-xr+1, y-1);
	ctx.lineTo(x+xr-1, y-1);
	ctx.lineTo(x+xr-1, y-h+1);
	ctx.stroke();
	//
	ctx.beginPath();
	ctx.strokeStyle = "white";
	ctx.moveTo(x+xr-1, y-h+1);
	ctx.lineTo(x-xr+1, y-h+1);
	ctx.lineTo(x-xr+1, y-1);
	ctx.stroke();
	ctx.restore();
	/* ------------------------------------------------------
	* グラデーション
	* ---------------------------------------------------- */
	if( bgradation == true ) {
		ctx.save();
		ctx.lineWidth = 1;
		var grad = ctx.createLinearGradient(x-xr, y-h, x+xr, y);
		if(document.uniqueID ) {
			grad.addColorStop(0, color);
			grad.addColorStop(0.3, "rgba(255, 255, 255, 0.1)");
			grad.addColorStop(1, color);
		} else {
			grad.addColorStop(0, "rgba(0, 0, 0, 0.1)");
			grad.addColorStop(0.3, "rgba(255, 255, 255, 0.1)");
			grad.addColorStop(1, "rgba(0, 0, 0, 0.4)");
		}
		ctx.fillStyle = grad;
		ctx.beginPath();
		ctx.moveTo(x-xr+2, y-2);
		ctx.lineTo(x+xr-2, y-2);
		ctx.lineTo(x+xr-2, y-h+2);
		ctx.lineTo(x-xr+2, y-h+2);
		ctx.closePath();
		if(document.uniqueID) { ctx.globalAlpha = 0; }
		ctx.fill();
		if(document.uniqueID) { ctx.globalAlpha = 1; }
		ctx.restore();
	}
};
/* ------------------------------------------------------------------
* 垂直棒フラフ（円柱）を描画
* ---------------------------------------------------------------- */
html5jp.graph.vbar.prototype._draw_vertical_bar_cylinder = function(ctx, x, y, h, xr, yr, color, alpha, balpha, bgradation) {
	if( typeof(alpha) != "number" || alpha < 0 || alpha > 1 ) {
		alpha = 1;
	}
	if( typeof(balpha) != "number" || balpha < 0 || balpha > 1 ) {
		balpha = 1;
	}
	/* ------------------------------------------------------
	* 境界線（背面）
	* ---------------------------------------------------- */
	ctx.save();
	ctx.strokeStyle = "black";
	ctx.globalAlpha = balpha;
	ctx.lineWidth = 1;
	ctx.beginPath();
	ctx.moveTo(x-xr, y);
	ctx.bezierCurveTo(x-xr, y-yr/2, x-xr/2, y-yr, x, y-yr);
	ctx.bezierCurveTo(x+xr/2, y-yr, x+xr, y-yr/2, x+xr, y);
	ctx.stroke();
	ctx.restore();
	/* ------------------------------------------------------
	* 面塗り
	* ---------------------------------------------------- */
	ctx.save();
	ctx.fillStyle = color;
	ctx.globalAlpha = alpha;
	ctx.beginPath();
	ctx.moveTo(x-xr, y);
	ctx.lineTo(x-xr, y-h);
	ctx.bezierCurveTo(x-xr, y-h-yr/2, x-xr/2, y-h-yr, x, y-h-yr);
	ctx.bezierCurveTo(x+xr/2, y-h-yr, x+xr, y-h-yr/2, x+xr, y-h);
	ctx.lineTo(x+xr, y);
	ctx.bezierCurveTo(x+xr, y+yr/2, x+xr/2, y+yr, x, y+yr);
	ctx.bezierCurveTo(x-xr/2, y+yr, x-xr, y+yr/2, x-xr, y);
	ctx.fill();
	ctx.restore();
	/* ------------------------------------------------------
	* 境界線（前面）
	* ---------------------------------------------------- */
	ctx.save();
	ctx.strokeStyle = "white";
	ctx.globalAlpha = balpha;
	ctx.lineWidth = 1;
	/* 底面 */
	ctx.beginPath();
	ctx.moveTo(x-xr, y);
	ctx.bezierCurveTo(x-xr, y+yr/2, x-xr/2, y+yr, x, y+yr);
	ctx.bezierCurveTo(x+xr/2, y+yr, x+xr, y+yr/2, x+xr, y);
	ctx.stroke();
	/* 側面 */
	ctx.beginPath();
	ctx.moveTo(x-xr, y);
	ctx.lineTo(x-xr, y-h);
	ctx.stroke();
	ctx.beginPath();
	ctx.moveTo(x+xr, y);
	ctx.lineTo(x+xr, y-h);
	ctx.stroke();
	/* 上面 */
	ctx.beginPath();
	ctx.moveTo(x-xr, y-h);
	ctx.bezierCurveTo(x-xr, y-h-yr/2, x-xr/2, y-h-yr, x, y-h-yr);
	ctx.bezierCurveTo(x+xr/2, y-h-yr, x+xr, y-h-yr/2, x+xr, y-h);
	ctx.bezierCurveTo(x+xr, y-h+yr/2, x+xr/2, y-h+yr, x, y-h+yr);
	ctx.bezierCurveTo(x-xr/2, y-h+yr, x-xr, y-h+yr/2, x-xr, y-h);
	ctx.stroke();
	ctx.restore();
	/* ------------------------------------------------------
	* 前面グラデーション
	* ---------------------------------------------------- */
	if( bgradation == true ) {
		/* 側面 */
		ctx.save();
		var grad1 = ctx.createLinearGradient(x-xr, y, x+xr, y);
		if(document.uniqueID) {
			grad1.addColorStop(0, color);
			grad1.addColorStop(0.4, "rgba(255, 255, 255, 0.3)");
			grad1.addColorStop(0.9, color);
			grad1.addColorStop(1, color);
		} else {
			grad1.addColorStop(0, "rgba(0, 0, 0, 0.1)");
			grad1.addColorStop(0.4, "rgba(255, 255, 255, 0.3)");
			grad1.addColorStop(1, "rgba(0, 0, 0, 0.3)");
		}
		ctx.fillStyle = grad1;
		ctx.beginPath();
		ctx.moveTo(x+xr, y);
		ctx.bezierCurveTo(x+xr, y+yr/2, x+xr/2, y+yr, x, y+yr);
		ctx.bezierCurveTo(x-xr/2, y+yr, x-xr, y+yr/2, x-xr, y);
		ctx.lineTo(x-xr, y-h);
		ctx.bezierCurveTo(x-xr, y-h+yr/2, x-xr/2, y-h+yr, x, y-h+yr);
		ctx.bezierCurveTo(x+xr/2, y-h+yr, x+xr, y-h+yr/2, x+xr, y-h);
		ctx.lineTo(x+xr, y);
		if(document.uniqueID ) { ctx.globalAlpha = 0; }
		ctx.fill();
		if(document.uniqueID ) { ctx.globalAlpha = 1; }
		ctx.restore();
		/* 上面 */
		ctx.save();
		var grad2 = ctx.createLinearGradient(x-xr/5, y-h+yr, x+xr/5, y-h-yr);
		if(document.uniqueID) {
			grad2.addColorStop(0, "rgba(255, 255, 255, 0.2)");
			grad2.addColorStop(1, color);
		} else {
			grad2.addColorStop(0, "rgba(255, 255, 255, 0.2)");
			grad2.addColorStop(1, "rgba(0, 0, 0, 0.1)");
		}
		ctx.fillStyle = grad2;
		ctx.beginPath();
		ctx.moveTo(x-xr, y-h);
		ctx.bezierCurveTo(x-xr, y-h-yr/2, x-xr/2, y-h-yr, x, y-h-yr);
		ctx.bezierCurveTo(x+xr/2, y-h-yr, x+xr, y-h-yr/2, x+xr, y-h);
		ctx.bezierCurveTo(x+xr, y-h+yr/2, x+xr/2, y-h+yr, x, y-h+yr);
		ctx.bezierCurveTo(x-xr/2, y-h+yr, x-xr, y-h+yr/2, x-xr, y-h);
		if(document.uniqueID ) { ctx.globalAlpha = 0; }
		ctx.fill();
		if(document.uniqueID ) { ctx.globalAlpha = 1; }
		ctx.restore();
	} else {
		/* 上面 */
		ctx.save();
		ctx.globalAlpha = 0.2;
		ctx.fillStyle = "white";
		ctx.beginPath();
		ctx.moveTo(x-xr, y-h);
		ctx.bezierCurveTo(x-xr, y-h-yr/2, x-xr/2, y-h-yr, x, y-h-yr);
		ctx.bezierCurveTo(x+xr/2, y-h-yr, x+xr, y-h-yr/2, x+xr, y-h);
		ctx.bezierCurveTo(x+xr, y-h+yr/2, x+xr/2, y-h+yr, x, y-h+yr);
		ctx.bezierCurveTo(x-xr/2, y-h+yr, x-xr, y-h+yr/2, x-xr, y-h);
		ctx.fill();
		ctx.restore();
	}
};
