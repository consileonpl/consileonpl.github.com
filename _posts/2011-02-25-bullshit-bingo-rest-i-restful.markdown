---
layout: post
title: Bullshit Bingo - REST i RESTful
description: Wpis o tym dlaczego REST i RESTful należy często traktować w kategorii buzzwordu niż czegoś co nasza aplikacja ma wspierać.
keywords: REST RESTful Bullshit Bingo
categories: [rest]
---
Ostatnio nie mam trochę czasu na techniczne wpisy, także tym razem będzie bardziej filozoficzny. Wczoraj zostałem zapytany co myślę
na temat konwencji [REST](http://en.wikipedia.org/wiki/Representational_State_Transfer) co zainspirowało mnie do stworzenia tego wpisu,
ku przestrodze przed bezmyślnym wciskaniem tej architektury do każdej aplikacji. 

REST w moim odczuciu urosło ostatnimi czasy do jednego
z największych buzzwordów w świecie IT. Mało kto tak naprawdę rozumie tę architekturę, ale każda aplikacja, każdy serwis musi być
REST-owy. Tak jakby od tego miało zależeć być albo nie być projektu. Być może w rozmowach biznesowych posiadanie REST-owej architektury
jest na tyle przekonywującym argumentem, że łatwiej pozyskać sponsorów. Nie wiem. Ja jednak proponuję każdemu krytycznym okiem
przyjrzeć się tej architekturze i samemu ocenić, czy w mojej aktualnej aplikacji jest ona w ogóle potrzebna? Czy nie jest tak, że
generuje ona więcej problemów niż pożytku? Oto kilka problemów jakie można napotkać wdrażając architekturę REST-ową.

## Id-ki, Id-ki widzę...

To co od razu rzuca się w oczy w architekturze REST-owej to wszędobylskie "Id-ki" w adresach URL. Pół biedy, jeżeli są to identyfikatory
danych publicznych (np. ofert w sklepie), gorzej jak zaczynają się tam pojawiać identyfikatory zasobów, do których dostęp chcemy ograniczyć.
A już szczytem masochizmu jest wrzucanie identyfikatorów profili użytkowników! Przykładowo edycja profilu użytkownika w naszej aplikacji
może być dostępna pod takim URL-em:

	/users/39/edit

No super! Piękny RESTful-owy URL. Z tym, że w kontrolerze dla takiego adresu i tak musimy zrobić walidację, że identyfikator użytkownika
podanego w adresie URL jest taki sam jak identyfikator zalogowanego użytkownika! Inaczej mogli by oni edytować profile innych użytkowników.
Także w tym przypadku użytkownik o identyfikatorze 39 i tak może wejść tylko na stronę podając parametr 39 w adresie URL, inaczej zostanie
przekierowany na jakąś stronę informującą go, że nie ma dostępu do żądanego zasobu. Jaki zatem jest sens posiadania parametru w adresie
URL, skoro i tak nie możemy go modyfikować? Nic nie zyskujemy, a możemy narazić się na kompromitację aplikacji gdy przez roztargnienie
zapomnimy o walidacji albo ją przez przypadek wyłączymy. Czy nie lepiej byłoby mieć adres:

	/users/edit

Albo jeszcze lepiej:

	/edit_profile

I nie musieć martwić się o identyfikator podany w URL-u?

Sprawy tu mogą się jeszcze bardziej skomplikować. Wyobraźmy sobie, że chcemy użytkownikowi udostępnić stronę edycji zamówienia, które
on złożył. Taka storna mogłaby być dostępna pod adresem:

	/users/39/orders/10

W ten sposób sami sobie utrudniamy życie, bo nie dość, że musimy sprawdzać identyfikator użytkownika, to jeszcze musimy sprawdzić, że
zamówienie o identyfikatorze 10 należy do użytkownika o identyfikatorze 39. W tej sytuacji o wiele lepsze jest wywalenie części dotyczącej
użytkownika (która i tak jest stała):

	/orders/10

Teraz sprawdzamy jedynie czy te zamówienie należy do zalogowanego użytkownika, którego identyfikator przechowujemy gdzieś w sesji
(byle nie jawnie w pliku cookie ;)).

Także piersza zasada poprawnego implementowania REST-u mówi: **wywal z URL-i stałe parametry, a w szczególności te, które dotyczą
użytkowników**.

No i warto zastanowić się nad jeszcze jedną kwestią. Czy te identyfikatory wnoszą cokolwiek użytecznego dla naszej aplikacji? Czy naprawdę
uważamy, że użytkownicy będą przeglądać oferty poprzez modyfikowanie parametru ID w adresie URL? Moim zdaniem bardzo wątpliwe.

## Ładne i brzydkie adresy URL

To co jest charakterystyczne w REST-owej architekturze to jej adresy URL tzw. *pretty URL*. No są one może i przyjazne, oraz nie kłują w oczy
wszędobylskimi znakami ? oraz &. Problem pojawia się wtedy, kiedy nasza witryna dostaje się pod strzechy eskertów od SEO. Pierwsze
co każą Ci zmienić w takiej aplikacji to właśnie adresy URL.

Stara zasada SEO mówi, że w adresie URL **musi** znaleźć się to do czego ta strona prowadzi. Przykładowo załóżmy, że poniższy adres
prowadzi do strony oferty zakupu Mac Booka Pro (nie nie jestem funboyem Apple'a, nie mam ani Mac Booka, ani iPhone'a ani niczego innego
z nadgryzionym jabłkiem w logo ;)):

	/offers/131

Ekspert od SEO powie Ci "Panie, na taki URL to ty się nigdy nie wypromujesz, trzeba go będzie przepisać". No i z twojego pięknego URL-a
robi się:

	/oferty/131/Mac-Book-Pro

Także suma sumarum na końcu i tak będziesz musiał ręcznie te piękne URL-e przepisywać (albo zaimplementować sprytny sposób ich przepisywania
coby nie robić tego ręcznie ;)) i nie będę one już takie piękne.

## Pokaż mi swój identyfikator, a powiem ci jaką masz sprzedaż

Jest jeszcze jedna ciekawa osobliwość posiadania identyfikatorów w adresach URL. Otóż okazuje się, że mogą one udostępniać na zewnątrz
informacje, którymi niekoniecznie chcielibyśmy się dzielić. Jeżeli przykładowo nasza strona pozwala podglądać publiczne profile użytkowników
np. pod adresem:

	/profiles/39

Inkrementując nasz identyfikator do momentu, aż otrzymamy 404 dowiemy się iluż zarejestrowanych użytkowników posiada dany portal (i autentycznie
jest kilka takich portali gdzie to można zrobić, ale nie wymienię ich nazwy ;)).

W ten sposób możemy wyciągać z witryn informacje nie tylko o ilości zarejestrowanych użytkowników, ale i posiadanych ofert itd. Także trzeba być
tego świadomym, że nie tylko to co jest na stronie jest informacją, ale i to co jest w adresie URL. I trzeba się zastanowić czy chcemy tę
informacje upubliczniać. Może się skończyć na tym, że nasze REST-owe identyfikatory i tak będziemy zasłaniać jakimiś losowymi wartościami na podstawie
których będziemy identyfikować zasób i w tym przypadku REST-owość może stać się bardziej uciążliwa niż pomocna.

## Polimorfizm URL-i i metody HTTP

Konwencja REST-owa zbudowana jest na bazie czterech metod protokołu HTTP: GET, POST, PUT oraz DELETE. Już tutaj pojawia się pierwszy problem, gdyż
przeglądarki internetowe z reguły wykorzystuję jedynie GET oraz POST. Stąd wszelkie formularze REST-owe do aktualizacji danych czy linki do ich
usuwania muszą stosować różne sztuczki, aby zasymulować użycie metod PUT lub DELETE w żądaniach GET i POST. Czasami to stwarza problemy, zwłaszcza
początkującym, przy konfiguracji routingów.

Konwencja ta niestety nie wyjaśnia do końca co powinno się dziać, jeżeli jakaś operacja się nie powiedzie. Przykładowo wchodzimy na ekran edycji
złożenia zamówienia:

	GET /orders/new

Konwencja REST mówi nam, iż utworzenie nowego zasobu (w tym wypadku o nazwie ``order``) powinno zostać wykonane za pomocą metody POST ale pod
adres kolekcji zasobów:

	POST /orders

I taki adres będzie ukryty w naszym formularzu (w atrybucie ``action`` elementu ``form``).

Takie działanie może i jest sensowne z punktu widzenia REST-a, ale z punktu widzenia działania witryny i przeglądarki internetowej jest wielce
niepożadana. Dlaczego? Jeżeli nasz formularz jest nieprawidłowy nie chcemy lądować na stronie z listą, chcemy ponownie wyswietlić formularz
wraz z odpowiednimi komunikatami o błędach. Innymi słowy nie chcemy być na ``/orders`` tylko ciągle na ``/orders/new``. Niestety przeglądarka
zmieni nam adres, mimo iż pozostajemy w tym samym miejscu. Jeszcze gorzej jest, jeżeli w ogóle nie udostępniamy strony o adresie ``/orders``
(czy chcemy użytkownikom udostępniać stronę z listą wszystkich zamówień złożonych w systemie?). Jeżeli użytkownik w tym momencie zrobi zakładkę, aby
późiej powrócić i poprawić formularz zamiast formularza przywita go piękne 404, a przecież wcześniej był na tym formularzu i go wypełniał!

O tym problemie [pisałem już kiedyś](http://michalorman.pl/blog/2010/03/zmieniajacy-sie-url-po-bledach-walidacji-w-rails/) na moim blogu.

## Parametrów kilka

Do tej pory skupiałem się na architekturze REST-owej w kontekście witryny internetowej. A co w przypadku serwisów webowych? Wydaje się, że
architektura ta jest wręcz stworzona do takich serwisów. O ile człowiek nie będzie łaził po stronie manipulując identyfikatorami o tyle
aplikacja korzystająca z serwisu nie będzie miała z tym problemu. Jednak w praktyce nie koniecznie wszystko wygląda tak różowo.

W całej swojej karierze deweloperskiej nie spotkałem jeszcze serwisu udostępniającego jakieś poważne usługi (np. płatności), którego żądania
przyjmują tylko 1 parametr albo wcale. Zwykle takie żadania przyjmują kilka parametrów, a mi zdażało się pisać takie co przyjmowały 10-15
parametrów. I to wcale nie jest nic dziwnego! Oprócz samych parametrów żadania często wymagane są jakieś dane identyfikacyjne, jakieś tokeny,
odciśki SSH czy dane statystyczne.

Wszystko to powoduje, że nasze piękne URL-e przestają być już piękne i nie ma w tym nic złego, w końcu te URL-e nie są przeznaczone dla
ludzi. Maszyny, przynajmniej jak na razie, nie mają zmysłów ani gustów i im nie przeszkadzają takie długie adresy. W związku z tym jaki sens
jest upierać się przy REST-owości w takich serwisach?

## A morał jest krótki i niektórym znany...

Ok, czy to oznacza, iż architektura REST jest zła i nie powinno się z niej korzystać? Nie, absolutnie nie! Trzeba tylko umieć rozgraniczyć,
kiedy architektura REST jest naprawdę potrzebna i sensowna, a kiedy jest tylko zwyczajnym buzzwordem. Trzeba być świadomym tego, co taka
architektura ze sobą przynosi i czy w naszej aplikacji będzie ona miała zastosowanie i będzie w ogóle wykorzystywana.

Obecnie wszystkie projekty muszą być REST-owe, musi być JSON i musi być coś z *Enterprise* w nazwie. Ta buzzwordowa karuzela już bardziej
działa na nerwy niż przynosi coś sensownego, ale co zrobić prawa marketingu są nieubłagane i aby mieć inwestorów trzeba wykazać się
innowacyjnością, nawet za cenę funkcjonalności, bezpieczeństwa czy łatwości programowania i utrzymania. Ja osobiście REST i RESTful dokładam
do swojej listy [Bullshit Bingo](http://en.wikipedia.org/wiki/Buzzword_bingo) i Tobie też polecam zastanowienie się nad tym, czy faktycznie
ten REST jest Ci potrzebny w Twojej aplikacji, aby potem na spotkaniu ktoś nie wstał i nie zawołał **Bullshit!**.

[http://michalorman.pl/blog/2011/02/bullshit-bingo-rest-i-restful/](http://michalorman.pl/blog/2011/02/bullshit-bingo-rest-i-restful/)

{% include bio_michal_orman.html %}
