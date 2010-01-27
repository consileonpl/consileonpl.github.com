---
layout: default
title: "Consileon PL - DevBlog"
description: ""
---
<h2 style="padding-top:1em;" class="green">Entries:</h2>
<ul>{% for post in site.posts %}
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
  </li>{% endfor %}
</ul>
{% for page in site.posts limit:5 %}
{% assign body = page.content %}
{% include post-div.html %}
{% endfor %}

