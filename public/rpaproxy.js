$(function() {
  $('#endpoint').click(function(e) {
    $(e.target).select();
  });

  $(':radio[name=locale]').click(function(e) {
    var base_url = 'http://rpaproxy.heroku.com/rpaproxy/';
    $('#endpoint').val(base_url + $(e.target).val() + '/');
  });

  $(':radio#jp').click();
});
