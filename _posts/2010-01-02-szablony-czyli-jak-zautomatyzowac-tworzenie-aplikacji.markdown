---
layout: post
title: App Templates - szybki start tworzenia aplikacji
categories: [rubyonrails, git]
---
[Ruby on Rails](http://rubyonrails.org) z wersji na wersję podlega naturalnej ewolucji. Jest to proces ciągły, oparty na reagowaniu jego użytkowników na nowe wymagania stawiane przed frameworkiem. Aktualna gałąź [2.3](http://guides.rubyonrails.org/2_3_release_notes.html) wprowadza szereg udogodnień związanych między innymi z automatyzacją procesu tworzenia aplikacji. Wprowadzono prosty język [DSL](http://en.wikipedia.org/wiki/Domain-specific_language) za pomocą którego jesteśmy w stanie projektować własne szablony.
Szablony te mogą się na wzajem wywoływać co pozwala na modułowe wykorzystanie.

Przykład szablonu automatyzującego dodawanie aplikacji do repozytorium [GIT](http://git-scm.com/):

{% highlight ruby %}
log 'GIT template', 'Starting template'

unless self.respond_to?(:already_using)
  template = ENV['TEMPLATE_BASE'] || 'http://github.com/andrzejsliwa/config/raw/master/templates'
  load_template("#{template}/helpers_methods.rb")
  @stand_alone = true
end

already_using('.git/config', 'GIT')

# Remove temp directories.
%w[cache pids sessions sockets].each do |dir|
  rmdir "tmp/#{dir}"
end

# Remove unnecessary files.
%w[index.html favicon.ico robots.txt].each do |file|
  rm "public/#{file}"
end
rm 'doc/README_FOR_APP'

# Hold empty directories touching a .gitignore file
run("find . \\( -type d -empty \\) -and \\( -not -regex ./\\.git.* \\) -exec touch {}/.gitignore \\;", false)

# Copy database.yml for reuse
cp 'config/database.yml', 'config/database.yml.example'

# Create root .gitignore file from template
config_file '.gitignore'

git :init

if @stand_alone
  # Initial commit
  git :add => "."
  git :commit => "-a -m 'initial import.'"
end

log 'GIT template', 'Successfully applied template'
{% endhighlight %}

Użycie przykładowego szablonu może odbywać się na 2 sposoby:

w trakcie tworzenia aplikacji:

{% highlight ruby %}
$ rails application_name
-m  http://github.com/andrzejsliwa/config/raw/master/templates/git.rb
{% endhighlight %}

w dowolnym momencie wykorzystując wbudowany task Rake'a:

{% highlight ruby %}
$ rake rails:template
LOCATION=http://github.com/andrzejsliwa/config/raw/master/templates/git.rb
{% endhighlight %}

Zapraszam do zapoznania się z tym mechanizmem, umiejętnie wykorzystany może zaoszczędzić nam mnóstwo czasu związanego z konfiguracją aplikacji.

Na koniec przykład pliku szablonu nad którym obecnie jeszcze pracuję, a który ma zautomatyzować konfigurację aplikacji pod [Cucumber](http://cukes.info/) / [Rspec](http://rspec.info/) oraz [Authologic](http://github.com/binarylogic/authlogic). Skrypt ten wykorzystuje wyżej prezentowany `git.rb`:

{% highlight ruby %}
log 'BASE template', 'Starting base template'

template = ENV['TEMPLATE_BASE'] || 'http://github.com/andrzejsliwa/config/raw/master/templates'

unless self.respond_to?(:already_using)
  load_template("#{template}/helpers_methods.rb")
end



gem 'authlogic',          :version => '>=2.1.3', :lib => false
gem 'gemcutter',          :version => '>=0.2.1', :lib => false

gem 'rcov',               :version => '>=0.9.7', :lib => false, :env => 'test'
gem 'database_cleaner',   :version => '>=0.4.0', :lib => false, :env => 'test'
gem 'webrat',             :version => '>=0.6.0', :lib => false, :env => 'test'
gem 'rspec',              :version => '>=1.2.9', :lib => false, :env => 'test'
gem 'rspec-rails',        :version => '>=1.2.9', :lib => false, :env => 'test'
gem 'cucumber',           :version => '>=0.5.3', :lib => false, :env => 'test'
gem 'cucumber-rails',     :version => '>=0.2.2', :lib => false, :env => 'test'
gem 'autotest',           :version => '>=4.1.4', :lib => false, :env => 'test'
gem 'autotest-rails',     :version => '>=4.1.0', :lib => false, :env => 'test'
gem 'autotest-fsevent',   :version => '>=0.1.3', :lib => false, :env => 'test'
gem 'autotest-growl',     :version => '>=0.1.7', :lib => false, :env => 'test'
gem 'ZenTest',            :version => '>=4.2.1', :lib => false, :env => 'test'
gem 'factory_girl',       :version => '>=1.2.3', :lib => false, :env => 'test'
gem 'email_spec',         :version => '>=0.3.8', :lib => "email_spec", :env => 'test'

rake 'gems:install', :env => 'test'
rake 'gems:install'

# We don't like unittest ;)
rmdir_r "test"

# Get database.yml file
database_yml(:postgresql)

# Run required generators
generate :cucumber
generate :rspec
generate :email_spec

gem 'email_spec', :version => '>=0.3.8', :lib => "email_spec", :env => 'cucumber'

# Get .autotest config file
config_file '.autotest'

rakefile 'rcov.rake', get_source('lib/tasks/rcov.rake')

spec 'rcov.opts'
spec 'spec_helper.rb'

features 'support/env.rb'

rake 'db:create:all'
rake 'db:migrate'
rake 'db:test:load'

load_template("#{template}/haml.rb") if yes?("enable HAML?")

@is_git = yes?("enable GIT?")
load_template("#{template}/git.rb") if @is_git

if @is_git
  # Initial commit
  git :add => "."
  git :commit => "-a -m 'initial import.'"
end

log 'BASE template', 'Successfully applied template'
{% endhighlight %}

Wszystkie aktualne źródła znajdują się tutaj:
[http://github.com/andrzejsliwa/config/tree/master/templates/](http://github.com/andrzejsliwa/config/tree/master/templates/)

Lektura obowiązkowa:
[http://asciicasts.com/episodes/148-app-templates-in-rails-2-3](http://asciicasts.com/episodes/148-app-templates-in-rails-2-3)
[http://m.onkey.org/2008/12/4/rails-templates](http://m.onkey.org/2008/12/4/rails-templates)
[http://guides.rubyonrails.org/2_3_release_notes.html](http://guides.rubyonrails.org/2_3_release_notes.html)


[http://andrzejsliwa.com/2010/01/02/szablony-czyli-jak-zautomatyzowac-tworzenie-aplikacji/](http://andrzejsliwa.com/2010/01/02/szablony-czyli-jak-zautomatyzowac-tworzenie-aplikacji/)

{% include bio_andrzej_sliwa.html %}