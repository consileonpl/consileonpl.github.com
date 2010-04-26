---
layout: post
title: Rails i Train Wrecks
categories: [ruby, rubyonrails]
---
Frameworki [ORM](http://en.wikipedia.org/wiki/Object-relational_mapping) takie jak Hibernate czy ActiveRecord pozwalają
nam w dość naturalny sposób przechodzić pomiędzy zależnościami modeli (encji). Wystarczy po kropce dodać nazwę
atrybutu i gotowe. Niestety takie podejście kończy się tym, że wywołania kolejnych zależności ciągną się
w nieskończoność:

{% highlight ruby %}
user.profile.address.city.zip_code
{% endhighlight %}

Takie konstrukty nazywamy z angielska *train wreck*. Nie jest to dobre podejście z punktu widzenia programowania obiektowego,
gdyż ujawnia zbyt dużą ilość informacji na temat wewnętrznej implementacji obiektu. Po co nam informacja w jaki sposób
klasa przechowuje kody pocztowe?

Aby ulepszyć naszą klasę i poprawić jej hermetyzację musimy skorzystać z mechanizmu delegacji. Moglibyśmy w modelu
``User`` utworzyć metodę delegującą wywołanie metody ``zip_code`` do modelu ``Profile``:

{% highlight ruby %}
class User < ActiveRecord::Base

  has_one :profile

  def zip_code
    self.profile.zip_code
  end

end
{% endhighlight %}

W modelu ``Profile`` zdefiniowalibyśmy delegację do ``Address`` a dalej do ``City``. W każdym z tych modeli (poza ``City``)
musimy utworzyć metodę delegująca, aby ostatecznie dobrać się do kodu pocztowego. Dzięki mechanizmowi delegacji zamiast wcześniejszego
łańcuszka możemy wykonać:

{% highlight ruby %}
user.zip_code
{% endhighlight %}

W tym momencie wewnętrzna implementacja klasy ``User`` jest przed nami ukryta.

Jak się jednak okazuje framework Rails daje nam inny, bardziej deklaratywny sposób definiowania delegacji.

## Dyrektywa ``delegate``

Dyrektywa ``delegate`` pozwala nam zadeklarować delegację, bez potrzeby tworzenia faktycznej metody:

{% highlight ruby %}
class User < ActiveRecord::Base

  has_one :profile
  delegate :zip_code, :to => :profile

end
{% endhighlight %}

Dzięki temu nie tylko zaoszczędziliśmy nieco linii kodu i parę klepnięć w klawiaturę, ale i definicja naszej klasy
staje się czytelniejsza, ponieważ nie zaśmiecamy jej metodami nie do końca biznesowymi. Poza tym taka deklaracja jawnie mówi nam,
że chcemy delegować komunikat. Deklaratywność ta przydaje nam się, jeżeli chcemy dodać delegację kolejnego komunikatu.
Po prostu dodajemy go do listy:


{% highlight ruby %}
class User < ActiveRecord::Base

  has_one :profile
  delegate :zip_code, :zip_code=, :to => :profile

end
{% endhighlight %}

Zamiast tworzyć dwie metody deklarujemy delegacje w jednym wyrażeniu. Co ciekawe, możemy nawet pominąć konieczność
powtarzania delegacji w kolejnych klasach i od razu zadeklarować delegację z modelu ``User`` do ``City``:

{% highlight ruby %}
class User < ActiveRecord::Base

  has_one :profile
  delegate :zip_code, :zip_code=, :to => 'profile.address.city'

end
{% endhighlight %}

Niestety to podejście pozostawia nam train wrecka i wywleka wewnętrzną implementację modelu ``Profile`` na wierzch, stąd
nie polecam tego podejścia.

To jeszcze nie koniec. Załóżmy, że nasz model ``User`` posiada atrybut ``name`` i taki sam atrybut posiada model ``City``.
Co jeżeli chcielibyśmy delegować pobieranie nazwy miasta w postaci komunikaty ``city_name``? Rails udostępnia nam taką
możliwość:

{% highlight ruby %}
class User < ActiveRecord::Base

  has_one :profile
  delegate :zip_code, :zip_code=, :to => :profile
  delegate :name, :to => :profile, :prefix => :city

end
{% endhighlight %}

Jest tutaj pewna subtelna pułapka. Mianowicie o ile zadeklarowaliśmy, że komunikat ``city_name`` ma być delegowany
do modelu ``Profile`` (a dalej aż do ``City``), to komunikat wysłany do tego modelu będzie bez prefiksu, czyli ``name``.
Oznacza to, że nasz model pośredniczący ``Profile`` musi delegować komunikat ``name`` bez prefiksu ``city_``:

{% highlight ruby %}
class Profile < ActiveRecord::Base

  has_one :address
  belongs_to :user
  delegate :zip_code, :zip_code=, :to => :address
  delegate :name, :to => :address

end
{% endhighlight %}

Podobna sytuacja jest w modelu ``Address``. Co ważne ani ``Profile`` ani ``Address`` nie mogą definiować metody ``name``,
gdyż ta metoda zostanie wywołana zamiast oddelegowania do kolejnego modelu.

## Podsumowanie

Poprawna enkapsulacja, czyli [hermetyczne odseparowanie implementacji klasy od świata zewnętrznego](/blog/2010/03/enkapsulacja-a-modyfikowanie-stanu-obiektow/)
pozwala nam tworzyć kod, w którym klasy są luźniej powiązane i zmiany w nich nie niszczą innych części systemu. Delegacja
pełni bardzo ważną rolę w zapewnianiu poprawnej hermetyzacji. Framework Rails pozwala nam w bardziej deklaratywny sposób
zarządzać delegacjami. Nie musimy tworzyć żadnych metod, a w czytelny sposób deklarujemy, iż chcemy delegować wywołanie
danego komunikatu do kolejnego obiektu.

[http://michalorman.pl/blog/2010/03/rails-i-train-wrecks/](http://michalorman.pl/blog/2010/03/rails-i-train-wrecks/)

{% include bio_michal_orman.html %}