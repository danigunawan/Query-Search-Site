$(document).on('turbolinks:load', function(){
  $('#search-form').on('submit', function(event){
    if((new Date($('#since').val()).getTime()) > (new Date($('#until').val()).getTime())){
      alert("Since Date Greater than Until Date")
      event.preventDefault();
      return false
    }
    if((new Date($('#since').val()).getTime()) == (new Date($('#until').val()).getTime())){
      alert("Until Date Should be Greater than Since Date")
      event.preventDefault();
      return false
    }
  });

  $('#since').datepicker({
    startDate: $('#since').attr('min'),
    endDate: $('#since').attr('max'),
    format: 'yyyy-mm-dd',
    autoclose: true
  });

  $('#until').datepicker({
    startDate: $('#until').attr('min'),
    endDate: $('#until').attr('max'),
    format: 'yyyy-mm-dd',
    autoclose: true
  });
});
