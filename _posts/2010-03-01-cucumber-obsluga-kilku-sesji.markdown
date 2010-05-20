---
layout: post
title: Cucumber - obsługa kilku sesji
categories: [rubyonrails, cucumber]
---
Większość standardowych zadań związanych z testowaniem aplikacji jest w prosty sposób do zrealizowania z użyciem domyślnych kroków Cucumbera. Z założenia [Cucumber](http://cukes.info/) służy do testów funkcjonalnych, lecz można go również zastosować do realizacji "testów" integracyjnych. Chodzi mi o taką sytuację kiedy chcemy przetestować w jednym scenariuszu interakcje pomiędzy działaniami kilku użytkowników, szczególnie gdy z jakiś powodów nie możemy używać ponownego wylogowania i zalogowania, gdyż wpływa ono w jakiś sposób na stan aplikacji. Na ten problem zwrócił mi uwagę mój kolega [Michał Papis](http://niczsoft.com)

W przypadku standardowych wbudowanych mechanizmów testowania możemy skorzystać z bloku
**open_session**:

{% highlight ruby %}
def login(user)
  open_session do |sess|
    sess.extend(CustomDsl)
    u = users(user)
    sess.https!
    sess.post "/login", :username => u.username, :password => u.password
    assert_equal '/welcome', path
    sess.https!(false)
  end
end
{% endhighlight %}

Lecz w przypadku cucumbera, który opiera się o poszczególne definicje kroków konieczne jest znalezienie rozwiązania pasującego do formy w jakiej tworzone są scenariusze.

W tym celu przygotowałem taki oto plik kroków (**mizzeria_steps.rb**):

{% highlight ruby %}
module ActionController
  module Integration
    class Session
      def switch_session_by_name(name)
        if @sessions_by_name.nil?
          @sessions_by_name = { :default => @response.session.clone }
        end
        @sessions_by_name[name.to_sym] ||= @sessions_by_name[:default].clone
        @response.session = @sessions_by_name[name.to_sym]
      end
    end
  end
end

Given /^session name is "([^\"]*)"$/ do |name|
  switch_session_by_name(name)
end
{% endhighlight %}

Użycie tego mechanizmu (multiple session) jest trywialnie proste, wykonujemy następujący krok:

{% highlight cucumber %}
Given session name is "new user"
{% endhighlight %}

W tym przypadku tworzona jest **nazwana** sesja która jest nie zależna od innych (również od domyślnej). Dostęp do domyślnej nazwanej sesji odbywa się poprzez użycie nazwy: **default**

{% highlight cucumber %}
Given session name is "default"
{% endhighlight %}

Jak to mówią małe proste i funkcjonalne rozwiązanie, a cieszy :)

Lektura obowiązkowa:
[http://guides.rubyonrails.org/testing.html#integration-testing-examples](http://guides.rubyonrails.org/testing.html#integration-testing-examples)


[http://andrzejsliwa.com/2010/03/01/cucumber-obsluga-kilku-sesji/](http://andrzejsliwa.com/2010/03/01/cucumber-obsluga-kilku-sesji/)

{% include bio_andrzej_sliwa.html %}