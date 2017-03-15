$(document).on('turbolinks:load', function(){
  if($('#timer-container').data('time') != ""){
    var countDownDate = new Date($('#timer-container').data('time')).getTime()
    var x = setInterval(function() {
      var now = new Date().getTime();

      var distance = countDownDate - now;

      var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((distance % (1000 * 60)) / 1000);

      $('#timer-container').html("<h3>Remaining time till next allowed query: " + minutes + "m " + seconds + "s </h3>")

      if (distance < 0) {
        $('#search-btn').prop('disabled', false);
        $('#timer-container').html("<div class='alert alert-success alert-dismissible'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button>It is ok to search again</div>");
        clearInterval(x)
      }
    }, 1000);
  }
});
