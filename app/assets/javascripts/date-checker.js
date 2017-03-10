$(document).on('turbolinks:load', function(){
  $('#search-form').on('submit', function(event){
    if((new Date($('#from').val()).getTime()) > (new Date($('#to').val()).getTime())){
      alert("From Date Greater than To Date")
      event.preventDefault();
      return false
    }
  })
})
