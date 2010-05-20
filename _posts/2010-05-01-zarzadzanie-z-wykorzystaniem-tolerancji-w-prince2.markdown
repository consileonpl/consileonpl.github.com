---
layout: post
title: Zarządzanie z wykorzystaniem tolerancji w PRINCE2
description: Jedną z głównych zasad metodyki PRINCE2 jest zarządzanie z wykorzystaniem tolerancji. Przyjrzyjmy się bliżej co też ta zasada oznacza w kontekście zarządzania projektem.
categories: [prince2]
---
Jedną z głównych zasad metodyki PRINCE2 (tzw. pryncypium) jest zarządzanie projektem z wykorzystaniem tolerancji.
Przyjrzyjmy się dlaczego owa zasada została wprowadzona, co ona oznacza i jakie konsekwencje niesie ze sobą dla
projektu.

## Zarządzanie z wykorzystaniem tolerancji

Cytując oficjalną definicję [OGC](http://www.ogc.gov.uk/index.asp):

> Projekt zgodny z PRINCE2 posiada tolerancje określone dla każdego z celów projektu, służące do
> ustanowienia granic dla delegowanych uprawnień.

Tolerancje służą nam do określenia pewnych akceptowalnych granic, w ramach których mogą odbiegać docelowe wskaźniki projektu
tj. koszt, czas, zakres, jakość, ryzyko i korzyść. Granice te pozwalają osobom, odpowiedzialnym za realizację poszczególnych
zadań, na pewną swobodę wykonywania swojej pracy bez potrzeby ubiegania się o akceptację do swoich zwierzchników. Innymi słowy
dopóki docelowe wskaźniki projektu mieszczą się w zakładanych tolerancjach, dopóty nie trzeba zwracać się z prośbą o decyzję
do wyższego szczebla zarządzania.

Zarządzanie z wykorzystaniem tolerancji ma na celu odciążenie osób zajmujących pozycje na wyższych szczeblach organizacji
projektu. Chodzi po prostu o nie zawracanie głowy osobom, które i tak mają sporo pracy. PRINCE2 zakłada, że jeżeli zmiana
nie powoduje przekroczenia granic tolerancji dla żadnego z wskaźników projektu, to osoba zarządzająca zmianą jest uprawniona
do jej wprowadzenia, bez prośby o jej akceptację. W przypadku, gdy zmiana powoduje przekroczenie tolerancji dla dowolnego
wskaźnika należy zwrócić się z prośbą o akceptację wprowadzenia zmiany do osób z wyższego szczebla zarządzania.

PRINCE2 nie narzuca poziomu tolerancji jaki należy przyjąć w projekcie. Tolerancje powinny zostać ustalone podczas
przygotowywania planu (z dowolnego poziomu). Powinny być one tak dobrane, aby nie generować zbyt dużej ilości zapytań o
pozwolenie wprowadzenia zmiany, a jednocześnie by nie dawać zbyt dużej swobody osobom z niższych poziomów organizacji zarządzania
projektem. Jak zawsze, wszystko zależy od konkretnych wymagań i skali projektu.

Aby lepiej wyjaśnić jak to wygląda przyjrzyjmy się teoretycznemu scenariuszowi projektowemu.

## Przykładowy scenariusz zarządzania z wykorzystaniem tolerancji

Wyobraźmy sobie taką oto sytuację. Kierownictwo organizacji zleca nam przygotowanie projektu. Dla konkretnego projektu
narzucono nam następujące wskaźniki (ograniczenia) wykonania wraz z tolerancjami:

<table>
  <tr>
    <th>Wskaźnik</th>
    <th>Wartość</th>
    <th>Tolerancja</th>
  </tr>
  <tr>
    <td>Budżet projektu:</td>
    <td>2 000 000 PLN</td>
    <td>+/- 250 000 PLN</td>
  </tr>
  <tr>
    <td>Budżet zmian:</td>
    <td>500 000 PLN</td>
    <td>+/- 50 000 PLN</td>
  </tr>
  <tr>
    <td>Budżet ryzyka:</td>
    <td>100 000 PLN</td>
    <td>+/- 20 000 PLN</td>
  </tr>
  <tr>
    <td>Czas realizacji projektu:</td>
    <td>18 miesięcy</td>
    <td>+/- 4 tygodnie</td>
  </tr>
</table>

<div class="hola_dog">
<p>Hola, Hola! Jaki jest sens ustalania ujemnej granicy tolerancji dla kosztów i czasu? Czyż nie jest dobrze, gdy
projekt szacowany na 2 miliony zrobimy za pół, albo zamiast w 18 miesięcy zrobimy go w 6?</p>
</div>

Pytanie to jest zasadne, jednakże ustalanie dolnych granic tolerancji dla kosztów i czasu ma swój sens. Wyobraźmy sobie
sytuację, że realizacja projektu wymaga skonfigurowania potężnego data center, gdzie pracować będzie kilkanaście maszyn.
Jeżeli takie data center stworzymy na pół roku przed faktycznym wdrożeniem systemu, będziemy musieli przez pół roku
niepotrzebnie ponosić koszty jego utrzymania. Innym powodem ustalania dolnych granic jest możliwość późniejszej weryfikacji
faktycznego wykonania projektu. W przypadku gdy koszt projektu wyniósł mniej niż dolna granica tolerancji dla budżetu projektu,
będziemy wiedzieć, że na kolejny podobny projekt możemy przeznaczyć mniejsze środki. Tak więc ustalenie dolnych granic
dla czasu i kosztów nie wymaga wielkiego wysiłku, a może być źródłem cennych informacji na przyszłość.

### Planowanie projektu i etapu

Zlecenie projektu od kierownictwa organizacji przyjmuje Komitet Sterujący. Określone wskaźniki, oraz ich tolerancje są
umieszczane w Planie Projektu (ponieważ dotyczą całego projektu). Projekt realizowany jest w etapach. Dla każdego etapu
tworzy się Plan Etapu a w nim umieszcza informacje na temat wymaganego poziomu docelowych wskaźników a także tolerancji.
W naszym przykładzie Plan Etapu może zakładać następujące wartości wskaźników:

<table>
  <tr>
    <th>Wskaźnik</th>
    <th>Wartość</th>
    <th>Tolerancja</th>
  </tr>
  <tr>
    <td>Budżet etapu:</td>
    <td>200 000 PLN</td>
    <td>+/- 25 000 PLN</td>
  </tr>
  <tr>
    <td>Budżet zmian:</td>
    <td>50 000 PLN</td>
    <td>+/- 5 000 PLN</td>
  </tr>
  <tr>
    <td>Budżet ryzyka:</td>
    <td>10 000 PLN</td>
    <td>+/- 2 000 PLN</td>
  </tr>
  <tr>
    <td>Czas realizacji etapu:</td>
    <td>3 miesiące</td>
    <td>+/- 1 tydzień</td>
  </tr>
</table>

Taki Plan Etapu jest wykorzystywany przez Kierownika Projektu do zlecania Grup Zadań Kierownikom Zespołów.
Kierownicy Zespołów mają prawo utworzenia własnego Planu Zespołu, jednakże plan ten powinien mieścić się w założonych
tolerancjach etapu.

### Planowanie realizacji zadań

Grupa Zadań to lista rzeczy jakie należy zrealizować w ramach danego etapu. Takich grup może być wiele i każda może
zostać przydzielona przez Kierownika Projektu innemu zespołowi. Zadania te powinny być podzielone pod względem priorytetów.
Można do tego celu wykorzystać metodę [MoSCoW](http://en.wikipedia.org/wiki/MoSCoW_Method).

Zadania dzielimy na cztery następujące grupy:

* Zadania, które muszą być zrealizowane (**M**ust be),
* zadania, które powinny być zrealizowane (**S**hould be),
* zadania, które mogą zostać zrealizowane (**C**ould be), oraz
* zadania, które nie będą realizowane (**W**on't be).

Wraz z takim podziałem zadań Kierownik Projektu może nałożyć pewne tolerancje:

* Z grupy **M** należy wykonać 100% zadań,
* z grupy **S** należy wykonać nie mniej niż 75% zadań, natomiast
* z grupy **C** należy wykonać nie mniej niż 10% zadań.

Taki podział pozwala Kierownikowi Zespołu na pewną swobodę w doborze zadań do zrealizowania w danym etapie, bez potrzeby
proszenia o akceptację Kierownika Projektu. Oczywiście w innych projektach podział zadań może być zorganizowany w inny
sposób.

### Tolerancje w praktyce

Przyjrzyjmy się teraz przykładowym sytuacjom jakie mogą mieć miejsce w projekcie.

Kierownik Zespołu po sesji [pokera planistycznego](http://en.wikipedia.org/wiki/Planning_poker) ze swoim zespołem
stwierdził, iż nie da się wykonać 100% zadań z grupy **M** w założonym terminie. Ponieważ problem ten powoduje przekroczenie
tolerancji musi to zgłosić Kierownikowi Projektu w formie zagadnienia. Zagadnienie w PRINCE2 to pewna forma formalnej obsługi
zdarzeń pojawiających się w projekcie.

Kierownik Projektu analizuje wpływ zgłoszonego zagadnienia na realizację etapu. Może być tak, że wykonanie wszystkich
zadań z grupy **M** wymagane jest ze względu na zapewnienie odpowiedniego poziomu jakości produktu. W takiej sytuacji Kierownik
Projektu powinien sporządzić Raport Nadzwyczajny i przedłożyć go Komitetowi Sterującemu, ponieważ zmiana Grupy Zadań
powoduje przekroczenie tolerancji dla wskaźnika jakość. Gdyby jednak Kierownik Projektu stwierdził, że dane zadanie można
przenieść do grupy **S** bez przekraczania tolerancji dla jakiegokolwiek wskaźnika, mógłby zaktualizować Plan Etapu i Grupę
Zadań bez proszenia o akceptację Komitetu Sterującego.

W przypadku, kiedy Kierownik Projektu sporządził Raport Nadzwyczajny i przedłożył go Komitetu Sterującemu celem podjęcia
działań naprawczych, możemy mieć do czynienia z kilkoma scenariuszami. Komitet Sterujący może zadecydować o zwiększeniu
czasu realizacji etapu. Jednakże istnieje zagrożenie, że czas ten wykroczy poza czas przeznaczony na realizację projektu
(jeżeli realizowany etap jest już którymś z kolei etapem). Decyzja powodująca przedłużenie czasu trwania projektu jest już
decyzją wykraczającą poza uprawnienia Komitetu Sterującego. W takiej sytuacji Komitet Sterujący powinien zwrócić się do
zarządu organizacji o podjęcie decyzji. Organizacja może zezwolić na przedłużenie czasu trwania projektu lub nie (natomiast
samo przedłużenie pewnie pociągnie za sobą potrzebę przeznaczenia większych środków finansowych na projekt). W sytuacji
kiedy decyzja o przedłużeniu trwania etapu mieści się w granicach tolerancji czasu trwania projektu, Komitet Sterujący
jest uprawniony do podjęcia takiej decyzji bez proszenia o zgodę kierownictwa organizacji.

Innym wyjściem mogłaby być zmiana wymagań jakościowych etapu. Tutaj również należałoby sprawdzić czy taka zmiana mieści
się w granicach tolerancji dla całego projektu.

Jaką decyzję by nie podjęto Komitet Sterujący zleca Kierownikowi Projektu opracowanie Planu Nadzwyczajnego. Plan ten
ma na celu zastąpienie aktualnego Planu Etapu albo Planu Projektu (w zależności od tego, czy zmieniono tolerancje
tylko dla etapu czy całego projektu). Plan Nadzwyczajny jest tworzony tak samo jak plan który ma zastąpić (praktycznie aktualizuje
się zastępowany plan) i obowiązuje od momentu wprowadzenia do końca trwania planu zastępowanego.

## Schemat delegowania tolerancji

Schemat delegowania tolerancji oraz raportowania sytuacji nadzwyczajnych przedstawia następujący rysunek:

<a href="/images/prince2_tolerance.png" title="Schemat delegowania tolerancji" rel="colorbox"><img src="/images/prince2_tolerance.png" alt="Schemat delegowania tolerancji" /></a>

Kierownictwo organizacji znajduje się poza zespołem projektowym i ustala całościowe wymagania dotyczące projektu.
Komitet Sterujący ustala wymagania dla etapu i informuje o sytuacjach nadzwyczajnych kierownictwo organizacji.
Kierownik Projektu ustala tolerancje dla Grupy Zadań i tworzy Raporty oraz Plany Nadzwyczajne dla potrzeb Komitetu
Sterującego. Kierownik Zespołu nie ustala tolerancji, jedynie zgłasza zagadnienia do Kierownika Projektu.
Za każdym razem kiedy wystąpi zagrożenie przekroczenia granic tolerancji należy odwołać się do wyższych szczebli
zarządzania celem podjęcia działań naprawczych.

## Podsumowanie

PRINCE2 nakazuje realizację projektu z wykorzystaniem tolerancji. Zdefiniowanie wartości tolerancji dla docelowych wskaźników
projektu ma na celu nadanie pewnych uprawnień dla członków projektu z niższego szczebla, tak aby mogli oni wykonywać
swoją pracę bez ciągłego zapytywania członków wyższego szczebla o zgodę na wprowadzania zmian. Tolerancje mają na celu
dać w pewnym zakresie wolną rękę Komitetowi Sterującemu, Kierownikowi Projektu czy Kierownikom Zespołów.

Podejście to jest dość praktyczne i sensowne. Z jednej strony nie ma potrzeby ciągłego, formalnego załatwiania zmian
i pytania o zgodę na ich wprowadzenie, z drugiej strony zapobiega to całkowitej samowolce w projekcie. Sytuacja w której
Kierownik Zespołu decyduje o czasie trwania projektu, czy jego budżecie jest niedopuszczalna. Podejście do zarządzania
z tolerancjami daje nam jednocześnie możliwość kontroli oraz swobodę działań. Wszystko to w celu zapewnienia odpowiedniej
decyzyjności w projekcie, oraz ochronie interesów kierownictwa organizacji i klienta.

Wbrew pozorom procedura obsługi zmian w ramach założonych tolerancji (i w momencie gdy są one przekroczone) jest bardzo
prosta i intuicyjna. PRINCE2 nie wymyśla tutaj niczego nowego a jedynie formalizuje ten proces. Przecież tak to wszystko
wygląda w naszych projektach, tylko inaczej się nazywa i być może jest mniej szczebli zespołów zarządzających.


[http://michalorman.pl/blog/2010/05/zarzadzanie-z-wykorzystaniem-tolerancji-w-prince2/](http://michalorman.pl/blog/2010/05/zarzadzanie-z-wykorzystaniem-tolerancji-w-prince2/)

{% include bio_michal_orman.html %}
