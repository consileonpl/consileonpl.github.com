---
layout: post
title: jQuery - czyste szablony HTML
categories: [jquery]
---

Ta historia będzie o [jquery pure templates](http://github.com/mpapis/jquery-pure-templates/) - czyste wzorce HTML w jquery.

Podczas pisania kodu na nowym projekcie znalazłem świetną bibliotekę [Pure napisaną przez BeeBole](http://beebole.com/pure/) i miałem właśnie o niej pisać. Ale wraz z użyciem jej znajdowałem coraz więcej problemów. Najpierw chciałem naprawić tą bibliotekę, ale w środku debugowania okazało się to nie takie proste, 20 kilobajtów źródeł ciężko zmienić.

Zdecydowałem się więc napisać swoją bibliotekę opisującą podobną ideę, ale wykorzystując inne podejście. Moja biblioteka jest nadal *czysta*, nie wymaga jednak śmiesznych znaczników HTML żeby wypełnić go danymi, wystarczy napisać kod który zawiera selektory jquery. Moja pierwsza próba została wykonana z użyciem selektorów jquery bezpośrednio w definicji danych:

{% highlight js %}
data = {'a#my':"my url",'a#my@href':"#/url"}
{% endhighlight %}

Po napisaniu działającego kodu wzorcowego tylko w 3 godziny pomyślałem że dobrze by było mapować klucze z danych na selektory w jquery, tak żeby serwer nie musiał zwracać selektorów jako kluczy w JSON:

{% highlight js %}
data2 = {'name':"my url",'link':"#/url"}
{% endhighlight %}

Do tego potrzebna jest prosta mapa:

{% highlight js %}
map2 = {'name':'a#my','link':'a#my@href'}
{% endhighlight %}

Więc jak to uruchomić ? Proste :). Załącz bibliotekę w swoim kodzie (najlepiej w nagłówku):

{% highlight html %}
<script src="jquery-pure-template.js" type="text/javascript" charset="utf-8"></script>
{% endhighlight %}

I wywołaj render na elementach wybranych przez jquery:

{% highlight js %}
$('.user').render(data);
{% endhighlight %}

Lub używając mapy:

{% highlight js %}
$('.user').render(data2,{map:map2});
{% endhighlight %}

Do działania potrzebny jest wzorzec (template) HTML:

{% highlight js %}
<div class="user"><a href="#"></a></div>
{% endhighlight %}

na koniec otrzymamy oto taki wynik w HTML:

{% highlight js %}
<div class="user"><a href="#/url">my url</a></div>
{% endhighlight %}

To był prosty przykład, ale ta biblioteka działa także z tablicami oraz zagnieżdżonymi tablicami, po prostu dajcie temu szanse, i pamiętajcie: nie zmuszajcie HTML do określania logiki, niech dane posterują logiką nie widok.

Oczywiście założone rozwiązanie może mieć kilka problemów, najważniejszy to wydajność. Tablice powyżej 500 elementów zaczynają zwalniać, ale używając zagnieżdżonych tablic można spokojnie operować na 5000 elementów na w miarę nowoczesnym komputerze. Dodatkowo dodanie ``id`` do zbiorów może przyśpieszyć kod nawet o 20% (znajdowanie elementów przez jquery).

Wiem że istnieją szybsze rozwiązania, które mogą bez problemu wyświetlić duże ilości danych, ale moje jest proste, tylko 70 linii kodu, to czyni je niesamowicie prostym w utrzymaniu i modyfikacji. Łatwiej pracować z mniejszą ilością kodu :).

This article is also available in english version: [http://niczsoft.com/2010/11/jquery-pure-templates/](http://niczsoft.com/2010/11/jquery-pure-templates/)

{% include bio_michal_papis.html %}