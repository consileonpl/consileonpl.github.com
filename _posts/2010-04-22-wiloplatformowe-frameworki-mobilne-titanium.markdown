---
layout: post
title: Wieloplatformowe frameworki mobilne - Titanium
categories: [android]
---


W [poprzednim poście](/blog/2010/04/wieloplatformowe-frameworki-mobilne-phonegap/) przedstawiłem PhoneGap, jako
framework pozwalający na tworzenie wieloplatformowych aplikacji mobilnych. W tym poście chciałbym przedstawić
[Titanium](http://developer.appcelerator.com/) jako framework alternatywny, który choć bazuje na podobnym koncepcie,
różni się jednak w wielu elementach od PhoneGap.

## Titanium

Titanium to framework, który podobnie jak PhoneGap, pozwala na pisanie wieloplatformowych aplikacji mobilnych
z wykorzystaniem HTML-a oraz JavaScript'u. W odróżnieniu jednak od PhoneGap, aplikacje nie są zwyczajnie uruchamiane
jako web aplikacje w odpowiedniej kontrolce. Titanium udostępnia bogate API JavaScript-owe, które deleguje odwołania
do natywnych bibliotek platformy na jakiej uruchamiana jest aplikacja. Co nam to daje? Daje nam to dostęp do
natywnych kontrolek, a nasza aplikacja posiada natywny wygląd (ang. look-and-feel). Jest to niewątpliwie spora zaleta
w porównaniu do tego co oferuje nam PhoneGap.

Titanium obsługuje o wiele mniej platform niż PhoneGap. Obecnie jedynie iPhone, Android i iPad, jednakże programiści
tego frameworka pracują nad wsparciem dla platformy Blackberry. Co ciekawe framework Titanium pozwala na tworzenie
nie tylko wieloplatformowych aplikacji mobilnych, ale także desktopowych.

Mimo, że Titanium wspiera mniejszą liczbę platform niż PhoneGap, jego API jest znacznie bogatsze. Mamy na przykład
możliwość dostępu do danych zarówno lokalnych (system plików, czy wbudowana baza SQL) jak i zdalnych (web service).
Pełna dokumentacja API znajduje się [tutaj](http://developer.appcelerator.com/apidoc/mobile/latest).

Dość ważną rzeczą jest w nauce tego frameworka jest program ["Appcelerator University Training"](http://developer.appcelerator.com/training).
Program ten przedstawia w postaci filmików ogólne informacje na temat samego frameworka, oraz jego API. Niestety
dostęp do filmików opisujących ważniejsze elementy frameworka jest płatny (jest to dość znany model biznesowy
w którym produkt jest darmowy, a całe wsparcie techniczne i szkoleniowe płatne). Niestety na dzień dzisiejszy nie
udało mi się dostać do filmików z poziomu 200, ponieważ po wypełnieniu stosownego formularza strona zwraca błąd
:).

## Pierwsza aplikacja z Titanium na platformę Android

Aby zacząć zabawę z Titanium, podobnie jak w przypadku PhoneGap, musimy zainstalować [SDK dla Androida](http://developer.android.com/sdk/index.html),
a następnie w menadżerze odpowiednie biblioteki platform dla których chcemy tworzyć aplikację. Titanium wspiera
platformy Android od 1.6 wzwyż.

Instalacja Eclipse i pluginu ADT jest w tym przypadku opcjonalna, ponieważ nie będziemy pracować na klasach Javy,
ani też nie będziemy wykorzystywać tego narzędzia do uruchamiania aplikacji w emulatorze. Także wystarczy nam
dowolny edytor tekstowy z kolorowaniem składni JavaScript :). Do uruchamiania i dystrybuowania aplikacji
będziemy używać narzędzia [Titanium Developer](http://www.appcelerator.com/products/download/). Co ciekawe
aplikacja ta jest napisana z wykorzystaniem frameworka Titanium, więc od razu możemy zobaczyć jakie możliwości
ma ten framework.

Titanium Developer to będzie nasze centrum dowodzenia. Tutaj będziemy tworzyć projekty, uruchamiać w emulatorach,
czy dystrybuować do App Store albo Google Market. Jednakże zanim zabierzemy się do tworzenia projektu musimy
załatać pewnego bug-a, który występuje w wersji 1.2.1 (ponoć bug jest już załatany, ale łatka nie jest jeszcze wypuszczona
więc w nowszych wersjach może nie być takiej potrzeby). Problem ten objawiał się tym, że nowo utworzonych projektów
androidowych nie można było uruchamiać w emulatorze, ponieważ brakowało odpowiedniego przycisku :).

Co zatem należy zrobić? Ściągnąć [ten](http://github.com/appcelerator/titanium_mobile/raw/55fea80fe28a5940b890c2291ec68b7a756a3c27/support/android/android.py)
plik, a następnie podmienić go w naszej instalacji Titanium. W przypadku OpenSUSE musiałem wrzucić go do:

    ~/.titanium/mobilesdk/linux/1.2.0/android

Zauważcie ukryty folder ``.titanium``. [Tutaj](http://developer.appcelerator.com/question/12931/getting-the-error)
znajdziecie opis jak rozwiązać problem w przypadku Mac OSX-a.

Jeżeli jest to nasza pierwsza instalacja Titanium najpierw poprosi nas o stworzenie konta. Konto to w serwisie
Appcelerator'a da nam dostęp do różnych usług (głównie płatnych). Po utworzeniu konta przechodzimy do sekcji edycji
profilu i upewniamy się, że ścieżka do SDK Androida jest ustawiona. Jeżeli aplikacja sama jej nie skonfigurowała
musimy ją wprowadzić.

<a href="/images/titanium/edit-profile.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/titanium/edit-profile.png" alt="Edycja profilu" /></a>

Teraz możemy stworzyć nowy projekt. Przechodzimy do panelu projektów, klikamy "New Project" i wypełniamy formularz:

<a href="/images/titanium/new-project.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/titanium/new-project.png" alt="Nowy projekt" /></a>

Upewniamy się, że nasze SDK Androida zostało wykryte i klikamy "Create Project".

Titanium stworzy nam odpowiednią strukturę projektu. Możemy teraz uruchomić ją w emulatorze i zobaczyć czy
wszystko jest w porządku. Przechodzimy do "Test & Package", wybieramy wersję platformy którą chcemy emulować,
a także rodzaj ekranu i poziom komunikatów (domyślnie jest to "Info").

<a href="/images/titanium/launch.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/titanium/launch.png" alt="Uruchamianie aplikacji" /></a>

Klikamy "Launch" i czekamy aż Titanium uruchomi emulator, zbuduje naszą aplikację i zainstaluje ją.

<a href="/images/titanium/run.png" rel="colorbox" title="Powiększ obrazek"><img src="/images/titanium/run.png" alt="Emulacja" /></a>

Działa! Widzimy także, że w odróżnieniu od PhoneGap nasza aplikacja ma natywny dla Androida wygląd. Na tym etapie zostawię
tę aplikację, może jeszcze przyjdzie czas na bardziej dogłębne zapoznanie się z tym frameworkiem.

## Wady i zalety

Główną zaletą frameworka Titanium jest możliwość dostępu do natywnych kontrolek platformy, przez co aplikacja
posiada natywny dla tej platformy wygląd. Osiągnięto to przez mapowanie wywołań JavaScript'owych na odpowiednie
wywołania API platformy na której aplikacja jest uruchomiona. Kolejną zaletą jest Titanium Developer, czyli swoiste
centrum dowodzenia z poziomu którego tworzymy i zarządzamy aplikacjami.

Ogromną wadą tego frameworka jest brak możliwości debugowania naszej aplikacji inaczej niż poprzez wyświetlanie
logów. Generalnie nasza aplikacja musi być uruchomiona na jakiejś konkretnej platformie przez co nie ma możliwości
stworzenia zautomatyzowanych testów. Możliwe, że istnieje jakaś aplikacja do tego celu wewnątrz konkretnych
platform, ale samo Titanium nie przychodzi nam tu z żadnym konkretnym rozwiązaniem.

## Podsumowanie

Framework Titanium podobnie jak PhoneGap pozwala nam tworzyć wieloplatformowe aplikacje mobilne. Wyróżnikiem tego
frameworka jest możliwość odwoływania się poprzez bibliotekę JavaScript'ową bezpośrednio do natywnych kontrolek,
przez co nasza aplikacja wygląda i działa tak jak natywna aplikacja. Framework ten posiada także dość dobre, choć
płatne, wsparcie ze strony Appcelerator'a, a także narzędzie Titanium Developer, które służy nam do uruchamiania
i dystrybuowania naszych aplikacji.

Minusem jest brak wsparcia ze strony frameworku do testowania i debugowania aplikacji, co może kończyć się sporymi
problemami podczas kodowania. Zastosowanie tego frameworka to, podobnie jak w przypadku PhoneGap, biznesowe aplikacje
typu wypełnij formularz i przeglądaj dane.

[http://michalorman.pl/blog/2010/04/wieloplatformowe-frameworki-mobilne-titanium/](http://michalorman.pl/blog/2010/04/wieloplatformowe-frameworki-mobilne-titanium/)

{% include bio_michal_orman.html %}