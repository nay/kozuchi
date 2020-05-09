/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS206: Consider reworking classes to avoid initClass
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */

// 残高編集時に金額を計算する
class MoneyCounter {
  static initClass() {
    this.prototype.fields = ['man', 'gosen', 'nisen', 'sen', 'gohyaku', 'hyaku', 'gojyu', 'jyu', 'go', 'ichi'];
    this.prototype.amounts = [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1];
  }
  count() {
    let amount = 0;
    for (let i = 0, end = this.fields.length-1, asc = 0 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
      const v = $('#' + this.fields[i]).val();
      if (v !== '') {
        amount += parseInt(v) * this.amounts[i];
      }
    }
    return $('#deal_balance').val(amount);
  }
}
MoneyCounter.initClass();

// 更新された行のスタイリング

const addClassToUpdatedline = function() {
  if (location.hash.match(/^#d[0-9]+$/)) {
    const id = location.hash.replace('#', '');
    return $("." + id).not(".detail_row").addClass("updated_line");
  }
};

const clearUpdateLine = () => $("tr").removeClass("updated_line");

// 最近の記入パターン欄の内容の更新
loadRecentDealPatterns = function() {
  const $frame = $('#deal_pattern_frame');
  return $frame.load($frame.data('url'));
};

// 最近の記入パターン欄を表示する（常に表示モードならなにもしない）
const showRecentDealPatterns = function() {
  if ($('#deal_pattern_frame').data('mode') === 'always') { return; }
  return $('#deal_pattern_frame').show();
};

// 最近の記入パターン欄を隠す（常に表示モードならなにもしない）
const hideRecentDealPatterns = function() {
  if ($('#deal_pattern_frame').data('mode') === 'always') { return; }
  return $('#deal_pattern_frame').hide();
};

const dealHasAccountId = function(deal, account_id){
  if (!account_id || !deal) { return false; }
  for (let entry of Array.from(deal.readonly_entries)) {
    if (entry.account_id === account_id) { return true; }
  }
  return false;
};

$(function() {
  // hide notice
  const hideNotice = () => $('#notice').hide();

  // 登録フォーム一式のidを編集フォームと重複しないように加工し、無効化して、見えなくする
  const disableCreateWindow = function() {
    const $new_deal_window = $("#new_deal_window");
    if ($new_deal_window.hasClass('disabled')) { return; } // 二重に走らないようにする
    $new_deal_window.hide();
    $('#edit_mode_explanation').show();
    $new_deal_window.find('#errorExplanation').remove(); // 検証エラーメッセージが出ていたら削除する
    $new_deal_window.addClass('disabled');
    return $new_deal_window.find("*").each(function() {
      if (this.id) {
        this.id = "disabled_new_deal_" + this.id;
      }
      if (this.tagName === "A") {
        $(this).addClass('disabled');
      }
      if ((this.tagName === "INPUT") || (this.tagName === "SELECT")) {
        return this.disabled = 'disabled';
      }
    });
  };

  // 登録フォーム一式のidや無効化状態を戻して表示する
  const enableCreateWindow = function() {
    const $new_deal_window = $("#new_deal_window");
    $new_deal_window.removeClass('disabled');
    $new_deal_window.find("*").each(function() {
      if (this.id) {
        this.id = this.id.replace("disabled_new_deal_", "");
      }
      if (this.tagName === "A") {
        $(this).removeClass('disabled');
      }
      if ((this.tagName === "INPUT") || (this.tagName === "SELECT")) {
        return $(this).prop('disabled', null);
      }
    });
    $('#edit_mode_explanation').hide();
    return $new_deal_window.show();
  };

  // 無効化されたリンクを封じる
  $(document).on('click', "a.disabled", event => event.preventDefault());

  // 編集windowを閉じる
  const closeEditWindow = function(event) {
    $(this).closest('tr.edit_deal_row').remove();
    enableCreateWindow();
    hideRecentDealPatterns();
    return event.preventDefault();
  };

  $(document).on('click', '#edit_window button.close', closeEditWindow);
  $(document).on('click', 'a.close_edit_window', () => $('#edit_window button.close').click());

  // deal_tab
  $(document).on('click', '#deal_forms .tabbuttons a.btn', function() {
    if ($(this).hasClass('active')) { return false; }
    hideNotice();
    $('#deal_forms').load(this.href);
    return false;
  });

// deal_form
  // click (submitでreturn false すると disabled にされてしまうので submit イベントが送られないように先に処理する)
  $(document).on('click', '#deal_form [type=submit]', function(event){
    // 日付のチェック
    if (($('#date_day').val() === '') || ($('#date_month').val() === '') || ($('#date_year').val() === '')) {
      alert('日付を入れてください。');
      return false;
    }

    // 金額のチェック
    const amounts = $('#deal_form input.amount');
    if ((amounts.length > 0) && ($.grep(amounts.get(), (amount, index) => $(amount).val() !== '').length === 0)) {
      alert('金額を入力してください。');
      return false;
    }
  });

  // submit
  $(document).on('submit', '#deal_form', function(event){
    // 日付の読み取り
    $('#deal_year').val($('#date_year').val());
    $('#deal_month').val($('#date_month').val());
    $('#deal_day').val($('#date_day').val());

    // 記入登録/更新を試みる
    $.post(this.action, $(this).serializeArray(), function(result){
      if (result.error_view) {
        $('#deal_forms').empty();
        return $('#deal_forms').append(result.error_view);
      } else {
        let resultUrl = null;
        let resultUrlWithHash = null;
        if (result.redirect_to) {
          resultUrlWithHash = result.redirect_to;
          resultUrl = resultUrlWithHash.split('#')[0];
        } else {
          if (dealHasAccountId(result.deal, $('#deal_form_option').data("condition-account-id"))) { // 遷移先に条件がついていて適合していればそちらのURLにする
            resultUrl = $('#deal_form_option').data("condition-match-url").replace(/_YEAR_/, result.year).replace(/_MONTH_/, result.month);
          } else {
            resultUrl = $('#deal_form_option').data("result-url").replace(/_YEAR_/, result.year).replace(/_MONTH_/, result.month);
          }
          resultUrlWithHash = resultUrl + "#recent";
        }
        let prevUrl = location.pathname;
        const prevSearch = location.search;
        if (prevSearch && (prevSearch !== "")) {
          prevUrl += "?" + prevSearch;
        }
        location.assign(resultUrlWithHash);
        // NOTE: assign しても location.pathname などが古いケースがあるため、resultUrlベースで用意して比較している
        if (resultUrl === prevUrl) {
          return location.reload();
        }
      }
    }
    , 'JSON');
    return false; // 通常の Form 動作は行わない
  });

  // 編集リンクのクリック
  $(document).on('click', 'a.edit_deal', function(event){
    let $tr = $(this).closest('tr');
    if ($tr.hasClass('edit_deal_row')) {
      $tr = $tr.prev();
    }
    $('.edit_deal_row').remove();
    while (!$tr.hasClass('last_entry') && ($tr.length > 0)) {
      $tr = $tr.next();
    }
    disableCreateWindow();
    $tr.after("<tr class='edit_deal_row'><td colspan='12' data-deal-id='" + $(this).data('deal-id') + "'></td></tr>");
    $(".edit_deal_row td").load(this.href, null, function() {
      return location.hash = 'd' + $(this).data("deal-id"); // コールバックで変えたほうが編集フォームが見やすい位置にスクロールされる
    });
    showRecentDealPatterns();
    return event.preventDefault();
  });

  // a.add_entry_fields
  $(document).on('click', 'a.add_entry_fields', function() {
    $('#deal_forms').load(this.href, $(this).closest('form').serializeArray());
    return false;
  });

  $(document).on('click', 'a.split_summary', function() {
    $('#deal_summary_frame').hide();
    $('.entry_summary').show();
    $('#deal_summary_mode, #deal_pattern_summary_mode').val('split');
    return false;
  });

  $(document).on('click', 'a.unify_summary', function() {
    $('.entry_summary').hide();
    $('#deal_summary_frame').show();
    $('#deal_summary_mode, #deal_pattern_summary_mode').val('unify');
    return false;
  });

  $(document).on('click', '#count_money_button', function() {
    const moneyCounter = new MoneyCounter;
    moneyCounter.count();
    return false;
  });

  $(document).on('click', 'a.end_of_month_button', function() {
    const day = endOfMonth($('#date_year').val(), $('#date_month').val());
    if (day) { $('#date_day').val(day); }
    return false;
  });

  addClassToUpdatedline();

  $(window).hashchange(function() {
    clearUpdateLine();
    return addClassToUpdatedline();
  });

  // 登録日時などの表示

  $(document).on('mouseover', 'td.number', function() { return $('.timestamps', this).show(); });

  $(document).on('mouseout', 'td.number', function() { return $('.timestamps', this).hide(); });

  // 口座情報の表示
  $(document).on('mouseover', '.account-memo-trigger', function() { return $('.account-memo', this).show(); });
  $(document).on('mouseout',  '.account-memo-trigger',function() { return $('.account-memo', this).hide(); });

  // 日ナビゲーション

  $('.for_deal_editor').on('click', '#day_navigator td.day a', function(event){
    $(".body_tab_link[data=monthly]").click();
    return $('input#date_day').val($(this).data('day'));
  });

  // 記入パターンのロード（リターンキーが押されたとき）
  $(document).on('keypress', 'input#pattern_keyword', function(event) {
    if (event.which && (event.which === 13)) {
      $('#pattern_search_result').empty();
      const code = $('input#pattern_keyword').val();
      if (code !== '') {
        // try to load that pattern
        $('#notice').hide();
        const url = $('#load_pattern_url').text().replace('template_pattern_code', encodeURIComponent(code));

        // 指定したコードがないときは 'Code not found' が返る
        $.get(url, function(data) {
          if (data === 'Code not found') {
            return $('#pattern_search_result')[0].innerHTML = 'コード「' + code + '」の記入パターンは登録されていません。';
          } else {
            const update_area = $('input#pattern_keyword').data('update-area');
            $(update_area).empty();
            $(update_area).append(data);
            // focus on submit button
            $(update_area).find("input[type='submit']").focus();
            return loadRecentDealPatterns();
          }
        });
      }
      return event.preventDefault();
    }
  });

  // 記入の削除
  $(document).on('click', 'a.deal_deletion_link', function(event){
    $.post(this.href, {_method: 'delete'}, function(data) {
      $('#content').find(".alert").remove();
      $('#content').prepend("<div class='alert alert-success alert-dismissable'><button class='close' type='button' data-dismiss='alert' area-hidden='true'>&times;</button>" + data.success_message + "</div>");
      $("tr.d" + data.deal.id).remove();
      return location.hash = "top"; // '#' もなしで取るのは難しいのでひとまずこのようにする
    });
    return event.preventDefault();
  });

  // 記入の確認
  $(document).on('click', 'a.deal_confirmation_link', function(event){
    $.post(this.href, {_method: 'put'}, function(data) {
      $('#content').find(".alert").remove();
      $('#content').prepend("<div class='alert alert-success alert-dismissable'><button class='close' type='button' data-dismiss='alert' area-hidden='true'>&times;</button>" + data.success_message + "</div>");
      $("tr.d" + data.deal.id + " a.deal_confirmation_link").remove();
      $("tr.d" + data.deal.id).removeClass('unconfirmed');
      return location.hash = "d" + data.deal.id;
    });
    return event.preventDefault();
  });

  // ナビゲーター内の口座選択の変更
  $('#account_selector #account_id').change(function(event){
    const account_id = $(this).val();
    if (account_id === '') {
      // TODO: あとで実装する
      return document.location.href = $('#deal_form_option').data('all-url');
    } else {
      return document.location.href = $('#deal_form_option').data('account-url').replace('_ACCOUNT_ID_', account_id);
    }
  });


  // 口座選択状態などで情報ボタンを押したとき
  $(document).on('click', 'td.open_detail', function(event){
    let $tr = $(this).closest('tr');

    while (!$tr.hasClass('last_entry') && ($tr.length > 0)) {
      $tr = $tr.next();
    }

    // 自分のところがすでに開いていたらそれを閉じるだけ
    if ($tr.next('.detail_row').is(':visible')) {
      return $tr.next('.detail_row').hide();
    } else { // 新しく開くリクエストがきたらいったん全部閉じてから開く
      $('tr.detail_row').hide();
      $tr.next('.detail_row').show();
      return location.hash = $(this).closest('tr').attr('id');
    }
  });

  // monthlyページのボディタブ切り替え
  $(document).on('click', '.body_tab_link', function(event){
    $('.body_tab li').removeClass('active');
    $(this).closest('li').addClass('active');

    $('.body_tab_area').hide();
    return $('#' + $(this).attr('data') + "_area").show();
  });

  // ロード時、#recent, #monthly というロケーションハッシュがあればリンククリック状態にする
  if ($('#monthly_deals_body_tab').length > 0) {
    if ((window.location.hash === '#recent') || (window.location.hash === '#monthly')) {
      return $(".body_tab_link[data=" + window.location.hash.slice(1) + "]").click();
    }
  }
});
