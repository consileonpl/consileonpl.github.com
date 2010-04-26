---
layout: post
title: Model Widok Kontroler (MVC)
categories: [wzorce, mvc]
---
Model-Widok-Kontroler to w tej chwili chyba najczęściej używany wzorzec projektowy. Niemal każda aplikacja, a zwłaszcza aplikacje
webowe, wykorzystują go (często pod przykrywką jakiegoś frameworka). Niestety rozpowszechnienie użycia tego wzorca nie idzie
w parze z jego zrozumieniem. Często widzę jak programistom brakuje elementarnej wiedzy na temat MVC przez co traci się
większość jego zalet. No cóż, znajomość podstawowych wzorców projektowych, a także paradygmatów programowania obiektowego,
wciąż pozostawia wiele do życzenia. Co z tego, że korzystamy z super-zwinnych i enterprajsowych frameworków, jeśli burdel
w kodzie sprawia, że jest on niemożliwy do ponownego użycia, nie można go rozwijać, a wprowadzanie zmian to droga przez mękę. Mam nadzieję,
że wpisami na swoim blogu na temat wzorców projektowych chociaż trochę przyczynię się do poprawy tej sytuacji (nie wiem
czy bardziej to robię dla siebie czy innych ;).

## Klasyczne MVC

Założenia wzorca Model-Widok-Kontroler są generalnie bardzo proste (tym bardziej dziwi ich nieumiejętne stosowanie w
projektach). Zacznijmy od analizy trzech tytułowych składowych:

1. **Model** - reprezentuje naszą logikę biznesową. Tutaj znajdują się wszelkie obiekty, które służą do wykonywania wszelkich
operacji związanych z implementacją funkcjonalności naszej aplikacji.
2. **Widok** - warstwa prezentacji. Widok odpowiedzialny jest za prezentację użytkownikowi wyników działania logiki biznesowej (Modelu).
3. **Kontroler** - obsługuje żądania użytkownika. Wszelkie żądania deleguje do odpowiednich metod Modelu.

Ogólny schemat klasycznego wzorca MVC wygląda tak:

<a href="/images/classic_mvc.png" title="Klasyczny MVC" rel="colorbox"><img src="/images/classic_mvc.png" alt="Schemat klasycznego MVC" /></a>

To co należy sobie zakodować, wyryć na ścianie, w kamieniu, wytatuować, czyli ogólnie zapamiętać to to, że: **Model == Logika Biznesowa**.
Niezrozumienie tego to bardzo częsty błąd jaki zauważałem w projektach, a wynika on z dwóch czynników - niezbyt trafnej nazwy,
oraz encji wymyślonych dla celów platformy Java EE. Nazwa "Model" niestety niezbyt dokładnie sugeruje, że to nie są tylko
klasy mapujące tabele w bazie danych. To są także **obiekty wykonujące wszelką logikę biznesową** związaną z funkcjonalnościami
naszej aplikacji. Normalnie klasy mapujące tabele w bazie i wykonujące logikę to powinny być te same klasy, niestety w
J2EE wymyślono jakieś DAO i anemiczne encje, które służą tylko jako worki na kartofle, ups... dane, a nie posiadają
żadnych odpowiedzialności i logiki, stąd też często programiści J2EE mają problemy ze zrozumieniem literki M skrótu MVC.

Reasumując Model to jest cała logika biznesowa aplikacji wraz z mapowaniem obiektowo-relacyjnym. To jest też stała część
naszej aplikacji, w tym sensie, że powinniśmy móc dowolnie wymieniać pozostałe części (Widok i Kontrolery), a aplikacja
nadal powinna robić to samo (oczywiście nie uwzględniając wszelkich wymagań systemu co do warstwy prezentacji).
Swoistym efektem ubocznym jest także to, że pewną logikę możemy wykonywać w różnych kontrolerach
bez powielania kodu (tutaj ucieszą się wszyscy zwolennicy DRY, czyli de facto wszyscy profesjonalni programiści).

Widok służy jedynie prezentacji danych dla użytkownika końcowego. W klasycznym podejściu MVC to model informuje komponenty
Widoku o zmianach w Modelu i potrzebie aktualizacji Widoku. Komponenty Widoku mogą natomiast wykorzystywać komponenty Modelu do pobierania danych
potrzebnych do wygenerowania Widoku. Niedopuszczalnym błędem jest modyfikowanie Modelu z poziomu Widoku. Model jest dla
Widoku dostępny tylko w trybie read-only i wywoływanie metod modyfikujących stan komponentów Modelu to poważny błąd, ponieważ
ściśle wiąże warstwę Widoku z Modelem. Należy na to szczególnie uważać, gdyż pełen interfejs, także ten zmieniający stan Modelu,
jest dostępny dla komponentów Widoku. Oczywiście możemy się przed tym bronić chowając nasz Model za odpowiednim interfejsem read-only, ale jest
to dość paranoiczne podejście, wystarczy, że wszyscy programiści będą świadomi, że tego nie wolno robić i będą się do tego
zakazu stosować.

Kontroler natomiast ma za zadanie przekierowywać wszelkie żądania użytkownika na odpowiednie wywołania Modelu. Można powiedzieć,
że Kontroler pełni rolę swoistego routera. Podobnie jak w przypadku Widoku najczęstszym błędem (i to jest generalnie
najczęściej spotykany błąd w aplikacjach opartych o MVC) jest wykonywanie logiki biznesowej zmieniającej stan Modelu
wewnątrz Kontrolera. Jest to bardzo poważny błąd, którego skutkiem jest ścisłe powiązanie Kontrolera z Modelem. Dodatkowo
nie można tej logiki wykorzystać wewnątrz innego kontrolera, a programiści nie rozumiejąc swojego błędu kopiują kod,
tworzą jakieś bazowe kontrolery albo helpery. Problem tak naprawdę tkwi w złym przypisaniu odpowiedzialności.

W tym momencie można zadać sobie pytanie, skoro Kontroler tylko przekazuje żądania (mapuje na odpowiednie wywołania metod
Modelu) to po co w ogóle je tworzyć? Przecież można bezpośrednio odwołać się do Modelu z pominięciem delegacji. To prawda, jednakże
Kontroler definiuje nam pewną warstwę abstrakcji pomiędzy protokołem obsługi żądań użytkownika a wywołaniem metod
Modelu. Z punktu widzenia Modelu nie musimy się martwić czy dane żądania przychodzą jako żądania HTTP, czy jako zdarzenia
wygenerowane z GUI.

Tak wygląda klasyczne podejście do wzorca Model-Widok-Kontroler. Takie podejście nadaje się do pisania aplikacji typu
stand-alone z jakimś GUI, jednakże nie do końca nadaje się do tworzenia aplikacji webowych opartych o protokół HTTP.
Problematyczne jest tutaj ograniczenie mówiące o tym, że to Model informuje Widok o zmianach co wymusza potrzebę
rejestracji jakiś komponentów nasłuchujących. Problem w tym, że w przypadku sieci i protokołu HTTP Widokiem są dokumenty
HTML i potrzeba by naprawdę dziwolągów w kodzie, aby dokument HTML odbierał komunikaty z klasy o zmianach w
Modelu. Rozwiązaniem tego jest tzw. **Model 2** czyli nieco zmodyfikowana wersja MVC (teraz pytanie, ilu programistów piszących aplikacje
z wykorzystaniem tego wzorca wie, że tak naprawdę korzysta z jego zmodyfikowanej wersji?).

## Model 2

Model 2 został wymyślony na potrzeby technologii Java Servlet oraz JSP, jednakże obecnie jest wykorzystywany przez wiele
innych frameworków. Posiada generalnie te same warstwy: Model, Widok i Kontroler jednak zmodyfikowane zostały nieco
ścieżki komunikatów:

<a href="/images/model2_mvc.png" title="Klasyczny MVC" rel="colorbox"><img src="/images/model2_mvc.png" alt="Schemat klasycznego MVC" /></a>

Różnica w tym podejściu jest taka, że Model nie komunikuje się w żaden sposób z Widokiem, natomiast Widok w trybie read-only
pobiera dane z Modelu. Kontroler natomiast zajmuje się delegacją żądań (np. HTTP) na wywołania metod modelu, oraz przygotowaniem
danych dla widoku i żądaniem jego wygenerowania (dalej przekazania go do przeglądarki). W tym przypadku nie musimy w żaden
sposób rejestrować Widoku w Modelu a to Kontroler decyduje, na podstawie żądania i odpowiedzi z modelu, jaki widok wyrenderować
(a następnie inicjuje tę akcję). Widok natomiast korzysta z komponentów przygotowanych przez Kontroler, a pobranych
z Modelu i umieszczonych w jakimś kontekście (np. w kontekście żądania w JSP/JSF albo jako zmienną egzemplarza Kontrolera
w przypadku ERb i Rails). Ważne jest tutaj, że Kontroler otrzymuje informacje zwrotne z Modelu, które dalej wykorzystuje
do wyrenderowania Widoku, zatem jego rola jest nieco rozszerzona w odróżnieniu od klasycznego podejścia.

Model 2 lepiej nadaje się do aplikacji webowych, gdzie role widoku pełnią takie technologie jak JSP, JSF czy ERb. Model
w tym podejściu jest dużo luźniej powiązany z Kontrolerami oraz Widokiem. Nie jest w ogóle świadomy istnienia tych warstw
(w poprzednim podejściu musiał wiedzieć co najmniej o warstwie Widoku). Oczywiście o ile nie implementujemy logiki biznesowej
w Widoku albo Kontrolerze.

## Zalety MVC

Najważniejszą zaletą wzorca MVC jest hermetyzacja Modelu. Logika biznesowa jest odizolowana od wszelkich technologii
Widoku czy protokołów obsługi żądań wysyłanych przez użytkowników. Z punktu widzenia Modelu (zwłaszcza we wzorcu Model 2)
nie ma znaczenia, czy aplikacja jest typu stand-alone, gdzie żądania od użytkownika są łapane jako zdarzenia GUI, czy jest
to aplikacja webowa, gdzie w grę wchodzi protokół HTTP. Dzięki MVC nasz Model pozostaje jeden, a resztę możemy sobie
wymieniać w zależności od środowiska uruchomieniowego. Możemy nawet bawić się w takie rozwiązania, gdzie Widok albo
Kontrolery są pisane w innej technologii i języku niż sam model (oczywiście o ile taka architektura będzie miała sens dla
naszej aplikacji).

## Podsumowanie

Świat byłby piękny, gdyby programiści oprócz wykorzystywanych technologii znali także metody i wzorce jakimi się - nawet
nieświadomie - posługują. Dobra znajomość wzorca MVC, który jest wykorzystywany niemal w każdym frameworku do tworzenia
aplikacji webowych, pozwala na pełną hermetyzację Modelu i dowolne osadzanie go w różnych środowiskach uruchomieniowych.
Jeżeli programiści będą dobrze rozumieć podstawy tego wzorca i będą w stanie zachować odpowiednią separację warstw w taki
sposób, że stan Modelu nie jest modyfikowany ani w Widoku ani w Kontrolerze, mammy dużą szansę, że zjawisko potocznie zwane
"śmietnikiem w kodzie" nas ominie. Będzie to dobre dla zdrowia psychicznego wielu programistów, którzy później taki
śmietnik muszą doprowadzać do ładu.

Nazwa Model stojąca za literką M skrótu MVC jest nieco niefortunna. Wielu programistom sugeruje ona, że są to obiekty
służące do mapowania bazy danych. Dokładając do tego anemię encji J2EE programiści tej platformy nagminnie umieszczają
logikę biznesową w obiektach warstwy Widoku albo Kontrolera. Jest to poważny problem, gdyż nazbyt wiąże nasz Model
z innymi warstwami. Moim zdaniem trafniejszym określeniem byłaby tutaj Domena (co mogłoby sugerować Domenę biznesową
aplikacji). W takim przypadku wzorzec powinien nazywać się Domena-Widok-Kontroler DVC (od Domain-View-Controller).

[http://michalorman.pl/blog/2010/03/model-widok-kontroler/](http://michalorman.pl/blog/2010/03/model-widok-kontroler/)

{% include bio_michal_orman.html %}