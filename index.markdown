---
layout: default
title: "Consileon PL - DevBlog"
description: ""
---
{% for page in site.posts limit:5 %}
{% assign body = page.content %}
{% include post-div.html %}
{% endfor %}
<ul>{% for post in site.posts %}
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
  </li>{% endfor %}
</ul>
