/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
this.Settlement = class Settlement {
  contsructor() {
    this.creditorSum = 0;
    return this.debtorSum = 0;
  }
  toggle(checkbox, amount) {
    if (checkbox.checked) {
      if (amount < 0) {
        this.debtorSum -= amount;
      } else {
        this.creditorSum += amount;
      }
      $(checkbox.parentNode.parentNode).removeClass('disabled');
    } else {
      if (amount < 0) {
        this.debtorSum += amount;
      } else {
        this.creditorSum -= amount;
      }
      $(checkbox.parentNode.parentNode).addClass('disabled');
    }
    $('#debtor_sum').html(numToFormattedString(this.debtorSum));
    $('#creditor_sum').html(numToFormattedString(this.creditorSum));

    if (this.debtorSum > this.creditorSum) {
      $('#target_description').html('に');
      return $('#result').html(' から ' + numToFormattedString(this.debtorSum - this.creditorSum) + '円 を入金する。');
    } else {
      $('#target_description').html('から');
      return $('#result').html(' に ' + numToFormattedString(this.creditorSum - this.debtorSum) + '円 が入金される。');
    }
  }
};

var numToFormattedString = function(num) {
  const str = num.toString();
  let result = '';
  let count = 0;
  for (let start = str.length-1, i = start, asc = start <= 0; asc ? i <= 0 : i >= 0; asc ? i++ : i--) {
    result = str.charAt(i) + result;
    if ((str.charAt(i) === '-') || (i === 0)) { break; }
    count += 1;
    if ((count % 3) === 0) {
      result = ',' + result;
    }
  }
  return result;
};

$(function() {
  const refreshTargets = function() {
    const data = $('#target_deals_form').serializeArray();
    data.push({name: '_method', value: 'PUT'});
    return $('#target_deals').load($('#target_deals_form').data('url'), data, function() {
      settlement.debtorSum = $('#settlement_sums').data("debtor-sum");
      return settlement.creditorSum = $('#settlement_sums').data("creditor-sum");
    });
  };

  $('#select_credit_account select.account_selector').change(function() {
    return location.href = $(this).data("url-template").replace("_ACCOUNT_ID_", $(this).val());
  });

  $('#target_deals').on('click', 'a.toggleDeals', function(e){
    const data = $('#target_deals_form').serializeArray();
    data.push({name: '_method', value: $(this).data('method')});

    $('#target_deals').load($(this).attr('href'), data, function() {
      settlement.debtorSum = $('#settlement_sums').data("debtor-sum");
      return settlement.creditorSum = $('#settlement_sums').data("creditor-sum");
    });
    return false;
  });

  const adjustDayOptions = function(option_selector, lastDay) {
    $(option_selector).each(function() {
      if (parseInt($(this).val()) > lastDay) {
        return $(this).remove();
      }
    });
    let day = parseInt($(option_selector).last().val());
    return (() => {
      const result = [];
      while (day < lastDay) {
        day += 1;
        result.push($(option_selector).last().after("<option value='" + day + "'>" + day + "</option>"));
      }
      return result;
    })();
  };

  // 選択された年、月に応じて日の選択肢の範囲を更新する
  const refreshDayOptions = function() {
    // 開始日
    const startYear = $('#start_date_year').val();
    const startMonth = $('#start_date_month').val();
    adjustDayOptions('#start_date_day option', new Date(parseInt(startYear), parseInt(startMonth), 0).getDate());

    // 終了日
    // TODO: 開始日より前を選べないようにもしたい
    const endYear = $('#end_date_year').val();
    const endMonth = $('#end_date_month').val();
    return adjustDayOptions('#end_date_day option', new Date(parseInt(endYear), parseInt(endMonth), 0).getDate());
  };

  // 指定された期間にあわせて月ナビゲーターの色を更新する
  const refreshMonthNavigator = function() {
    $("tr.month").removeClass('selected');

    let startYear = $('#start_date_year').val();
    let startMonth = $('#start_date_month').val();
    let endYear = $('#end_date_year').val();
    let endMonth = $('#end_date_month').val();
    if ((new Date(parseInt(startYear), parseInt(startMonth)-1, 1)) <= (new Date(parseInt(endYear), parseInt(endMonth)-1, 1))) {
      startYear = parseInt(startYear);
      startMonth = parseInt(startMonth);
      endYear = parseInt(endYear);
      endMonth = parseInt(endMonth);
      return $("tr.month").each(function() {
        const year = $(this).data('year');
        const month = $(this).data('month');
        if (((year > startYear) || ((year === startYear) && (month >= startMonth))) && ((year < endYear) || ((year === endYear) && (month <= endMonth)))) {
          return $(this).addClass('selected');
        }
      });
    }
  };

  const onSpanChange = function() {
    refreshDayOptions();
    refreshMonthNavigator();
    return refreshTargets();
  };

  refreshMonthNavigator();
  refreshDayOptions();

  $('#target_deals_form').on('change', 'select', onSpanChange);
  $('#target_deals_form').on('change', "input[type='text']", onSpanChange);
  $('#target_deals_form').on('change', "input[type='checkbox']", onSpanChange);
  $('#target_deals_form').on('change', 'textarea', onSpanChange);

  // まだ選択されていない領域がクリックされたら、範囲が月まで選択されていれば、近い方の端を伸ばす。
  // 選択されている領域がクリックされたら、その月のみが選択された状態にする。
  $('#month_navigator_frame tr.month').click(function() {
    const year = $(this).data('year');
    const month = $(this).data('month');

    let startYear = $('#start_date_year').val();
    let startMonth = $('#start_date_month').val();
    let endYear = $('#end_date_year').val();
    let endMonth = $('#end_date_month').val();

    if ((new Date(parseInt(startYear), parseInt(startMonth)-1, 1)) <= (new Date(parseInt(endYear), parseInt(endMonth)-1, 1))) {
      startYear = parseInt(startYear);
      startMonth = parseInt(startMonth);
      endYear = parseInt(endYear);
      endMonth = parseInt(endMonth);

      // 開始より以前をクリック
      if ((year < startYear) || ((year === startYear) && (month < startMonth))) {
        $('#start_date_year').val(year);
        $('#start_date_month').val(month);
        $('#start_date_day').val(1);
      } else if ((year > endYear) || ((year === endYear) && (month > endMonth))) {
        $('#end_date_year').val(year);
        $('#end_date_month').val(month);
        $('#end_date_day').val((new Date(year, month, 0)).getDate());
      } else {
        $('#start_date_year').val(year);
        $('#start_date_month').val(month);
        $('#start_date_day').val(1);
        $('#end_date_year').val(year);
        $('#end_date_month').val(month);
        $('#end_date_day').val((new Date(year, month, 0)).getDate());
      }

      return onSpanChange();
    }
  });

  if ($('#settlement_sums').length > 0) {
    settlement.debtorSum = $('#settlement_sums').data("debtor-sum");
    return settlement.creditorSum = $('#settlement_sums').data("creditor-sum");
  }
});
