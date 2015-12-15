$(function() {
  function selectorEscape(val){
    return val.replace(/[ !"#$%&'()*+,.\/:;<=>?@\[\\\]^`{|}~]/g, '\\$&');
  }

  // activate current manu in the navigation bar
  $('#navbar a[href=' + selectorEscape(location.pathname) + ']')
    .parent()
    .addClass("active");

  $('#endpoint').click(function(e) {
    $(e.target).select();
  });

  $('form#endpoint-form').change(function(e) {
    var base_url = location.href + 'rpaproxy/';
    var locale = $('#endpoint-form [name=locale]:checked').val();
    $('#endpoint').val(base_url + locale + '/');
  });

  $('#endpoint-form :radio[value=jp]').click();

  $('#stats-locales a[href=#tabs-jp]').click();
});
