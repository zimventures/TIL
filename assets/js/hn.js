// Don't call this until the page is ready (aka: finished loading)
$( document ).ready(function(){

// First, get a list of all the top stories
$.get("https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty", 
    function(result) {      

    // Fetch the first top story
    $.get("https://hacker-news.firebaseio.com/v0/item/" + result[0] + ".json?print=pretty", function(data) {

        // With the title and URL in hand, form a link
        $( "#latest-hn" ).html("<a href=\"" + data.url + "\">" + data.title + "</a>");
    }); 
});

});
