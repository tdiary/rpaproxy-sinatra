$(function() {
  $('#endpoint').click(function(e) {
    $(e.target).select();
  });

  $('form#endpoint-form').change(function(e) {
    var base_url = location.href + 'rpaproxy/';
    var locale = $('#endpoint-form [name=locale]:checked').val();
    $('#endpoint').val(base_url + locale + '/');
  });

  $('#endpoint-form :radio[value=jp]').click();
});
