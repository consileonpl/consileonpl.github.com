
desc "generate categories pages"

task :categories do
  require "rubygems"
  require "jekyll"
  include Jekyll::Filters
  
  options = Jekyll.configuration({})
  site = Jekyll::Site.new(options)
  site.read_posts("");
  site.categories.sort.each do |category, posts|
    html = <<-HTML
---
layout: default
title: "Consileon PL - DevBlog"
description: ""
---

<div class="related">
  <div id="rest">
    <h1>Kategoria \"#{category}\":</h1>
    <p>{% for post in site.categories.#{category} %}<a href="{{ post.url }}">{{ post.title }}</a>{% unless forloop.last %} &middot; {% endunless %}{% endfor %}</p>
  </div>
</div>    
HTML
    File.open("tags/#{category}.html", 'w+') do |file|
      file.puts html
    end
  end
  
  html = "<ul>\n"
  site.categories.sort.each do |category, post|
    html += "<li><a href='/tags/#{category}.html'>#{category}</a></li>\n"
  end 
  html += "</ul>\n"
  
  File.open("_includes/categories.html", 'w+') do |file|
    file.puts html
  end

end
