---
layout: post
title: Wieloplatformowe frameworki mobilne - PhoneGap
categories: [android, framework, mobilne]
---
Platformy mobilne takie jak iPhone czy Android zdobywają coraz większą popularność. Serwisy takie jak Apple App Store czy Google Market
posiadają już pokaźną bibliotekę aplikacji dostępnych dla tych platform i co chwila pojawiają się nowe. Niestety każdy programista
chcący tworzyć aplikacje mobilne stoi przed nie lada dylematem. Musi wybrać platformę dla której chce tworzyć aplikacje. Wybór ten nie
jest taki prosty. Choć teraz iPhone jest liderem to Android [depcze mu po piętach](http://feedproxy.google.com/~r/OSnewspl/~3/mNHnKxsQa8w/).
Dlaczego zatem nie tworzyć aplikacji wieloplatfomowej dającej uruchomić się zarówno na jednej jak i drugiej platformie (a także na
Symbianie, Blackberry itd.)?

Istnieje kilka frameworków pozwalających tworzyć wieloplatfomowe aplikacje mobilne. Frameworki te stworzone są z użyciem podobnej
architektury, czyli aplikacji webowej uruchamianej wewnątrz odpowiedniej kontrolki na danej platformie. Dzięki temu nasza aplikacja
webowa jest uruchamiana lokalnie. Dlaczego chcielibyśmy w taki właśnie sposób ją wykonywać, a nie po prostu poprzez umieszczenie
jej na serwerze? Ano dlatego, że taką aplikację możemy dystrybuować w App Store albo Google Market, a do tego aplikacja taka ma dostęp
do bibliotek natywnych niedostępnych dla aplikacji uruchamianych za pomocą przeglądarki (ograniczenie to wynika z polityki
bezpieczeństwa tych platform).

## PhoneGap

[PhoneGap](http://www.phonegap.com/) to framework pozwalający aplikacje webowe napisane za pomocą HTML'a i JavaScriptu osadzić
wewnątrz platformy mobilnej. Dzięki dołączonej bibliotece JS otrzymujemy dostęp do natywnych funkcjonalności telefonu tj. geolokacji,
akcelerometru, aparatu fotograficznego, wibracji oraz orientacji telefonu czy gestów i multitouch. Pełna lista funkcjonalności i
wspieranych platform znajduje się [tutaj](http://wiki.phonegap.com/Roadmap).

Ponieważ aplikacje tworzone przez nas są w istocie web aplikacjami musimy pogodzić się z pewnymi ograniczeniami. Po pierwsze
wygląd naszej aplikacji (ang. look-and-feel) nie będzie przypominał wyglądu aplikacji natywnych. Dodatkowo nie mamy możliwości użycia
natywnych kontrolek, a także dodatkowych funkcjonalności platformy (np. animacji 3d). Wygląd i działanie naszej aplikacji
ogranicza się do tego co oferuje nam HTML i JS, tak więc jeżeli planujemy za pomocą tego frameworku pisać gry, to lepiej sobie
go odpuścić. Framework ten nadaje się do biznesowych aplikacji typu "wypełnij formularz".

### Jak zacząć zabawę z PhoneGap i Androidem

Generalnie zacząć tworzyć aplikację z PhoneGap jest bardzo prosto, pod warunkiem, że nie korzystamy z opisu dostępnego na stronie
tego frameworka. Opis ten jest nie dość, że nieprofesjonalnie napisany, to jeszcze nieaktualny.

Zanim zaczniemy zabawę z PhoneGap (i generalnie każdym innym frameworkiem) musimy zainstalować SDK platformy dla jakiej tworzymy
aplikację. Ponieważ ja tworzyłem dla Androida musiałem zainstalować [Android SDK](http://developer.android.com/sdk/index.html).
Narzędzie to posiada także menadżera do instalowania bibliotek konkretnych platform. Ja zainstalowałem sobie platformy dla
Androida w wersjach 1.6 oraz 2.1.

Mając zainstalowane SDK, oraz odpowiednią platformę ściągamy [Eclipse'a](http://www.eclipse.org/) oraz plugin [ADT](http://developer.android.com/sdk/eclipse-adt.html)
dzięki któremu będziemy mogli tworzyć projekty i uruchamiać emulator.

Teraz ściągamy PhoneGap:

      git clone git://github.com/sintaxi/phonegap.git

Tworzymy nowy "Android Project" w Eclipse:

<a href="/images/phonegap/create-project.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/phonegap/create-project.png" alt="Nowy projekt" /></a>

W kolejnym dialogu zaznaczamy iż chcemy stworzyć projekt z istniejącego źródła ("Create project from existing source") a jako źródło
wybieramy katalog ``android/framework`` z katalogu w którym ściągnęliśmy PhoneGap. Zaznaczamy jeszcze platformę, przy czym
aktualna wersja PhoneGap wymaga platformy co najmniej 2.0 (w moim przypadku użyłem 2.1):

<a href="/images/phonegap/new-android-project.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/phonegap/new-android-project.png" alt="Nowy projekt" /></a>

Jeżeli zaznaczymy platformę w wersji 1.6 nasza aplikacja nie będzie w stanie się zbudować:

    Unable to resolve target 'android-5'

Możemy teraz uruchomić naszą aplikację w emulatorze. Klikamy "Run As..." i wybieramy "Android Application":

<a href="/images/phonegap/run-as.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/phonegap/run-as.png" alt="Uruchom jako" /></a>

Aplikacja powinna uruchomić się bez problemu:

<a href="/images/phonegap/emulator-app1.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/phonegap/emulator-app1.png" alt="Nowy projekt" /></a>

Spróbujmy zmodyfikować co nieco, aby upewnić się, że cokolwiek działa. Ponieważ tworzymy aplikację webową, nasz kod de facto nie
znajduje się w katalogu ``src`` a ``assets/www``. Także przechodzimy do edycji pliku ``index.html``:

{% highlight html %}
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
  "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <meta name="viewport" content="width=320; user-scalable=no" />
    <meta http-equiv="Content-type" content="text/html; charset=utf-8">
    <title>Hello, PhoneGap!</title>
    <link rel="stylesheet" href="master.css" type="text/css" media="screen" title="no title" charset="utf-8">
    <script type="text/javascript" charset="utf-8" src="phonegap.js"></script>
  </head>

  <body onload="init();" id="stage" class="theme" style="padding: 2em">
  <h1>Hello, PhoneGap!</h1>
     <p style="text-align: center; background-color: #333">
       Sample 'Hello' application on Android.
     </p>
     <p style="text-align: center; font-size: 0.8em">
       Powered by PhoneGap.
     </p>
  </body>
</html>
{% endhighlight %}

Uruchamiamy ponownie (jeżeli nie zamknęliśmy emulatora, nie będzie potrzeby ponownej inicjalizacji
platformy):

<a href="/images/phonegap/emulator-app2.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/phonegap/emulator-app2.png" alt="Nowy projekt" /></a>

Ok działa. Na bardziej poważne aplikacje przyjdzie jeszcze czas.

## Wady i zalety PhoneGap

Niewątpliwą zaletą PhoneGap jest możliwość tworzenia aplikacji za pomocą HTML'a, CSS'a i JavaScript'u. Dzięki temu
aplikacje są wieloplatformowe i jednocześnie nie ma potrzeby uczenia się architektury i API poszczególnych platform.
Dodatkowo nasze aplikacje możemy testować w normalnej przeglądarce na naszym laptopie, bez potrzeby uruchamiania
emulatora. Co ważne możliwość uruchomienia naszej aplikacji poza platformą pozwala nam na stworzenie
zautomatyzowanych testów np. za pomocą [Selenium](http://seleniumhq.org/).

Do wad tego frameworka należy zaliczyć brak natywnego wyglądu naszych aplikacji, a także natywnych kontrolek, przez
co nasze listy wyboru i inne pola będą wyglądały jak w przeglądarce, a nie w aplikacjach natywnych. Kolejną wadą
tej platformy jest dość słaba i często nieaktualna dokumentacja, także bardzo często trzeba będzie wspierać się
pomocą wujka Google. Brakuje takiego opisu krok po kroku omawiającego zagadnienia tego frameworka (kto wie,
może stworzę takowy na niniejszym blogu :).

## Podsumowanie

Nie ma co ukrywać, że frameworki pozwalające tworzyć wieloplatformowe aplikacje mobilne będą zdobywać coraz
większą popularność. Aplikacje niejako muszą być tworzone na kilka platform jednocześnie a utrzymywanie kodu dla
każdej platformy z osobna jest tylko stratą pieniędzy.

Jednym z rozwiązań pozwalających nam na tworzenie wieloplatformowych aplikacji mobilnych jest framework
PhoneGap. Potrafi on osadzić naszą aplikację webową w lokalnym środowisku platformy co daje wrażenie
uruchamiania aplikacji natywnej. Zaletą tego frameworka jest użycie powszechnie znanych webowych technologii
tj. HTML i JavaScript-u. Niestety korzystając z tego frameworka musimy pogodzić się, że nasze aplikacje
nie będą wykorzystywać natywnych kontrolek, a ich wygląd nie będzie przypominał prawdziwych aplikacji
napisanych na konkretną platformę. Framework ten nadaje się do tworzenia wszelkich aplikacji biznesowych
opartych o wypełnianie formularzy i przeglądanie kolekcji danych.

W kolejnym wpisie przedstawię kolejny framework [Titanium](http://developer.appcelerator.com/).

[http://michalorman.pl/blog/2010/04/wieloplatformowe-frameworki-mobilne-phonegap/](http://michalorman.pl/blog/2010/04/wieloplatformowe-frameworki-mobilne-phonegap/)

{% include bio_michal_orman.html %}