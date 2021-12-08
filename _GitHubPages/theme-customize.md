---
title: Theme Customization
layout: default
order: 3
---

We've got our development environment setup and a landing page served by both GitHub - all within our development server that can be fired up in a single click. 

<p align="center">
<iframe src="https://giphy.com/embed/lgRNj0m1oORfW" width="480" height="267" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/lgRNj0m1oORfW">via GIPHY</a></p>
</p>

But now's not the time to get cocky, kid! Now it's time to press the attack and make this site theme our own. Speaking of themes, as part of this tutorial we're going to switch over to [minima](https://github.com/jekyll/minima/tree/master). It offers a very clean theme that we can use as a building block to customize as we need. 

# Update Our Gem
First things first, we need to install the minima gem in our local development environment. Remember, when installing themes or plugins, we must consult the [dependency version codex](https://pages.github.com/versions/). As of this writing, version `2.5.1` is what GitHub supports. 

Crack open the `Gemfile` and add the following line:

```gemfile
"minima", "~>2.5.1"
```

We'll leave the existing theme in the `Gemfile` until the end, in case we want to switch back for testing or comparison. 
Execute `bundle` on the console to update the local gems. 

```bash
@zimventures ➜ /workspaces/TIL (main ✗) $ bundle
Fetching gem metadata from https://rubygems.org/.........
Resolving dependencies...
Using bundler 2.2.30
Using colorator 1.1.0
Using concurrent-ruby 1.1.9
Using public_suffix 4.0.6
Using eventmachine 1.2.7
Using http_parser.rb 0.8.0
Using ffi 1.15.4
Using forwardable-extended 2.6.0
Using rb-fsevent 0.11.0
Using rexml 3.2.5
Using liquid 4.0.3
Using mercenary 0.3.6
Using rouge 3.26.1
Using safe_yaml 1.0.5
Using em-websocket 0.5.3
Using rb-inotify 0.10.1
Using kramdown 2.3.1
Using pathutil 0.16.2
Using sass-listen 4.0.0
Using listen 3.7.0
Using kramdown-parser-gfm 1.1.0
Using addressable 2.8.0
Using sass 3.7.4
Using i18n 0.9.5
Using jekyll-watch 2.2.1
Using jekyll-sass-converter 1.5.2
Using jekyll 3.9.1
Using jekyll-feed 0.15.1
Using jekyll-seo-tag 2.7.1
Using jekyll-theme-hacker 0.2.0
Using minima 2.5.1
Bundle complete! 4 Gemfile dependencies, 31 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
@zimventures ➜ /workspaces/TIL (main ✗) $ 
```

Lastly, update `_config.yml` to use minima as the theme: 

```yaml
theme: minima
```

Run the development server and verify that the local site is now being rendered with the minima theme:
```bash
@zimventures ➜ /workspaces/TIL (main ✗) $ bundle exec jekyll serve
Configuration file: /workspaces/TIL/_config.yml
            Source: /workspaces/TIL
       Destination: /workspaces/TIL/_site
 Incremental build: disabled. Enable with --incremental
      Generating... 
       Jekyll Feed: Generating feed for posts
                    done in 0.681 seconds.
/usr/local/bundle/gems/pathutil-0.16.2/lib/pathutil.rb:502: warning: Using the last argument as keyword parameters is deprecated
 Auto-regeneration: enabled for '/workspaces/TIL'
    Server address: http://127.0.0.1:4000
  Server running... press ctrl-c to stop.
```

# Overriding Gem Themes
When using a theme that is based on a gem, all of the files are hidden from the project. However, when Jekyll renders the site it 
allows the gem to be overriden by files in the project. Let's use the [minima theme](https://github.com/jekyll/minima) as our example. 
Within the `_layouts` directory there are four files which serve as base templates, or layouts, for our content.

```bash
./_layouts/
├── default.html
├── home.html
├── page.html
└── post.html
```

In order to override any of these files they must exist within the project. You'll recall from the first tutorial that our landing 
page currently uses the `default` layout. 

```markdown
---
title: Home
layout: default
---

# Welcome to Today, I Learned

TODO: Write this! 😅
```

In order to start tweaking the minima version of this file we'll need to get a copy and place it into our project.


---
**IMPORTANT!**

GitHub Pages currently uses version 2.5.1 of minima, [per the version codex](https://pages.github.com/versions/). This does NOT correspond to the `master` branch of the minima project, which is currently the 3.x branch. 
After checking out the repo, we'll change the working branch to `2.5-stable`. 

---


Steps shown below:
- clone the minima repo
- change to the 2.5-stable branch
- move the entire `_layouts` directory to our project root

```bash
@zimventures ➜ /tmp $ git clone https://github.com/jekyll/minima
Cloning into 'minima'...
remote: Enumerating objects: 1885, done.
remote: Total 1885 (delta 0), reused 0 (delta 0), pack-reused 1885
Receiving objects: 100% (1885/1885), 645.11 KiB | 1.74 MiB/s, done.
Resolving deltas: 100% (1062/1062), done.
@zimventures ➜ /tmp $ cd minima/
@zimventures ➜ /tmp/minima (master) $ git checkout 2.5-stable
Branch '2.5-stable' set up to track remote branch '2.5-stable' from 'origin'.
Switched to a new branch '2.5-stable'
@zimventures ➜ /tmp/minima (2.5-stable) $ mv ./_layouts/ /workspaces/TIL/
@zimventures ➜ /tmp/minima (2.5-stable ✗) $ 

```


Let's take a peek at the `default.html` layout to see what we're working with:

{% raw %}
```django
<!DOCTYPE html>
<html lang="{{ page.lang | default: site.lang | default: "en" }}">

  {%- include head.html -%}

  <body>

    {%- include header.html -%}

    <main class="page-content" aria-label="Content">
      <div class="wrapper">
        {{ content }}
      </div>
    </main>

    {%- include footer.html -%}

  </body>

</html>
```
{% endraw %}

Wait a second! Where are `head.html`, `header.html`, and `footer.html` defined? Minima defines those in the `_includes` directory, which we haven't copied to our project. 
Let's go ahead and do that now. If you aren't already there, don't forget to change to the `2.5-stable` branch before copying the directory over.

```bash
@zimventures ➜ /workspaces/TIL (main ✗) $ cd /tmp/minima/
@zimventures ➜ /tmp/minima (2.5-stable ✗) $ mv _includes/ /workspaces/TIL/
@zimventures ➜ /tmp/minima (2.5-stable ✗) $  
```

## Modifying the template
There are a great many modifications I want to make to the base template, including building a custom menu. For now, let's add a little link to the footer that shows the current top story from [HackerNews](https://news.ycombinator.com/).
The [Hacker News API](https://github.com/HackerNews/API) will be our source of inspiration. In short, we'll call the API using `jQuery` and stash the results into an element within the footer.

### Add jQuery to our site
Crack open `./_includes/head.html`, which was previously copied from the minima repo clone. Right before the `</head>` declaration, add in a link to the Google CDN hosted copy of jQuery.

```html
  ...
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
</head>
```

### Dynamic Content Element
Before we use jQuery to invoke the Hacker News API, we need a place in the footer to display what is returned. For that, we'll add a simple paragraph block.

Within `./_includes/footer.html` we'll add a paragraph with the id `latest-hn`. The contents of the block will be replaced with something from the API. 

```html
<p align="center">
  Latest HN Top Story: <span id="latest-hn"></span>
</p>
```

### get() 'er done!
With jQuery now available to us and the HTML element ready to be populated, it's time to make the call to the Hacker News API! 

The block below will be placed right before the `</footer>` end tag within `./_includes/footer.html`. 

As you can see from the comments, it 
fetches a list of the top stories and then grabs details for the first one in the list. See the [Hacker News API](https://github.com/HackerNews/API) for more details on the data that is returned. 
For our purposes, we'll just make use of the title and URL to the story. 

```html
<script>

  // Don't call this until the page is ready (aka: finished loading)
  $(document).ready( function(){

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
</script>
```

Let's fire up the local development server and see what the footer looks like.

```bash
@zimventures ➜ /workspaces/TIL (main ✗) $ bundle exec jekyll serve
Configuration file: /workspaces/TIL/_config.yml
            Source: /workspaces/TIL
       Destination: /workspaces/TIL/_site
 Incremental build: disabled. Enable with --incremental
      Generating... 
       Jekyll Feed: Generating feed for posts
                    done in 0.608 seconds.
/usr/local/bundle/gems/pathutil-0.16.2/lib/pathutil.rb:502: warning: Using the last argument as keyword parameters is deprecated
 Auto-regeneration: enabled for '/workspaces/TIL'
    Server address: http://127.0.0.1:4000
  Server running... press ctrl-c to stop.
```
---
*Screenshot*
<p align="center">
<img src="{{'/assets/images/GitHubPages/hn_footer.png' | relative_url }}">
</p>
---

Voila...we've got the latest news!

With our newfound knowledge of how to update the guts of a theme, let's take the next step and start making heavier modifications using [Liquid](https://shopify.github.io/liquid/).

Next up: [Navigation Menu]({{ "/GitHubPages/navigation-menu" | relative_url }})