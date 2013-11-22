---
layout: post
title: Agile w Biznesie - w kierunku nowego spojrzenia na zarządzanie projektami IT
categories: [agile]
---
Umiejętność przygotowania dobrych testów i ich zautomatyzowania, konieczność ciągłej
integracji i cyklicznego wdrażania poszczególnych etapów projektu, stała współpraca z
klientem oraz efektywne zarządzanie pracą zespołu z naciskiem na rozwijanie talentów
jego poszczególnych członków – to kluczowe czynniki wpływające na skuteczne prowadzenie
projektów IT. Takie podejście charakteryzuje ideę Agile, która coraz dynamiczniej
rozwija się na polskim rynku.

Stwierdzenie, że tradycyjne podejście do zarządzania projektami IT powoli odchodzi
w niepamięć, byłoby z pewnością nadużyciem - w Polsce wciąż jeszcze dominuje ten
model tworzenia oprogramowania. Jednak bez wątpienia można uznać, że zwinne metodyki
prowadzenia projektów IT zyskują na rodzimym gruncie coraz większą popularność.
Świadczą o tym choćby statystki, według których aż 75% polskich menedżerów IT
miało lub ma własne doświadczenia w praktycznym wykorzystaniu Agile.

Za dobrą kartę należy uznać również fakt, że zmienia się charakter prezentowania
tematyki Agile – na branżowych spotkaniach już nie mówi się tylko o tym, czym jest
i do czego służy Agile, ale omawia się rezultaty i dobre praktyki wdrażania zwinnych
metodyk prowadzenia projektów. Taka problematyka prezentowana była podczas tegorocznej
konferencji [„Agile w biznesie”][1] zorganizowanej już po raz trzeci przez Computerworld.
Poniżej kilka refleksji z tego spotkania.

### Wydawaj i wdrażaj tak szybko, jak produkujesz

W podejściu Agile, gdzie wszystkie fazy tworzenia projektu – tj. analiza, projektowanie,
implementacja i testowanie – realizowane są co Sprint, konieczne jest posiadanie
bardzo efektywnego procesu testowania, budowania, wydawania i wdrażania kolejnych
wersji oprogramowania. Tylko tak można nadążyć za zespołem dostarczającym co Sprint
nowe wydania i nie zmarnować tempa i rytmu, jakim poddany jest proces wytwórczy.

### Testy automatyczne są koniecznością

Niezbędna przy zastosowaniu Agile efektywność procesu testowania wymaga zmiany
proporcji nakładów pracy w stosunku do jego poszczególnych faz. W skrócie oznacza to,
że  tworzona jest znacznie większa ilość testów jednostkowych, zbliżona do modelu
tradycyjnego ilość testów integracyjnych oraz zdecydowanie mniejsza ilość testów
akceptacyjnych UAT. W konsekwencji zdecydowanie większy nacisk kładzie się na
automatyzację testów niż ich realizację przez ludzi, co jest nieuniknione przy dużej
ilości wydań i stałej powtarzalności procesu. Z tego też powodu umiejętność przygotowania
dobrych testów i ich zautomatyzowania będzie coraz bardziej kluczowa dla
efektywnego prowadzenia projektów wytwórczych.

### Musisz mieć Continuous Integration & Continuous Deployment

Bez Agile proces budowy, testowania  i wdrażania realizowany był w niektórych firmach
np. tylko kilka razy w roku. Stosowanie zwinnych metodyk sprawia, że wydania
lądują na środowisku produkcyjnym nawet co tydzień, dlatego całość tego procesu
musi być bezbłędna, powtarzalna i szybka, a więc oczywiście zautomatyzowana.
Absolutną koniecznością staje się zatem dobrze zbudowane środowisko CI & CD.
Ciągła integracja i ciągłe wdrażanie umożliwiają wczesne wykrywanie i reagowanie
na błędy oraz zwiększenie tempa pracy. Z naszych doświadczeń i obserwacji wynika,
że w 2014 roku ta zmiana może być jednym z kluczowych wyzwań dla licznych działów IT.

### Przestań bać się UAT

Zastosowanie Agile wymaga stałego zaangażowania użytkowników końcowych w całość
procesu wytwarzania oprogramowania. Każdy Sprint rozpoczyna się
planowaniem, a kończy przedstawianiem klientowi, oraz reprezentantom użytkowników
końcowych inkrementu produktu wytworzonego
w ramach sprint-u w celu zebrania ich uwag. Wobec tego testy UAT, które w modelu
tradycyjnym
są często kluczowym etapem decydującym o losie projektu i jednocześnie ciężką próbą
dla relacji klienta z dostawcą, przy stosowaniu Agile sprowadzają się niemal do
formalności. Zmiany wprowadzane na bieżąco z udziałem użytkownika końcowego pozwalają
bowiem unikać sytuacji, w których efektem testu UAT jest brak akceptacji klienta
na wdrożenie z powodu niespełniania jego prawdziwych i zmiennych oczekiwań.

### Praca zespołowa i stały kontakt z klientem

Wykorzystywanie Agile w prowadzeniu projektów IT pokazuje prawdę o tym, czym
w istocie jest tworzenie oprogramowania i pozwala zrozumieć, jak pracować
zespołowo w sposób zgodny z ludzką naturą. Świadczą o tym zmiany, jakie zachodzą
w mentalności menedżerów IT licznie przybyłych w tym roku na konferencję
„Agile w biznesie”. Większość z nich zauważa już, że zespół projektowy to
nie tylko X zasobów o wyspecyfikowanych rolach, ale grupa bardzo konkretnych
ludzi, których wszelkie talenty można i warto wykorzystać. Ponadto wielu
menedżerów zdało sobie sprawę, że warto przestać udawać  idealnych reprezentantów
użytkowników końcowych, na tyle doświadczonych, by już na początku całość
rozwiązania zaprojektować, zaplanować i z inżynierską precyzją zrealizować
z sukcesem bez udziału klienta.

Za podsumowanie i ocenę [AWB 2013][1] niech służy zapewnienie, że w roku 2014 też tam będę
– zawsze dotychczas było warto!

{% include bio_marcin_kaczmarek.html %}

[1]: http://www.computerworld.pl/konferencja/Agile2013
