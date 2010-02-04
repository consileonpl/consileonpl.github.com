
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

<div id="entries">
  <h1>Kategoria \"#{category}\":</h1>
  <ul> 
    {% for post in site.categories.#{category} %}
    <li><a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endfor %}
  </ul>
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
