# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  $('#mainTabs a:first').tab('show');
  $('.selectpicker').selectpicker({style: 'btn-info'});
  data = [ {label : "Proximeter", data :  [[0, 0], [1, 1], [2,2]]},{label : "Scale", data :  [[0, 0], [2, 1], [3,4]]}, {label : "Scanner", data :  [[0, 0], [3, 1], [4,4]]} ]; 
  options = {series: { lines: { show: true }, points: {show: true}},xaxis: { tickDecimals: 0 }, yaxis: { min: 0 }};
  $.plot($("#placeholder"), data, options);
  
  #$(document).fartscroll();
  #Fart every 800 pixels scrolled in the document
  #$(document).fartscroll(800);
  #Fart every 100 pixels scrolled in the body (probably a bit much)
  #$("body").fartscroll(100);
  #Now I'm just adding more examples to make the page longer
  #$("body").fartscroll(50);
  #SO MANY FARTS
  #$("body").fartscroll(5);
  #I should register fart.io for this
  #$("div").fartscroll(500);
  #I should register fart.io for this
  #$("body").fartscroll(400);
  #Dammit, fart.io is taken
  #$(window).fartscroll(600);
  #Alright, that's probably enough examples
  #$("body").fartscroll(400);