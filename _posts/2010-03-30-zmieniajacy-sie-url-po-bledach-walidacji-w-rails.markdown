---
layout: post
title: Zmieniający się URL po błędach walidacji w Rails
categories: [ruby, rubyonrails]
---
Wygenerujmy sobie proste rusztowanie (ang. scaffolding):

    script/generate scaffold user first_name:string last_name:string

Następnie dodajmy kilka walidacji dla naszego modelu:

{% highlight ruby %}
class User < ActiveRecord::Base
  validates_presence_of :first_name, :last_name
end
{% endhighlight %}

Odpalamy migracje i wchodzimy na:

    http://localhost:3000/users/new

Nie wypełniając żadnego pola klikamy przycisk ``Create``. Niby wszystko gra, dostajemy informacje o błędach walidacji
i takie tam. Jednak jeżeli przyjrzymy się dokładnie, a w szczególności adresowi URL to widzimy:

    http://localhost:3000/users

Adres się zmienił! Ale przecież nie klikaliśmy żadnego linku! Ba nawet w kodzie nie ma w tym miejscu przekierowania:

{% highlight ruby %}
def create
  @user = User.new(params[:user])

  respond_to do |format|
    if @user.save
      # ...
    else
      format.html { render :action => "new" }
      # ...
    end
  end
end
{% endhighlight %}

Dlaczego zatem adres się zmienił?

## Źródło problemu

Aby zrozumieć dlaczego tak się stało musimy przeanalizować kod HTML wygenerowany dla formularza. Wchodzimy jeszcze raz
na formularz, wyświetlamy źródło strony i szukamy znacznika ``<form>``:

{% highlight html %}
<form action="/users" class="new_user" id="new_user" method="post">
    <!-- Pola formularza -->
</form>
{% endhighlight %}

Widać, że posiada on atrybut ``action`` z wartością ``/users``. Oznacza to, że przeglądarka wygeneruje żądanie ``POST``
pod adres ``http://localhost:3000/users``. Rzućmy okiem na nasz routing:


    $ rake routes | grep create
          POST   /users(.:format)                   {:controller=>"users", :action=>"create"}

Widzimy, że faktycznie spodziewamy się takiego żądania pod ten adres, a ponieważ metoda ``render`` w odróżnieniu od
``redirect_to`` nie generuje przekierowania w przeglądarce ustawiony zostaje adres taki jak przy żądaniu ``POST``. Wszystko
zatem działa poprawnie, bo tak zostało skonfigurowane. Czy to jest błąd? To pewnie zależy od aplikacji, w każdym razie
niezbyt profesjonalne jest kiedy adres URL zmienia się bez wyraźnego powodu. Oto kilka sposobów jak sobie można z tym
poradzić.

## Flash

Flash to jest tymczasowy bufor w Rails, w którym możemy przechować dane pomiędzy kolejnymi żądaniami HTTP (w jednym coś
wrzucamy a w następnym wyciągamy). Najczęściej flasha używa się do przekazywania komunikatów, w buforze może być umieszczany
jednakże nie tylko tekst.

Zatem możemy nasze wywołanie metody ``render``, które renderuje tylko wybrany szablon, a nie generuje przekierowania
zamienić na ``redirect_to``. Ponieważ kolejne żądanie spowoduje utworzenie nowego obiektu kontrolera potrzebujemy sposobu
przechowania naszego utworzonego obiektu ``user`` aby nie zgubić błędów walidacji. Możemy się posłużyć właśnie buforem
flash:

{% highlight ruby %}
class UsersController < ApplicationController
  def new
    @user = flash[:user] || User.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        # ...
      else
        flash[:user] = @user
        format.html { redirect_to :action => "new" }
      end
    end
  end

  # Reszta metod ...
end
{% endhighlight %}

To podejście jest proste i działa, jednakże ma swoje wady. Bufor flash jest trzymany w sesji co oznacza, że obiekty,
które tam wrzucamy muszą dać się serializować. Do tego w przypadku, gdy sesja jest trzymana w ciasteczkach mamy ograniczenie
4KB na dane sesji. Generalnie wrzucanie dużych obiektów (albo i w ogóle obiektów) do sesji to zły pomysł, raczej posługujemy
się identyfikatorami. Dodatkowo w tym podejściu generujemy dodatkowe żądanie do serwera (co generalnie nie jest nam
aż tak bardzo potrzebne).

Tak więc to podejście może być jedynie szybkim, tymczasowym rozwiązaniem, jednak aby w pełni
sobie poradzić z problemem, trzeba się nieco bardziej wysilić.

## Routing

Innym rozwiązaniem może być modyfikacja routingu.

W tym momencie nasz plik ``routes.rb`` definiuje standardowy routing, dla kontrolera ``:users``:

{% highlight ruby %}
map.resources :users
{% endhighlight %}

Możemy wyrzucić routing na metodę ``create`` i dodać ręcznie routing kierujący żądania ``POST`` wysłane na adres ``/users/new``
do tej metody:

{% highlight ruby %}
map.resources :users, :except => [ :create ]
map.connect 'users/new',
            :conditions => { :method => :post },
            :controller => :users,
            :action => :create
{% endhighlight %}

Musimy jeszcze zmienić adres w formularzu:

{% highlight erb %}
<% form_for(@user, :url => new_user_path) do |f| %>
    <!-- Pola formularza -->
<% end %>
{% endhighlight %}

(Podobnie należałoby postąpić z metodą ``update``.)

Podejście to działa i jest pozbawione wad poprzedniej metody. Wymaga nieco więcej wysiłku, ale nie generujemy dodatkowych
przekierowań ani nie wrzucamy niczego do sesji. Problemem jest jedynie na stałe wprowadzony adres ``users/new`` w routingu.

Możemy również pominąć deklarację routingu na metodę ``create`` i w metodzie ``new`` rozpatrywać rodzaj żądania. Ten sposób
jest jednak mało deklaratywny i nie przynosi niczego szczególnie dobrego.

## Podsumowanie

Routing oparty na zasobach, mimo iż w prosty sposób pozwala nam na tworzenie aplikacji RESTful-owych nie jest pozbawiony
wad. Jedną z nich jest zamiana adresu URL dla formularza, nawet jeżeli pozostajemy wciąż na tym samym ekranie. Nie w
każdej aplikacji będzie to błąd, jednak nie świadczy to zbyt dobrze o twórcy aplikacji.

Jest kilka sposobów na radzenie sobie z tym problemem. Możemy zamiast renderowania szablonu wykonać przekierowanie na
odpowiedni adres URL przechowując zwalidowany obiekt w buforze flash. Możemy także ręcznie zmodyfikować routing w pliku
``routes.rb``. Innym sposobem, nie opisanym tutaj. może być wykorzystanie AJAX-u do walidacji. Podejście to wymaga
najwięcej pracy, ale jednocześnie daje aplikację bardziej responsywną i przyjazną użytkownikowi.

[http://michalorman.pl/blog/2010/03/zmieniajacy-sie-url-po-bledach-walidacji-w-rails/](http://michalorman.pl/blog/2010/03/zmieniajacy-sie-url-po-bledach-walidacji-w-rails/)

{% include bio_michal_orman.html %}