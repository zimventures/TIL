---
title: Blog
layout: default
order: 6
---

# Blog
To this point, we've been working with static pages within a collection. Each of these pages are shown as sub-menu items within the sidebar menu. I'd like to have the ability to create blog posts, unrelated to any particular top level collection.

## Posts Landing Page
A landing page will be needed for the blog. On this landing page, the latest post will be featured at the top. Below it, the previous three posts will be shown. Below those three posts, a pagination widget allows the user to quickly navigate through previous posts. 

## Pagination
Jekyll has built in [pagination support](https://jekyllrb.com/docs/pagination/) for blog posts. In order to enable pagination, start by modifying the `_config.yml` with the following: 

```yaml
plugins:
  - jekyll-paginate
  
paginate_path: "/blog/page:num/"
paginate: 3
```

Pagination only works with `.html` files. In particular, the `pagination` object will only be passed to the `index.html` in the same directory specified by the `paginate_path` in `_config.yml`. This sounds like a problem, but it really isn't. Blog posts will still be written as Markdown and will use a new `_layout`. `./blog/index.html`. 

### /blog/index.html

Let's take a look at the first section of the blog's `index.html`

{% raw %}
```django
{% if paginator.page == 1%}
    <p class="display-1 text-center">Latest Post</p>
    {% for post in paginator.posts limit:1 %}

        {% if post.header_img %}
            <img src="{{post.header_img}}" class="card-img-top" alt="...">
        {% endif %}

        <p class="lead">{{post.title}}</p>
        <p class="card-text">{{post.excerpt}}</p>
        <a href="{{ post.url | relative_url }}" class="btn btn-primary text-white">read more...</a>

    {% endfor %}

    <p class="display-4 text-center">Check Out These Other Posts</p>

    {% assign posts = paginator.posts | shift %}

{% else %}
    
    {% assign posts = paginator.posts %}
    
{% endif %}
```
{% endraw %}

The `posts` variable that is being assigned contains a list of the posts that will be drawn as smaller cards at the bottom of the page. In the case where the first page in the paginator is being drawn, we'll render the latest page, pop it off the list, and show the next two as smaller preview cards. For all other pagination pages, we'll show three preview cards. 

<p align="center">
    <img src="{{'/assets/images/GitHubPages/post_previews.png' | relative_url}}">
</p>

Here is the HTML template for rendering the preview cards. After the previews are shown, the pagination widget is rendered by including the `posts_navigation.html` file...which we'll write now. 

{% raw %}
```django

<div class="row justify-content-center">
    {% for post in posts %}

        <div class="card col m-3">
            {% if post.header_img %}
                <img src="{{post.header_img}}" class="card-img-top" alt="...">
            {% endif %}

            <div class="card-body">
                <h5 class="lead">{{post.title}}</h5>
                <p class="card-text">{{post.excerpt}}</p>
                <a href="{{ post.url | relative_url }}" class="btn btn-primary text-white">read more...</a>
            </div>
        </div>

    {% endfor %}
</div>


{%- include posts_pagination.html -%}
```
{% endraw %}

##### excerpts
It's important to note the use of the {% raw %}`{{post.excerpt}}`{% endraw %} for rendering the content from the post. An excerpt is a the content from the post that precedes some type of excerpt separator. Let's take a look at an example post to see how the excerpt is defined.

{% raw %}
```markdown
---
layout: post
title:  "November Update"
author: "Rob Zimmerman"
excerpt_separator: <!--more-->
---
November stuff!.

<!--more-->

Other stuff goes here.
```
{% endraw %}

Inside of the Front Matter is a new variable: `excerpt_separator`. This variable defines where in the page the excerpt for the content *ends*. To access the entire post, including the excerpt, use the `post.content` parameter. 
## ./_includes/posts_pagination.html
The pagination widget is the visual representation of the `pagination` object that is created and managed by Jekyll. It will comprise of three main elements: back button, tabs for each page within the pagination object, a next button. Bootstrap has, once again, done most of the heavy lifting for us. Their [pagination examples](https://getbootstrap.com/docs/4.0/components/pagination/) have quick and easy references to get us started. 

There are a few high level details of the widget to note:
- The entire pagination widget will only be rendered if the number of pages is greater than one (duh). 
- The widget is actually just a stylized unordered list (`<ul>`) with each page being a `<li>`
- This current implementation draws every page. As I start to write more posts, this will need to get fixed (30+ posts).

<hr/>
<details>
<summary>View complete posts_pagination.html</summary>

{% highlight django %}
{% raw %}
{% if paginator.total_pages > 1 %}

  <ul class="nav justify-content-center">
    {% if paginator.previous_page %}
      <li class="page-item">
        <a class="page-link" href="{{ paginator.previous_page_path | relative_url }}" aria-label="Previous">
          <span aria-hidden="true">&laquo; Previous</span>
        </a>
      </li>
    {% else %}
      <li class="page-item disabled">
        <a class="page-link"><span aria-hidden="true">&laquo; Previous</span></a>
      </li>
    {% endif %}

    {% for page in (1..paginator.total_pages) %}
      {% if page == paginator.page %}
        <li class="page-item active" aria-current="page">
          <a class="page-link" href="#">{{page}}</a>
        </li>
      
      {% elsif page == 1 %}
        <li class="page-item">
          <a class="page-link" href="{{ '/blog/' | relative_url}}">{{ page }}</a>
        </li>
      {% else %}
        <li class="page-item">
          <a class="page-link" href="{{ site.paginate_path | relative_url | replace: ':num', page }}">{{ page }}</a>
        </li>
      {% endif %}
    {% endfor %}

    {% if paginator.next_page %}
      <li class="page-item">
        <a class="page-link" href="{{ paginator.next_page_path | relative_url }}" aria-label="Next">
          <span aria-hidden="true">Next &raquo;</span>
        </a>
      </li>
      
    {% else %}
      <li class="page-item disabled">
        <a class="page-link"><span aria-hidden="true">Next &raquo;</span></a>
      </li>
    {% endif %}
  </ul>

{% endif %}
{% endraw %}
{% endhighlight %}

</details>
<hr/>

### Previous Button
The previous button is drawn using the `paginator.previous_page_path` IF there is a previous page. Otherwise, we'll disable the button and use the same text: "Previous" pre-pended with a left chevron. 


{% highlight django %}
{% raw %}
{% if paginator.previous_page %}
    <li class="page-item">
    <a class="page-link" href="{{ paginator.previous_page_path | relative_url }}" aria-label="Previous">
        <span aria-hidden="true">&laquo; Previous</span>
    </a>
    </li>
{% else %}
    <li class="page-item disabled">
    <a class="page-link"><span aria-hidden="true">&laquo; Previous</span></a>
    </li>
{% endif %}
{% endraw %}
{% endhighlight %}

### Pages
This is the real meat of the widget. The liquid logic here will iterate over each page in the paginator, drawing a button for each. The button is marked as disabled if it represents the current page that is being shown. 

A special check is made for the first page of the paginated list. For the first page, always go to the root of the blog: `/blog/` rather than `/blog/page1/`, which doesn't exist.

The URL for each page is procedurally generated directly in the template using a combination of a site variable and some Liquid filtering magic. You'll recall that `site.paginate_path` was set to `/blog/page:num/` within `_config.yml`. The `:num` part of that path must be replaced within the template to the desired page number. Using the Liquid [`replace` filter](https://shopify.github.io/liquid/filters/replace/), the page number is dropped right in place where it's needed. 

{% highlight django %}
{% raw %}
{% for page in (1..paginator.total_pages) %}
    {% if page == paginator.page %}
        <li class="page-item active" aria-current="page">
            <a class="page-link" href="#">{{page}}</a>
        </li>    
    {% elsif page == 1 %}
        <li class="page-item">
            <a class="page-link" href="{{ '/blog/' | relative_url}}">{{ page }}</a>
        </li>
    {% else %}
        <li class="page-item">
            <a class="page-link" href="{{ site.paginate_path | relative_url | replace: ':num', page }}">{{ page }}</a>
        </li>
    {% endif %}
{% endfor %}
{% endraw %}
{% endhighlight %}

### Next Button
The next button is more or less identical to the previous button. The difference being that `paginator.next_page` is the boolean checked to see if the button is enabled and `paginator.next_page_path` contains the URL for the next page.

{% highlight django %}
{% raw %}
{% if paginator.next_page %}
    <li class="page-item">
    <a class="page-link" href="{{ paginator.next_page_path | relative_url }}" aria-label="Next">
        <span aria-hidden="true">Next &raquo;</span>
    </a>
    </li>
    
{% else %}
    <li class="page-item disabled">
    <a class="page-link"><span aria-hidden="true">Next &raquo;</span></a>
    </li>
{% endif %}
{% endraw %}
{% endhighlight %}

## Post Layout
Recall that the front of any content for a Jekyll site has a [Front Matter](https://jekyllrb.com/docs/front-matter/) section. 

{% highlight yaml %}
---
layout: post
title: Blogging Like a Hacker
---
{% endhighlight %}

In all our pages to this point, the `layout` field has been `default`, which matches the layout found in `_layouts/default.html`. 
For blog posts, some additional formatting will be required, while still using the base template that is defined in the default layout. Jekyll supports this type of template inheritance simply by including Front Matter at the top of the layout that references another layout. 

The `post.html` is a modified version from the base minima theme. Our version will be updated to include a simple navigation menu (next/previous post). 
<hr/>
<details>
<summary> View complete post.html layout </summary>


{% highlight django %}
{% raw %}

---
layout: default
---
<article class="post h-entry" itemscope itemtype="http://schema.org/BlogPosting">

  <header class="post-header">
    <h1 class="post-title p-name" itemprop="name headline">{{ page.title | escape }}</h1>
    <p class="post-meta">
      <time class="dt-published" datetime="{{ page.date | date_to_xmlschema }}" itemprop="datePublished">
        {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
        {{ page.date | date: date_format }}
      </time>
      {%- if page.author -%}
        • <span itemprop="author" itemscope itemtype="http://schema.org/Person"><span class="p-author h-card" itemprop="name">{{ page.author }}</span></span>
      {%- endif -%}</p>
  </header>

  <div class="post-content e-content" itemprop="articleBody">
    {{ content }}
  </div>

  <a class="u-url" href="{{ page.url | relative_url }}" hidden></a>
</article>

<div class="p-author text-center">
{% if page.previous %}
  
    <a href={{page.previous.url | relative_url}}>{{page.previous.title}}</a>
    &laquo; Previous Post

{% endif %}

{% if page.next and page.previous %}
 | 
{% endif %}

{% if page.next %}

    Next Post &raquo;
    <a href={{page.next.url | relative_url}}>{{page.next.title}}</a>

{% endif %}
{% endraw %}
{% endhighlight %}

</details>
<hr/>

The previous/next links drawn at the bottom of each post use the `page.previous` and `page.next` properties, respectively. The `previous` and `next` properties of the current page, if defined, are `page` objects themselves. That means those properties have the variables we need, such as the URL and title. 

## Latest Post in Sidebar
For convenience, it would be nice to render a link to the latest blog post in the sidebar. The following code block will be added to the bottom of `_includes/sidebar.html`:

{% raw %}
```html
<div class="text-center border-top">
    latest post
    <p>
    {% for post in site.posts limit:1 %}
        <a href="{{post.url | relative_url}}">{{post.title}}</a>
    {% endfor %}
    </p>
</div>
```
{% endraw %}

The [Liquid `limit`](https://shopify.github.io/liquid/tags/iteration/) tag allows us to (huge surprise) *limit* the number of items that are iterated across in a for loop. The `site.posts` list is sorted by publishing date so the first one should always be the latest. 

# Conclusion
It's been a bit of work, but the plumbing is now in place for a blogging system. Creating a new post is as easy as dropping a new file in `_posts/` with the name corresponding to the following format: `YYYY-MM-DD-title.md`. I'm truly impressed how flexible Jekyll's blogging system is, right out of the box! 