---
layout: default
title: "Consileon PL - DevBlog"
description: ""
---
<div id="entries">
<h1>Ostatnie wpisy:</h1>
  <ul>{% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}.</a>
    </li>{% endfor %}
  </ul>
</div>
{% for page in site.posts limit:5 %}
{% assign body = page.content %}
{% include post-div.html %}
{% endfor %}

