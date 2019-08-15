//= require 'jstz'

$(document).ready(function() {
    var timezone = jstz.determine();
    document.cookie = 'time_zone=' + timezone.name() + ';';
});