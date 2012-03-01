---
layout: post
title: CQRS/DDD/ES w pigułce  
categories: [cqrs, ddd]
---

O czym traktuje wpis:

 - **CQRS** - Command Query Responsibility Segregation
 - **DDD** - Domain Driven Design
 - **ES** - Event Sourcing

## Koncepcja CQRS

Podział systemu na dwa obszary:
1. przetwarzanie transakcji
2. obsługa zapytań (widoki)

[Koncepcja CQRS](http://www.infoq.com/resource/articles/cqrs_with_axon_framework/en/resources/cqrs.png)

Architektura systemu, która wyłania się w wyniku zastosowania takiej separacji, jest zasadniczo różna względem typowych architektur bazujących na jednym modelu danych i jednej warstwie serwisowej obsługujących zarówno zapisy jak i odczyty. Dzięki separacji można niezależnie optymalizować obydwa obszary systemu.

Event Sourcing i DDD to rozwiązania, które umożliwiają implementację koncepcji CQRS.

## DDD

Metodyka DDD dostarcza wytyczne w jaki sposób modelować logikę biznesową. Podstawowe koncepje DDD:
 - **Ubiquitous Language** - modele powstają (wyłaniają się) w wyniku dogłębnej analizy domeny i są opisywane językiem zrozumiałym dla developerów jak i ekspertów domenowych (których udział w procesie analizy domeny jest niezwykle pożądany)
 - **Bounded Contexts** - zwykle w ramach jednego systemu występuje wiele domen, które należy opisywać odrębnymi modelami
 - **Aggregates** - agregaty są głównymi elementami modelu, grupują powiązane ze sobą obiekty, których modyfikacja możliwa jest tylko za pośrednictwem obiektu głównego (**Aggregate Root**) (AR), co zapewnia kontrolę nad spójnościa agregatu

## Event Sourcing

Event Sourcing to koncepcja, w której stan obiektu reprezentowany jest jako suma zdarzeń (``Events``) jakie zostały wygenerowane przez ten obiekt. Każda modyfikacja stanu obektu skutkuje wygenerowaniem przez obiekt zdarzenia reprezentującego tę modyfikację. Dla przykładu, obiekt ``Invoice`` może być reprezentowany jako suma zdarzeń ``InvoiceCreated``, ``InvoiceItemAdded``, ``InvoiceSent``. To AR wie co zostało zmienione i jest to jawnie reprezentowane przez ``Event``.

## Optymalizacja przetwarzania transakcji

System akceptuje wywołania operacji biznesowych w formie komend. Przetwarzanie komendy polega na wywołaniu pojedynczej metody w Aggregate Root. Metoda nie zwraca żadnego wyniku, a brak wyjątku oznacza pomyśle zakończenie operacji. Komenda nie musi być przetworzona natychmiast (może zostać zakolejkowana).

### Aggregate Root wyznacza granice spójności

Aggregate Root gwarantuje integralność (spójność) danych które obejmuje. Możliwa jest dowolna optymalizacja wewnętrznej struktury agregatu dla celów przetwarzania transakcji bez konieczności uwzględniania warstwy prezentacji 

### Aggregate Root wyznacza granice transakcji

Transakcja nie może obejmować kilka AR, a więc AR nie może posiadać referencji do innego AR (może posiadać jedynie jego Id) Dzięki temu możliwe jest partycjonowanie AR.

### Append-only storage

Zmiany stanu Aggregate Root sygnalizowane są zdarzeniami (``Event``), które na koniec transakcji serializowane są do bazy (**Event Store**). Rozwiązanie to zapewnia ogromną wydajność przetwarzania transakcji dzięki temu, że nie jest konieczne tworzenie locków na bazie danych oraz wykonywanie skomplikowanych zapytań sql. Event Store może wykorzystywać dowolny mechanizm utrwalania (baza sql, nosql, pliki) i jest łatwy w utrzymaniu (backup'y, replikacja). Oczywistą konsekwencją jest brak możliwości wykonywania zapytań sql, stąd Aggregate Root może być ładowany tylko na podstawie Id. 

### Asynchroniczne przetwarzanie zdarzeń

Zdarzenia są asynchronicznie propagowane do zarejestrowanych słuchaczy (``Event Handler``), a zatem przetwarzanie ich nie wydłuża czasu trwania transakcji. W ten sposób aktualizowana jest druga strona systemu (widoki). Konsekwencją jest opóźnienie pomiędzy zatwierdzeniem transakcji a aktualizacją widoku. To samo opóźnienie może dotyczyć aktualizacji stanu innych ARs, które są wywoływane przez ``Event Handler``'a (wysłanie komendy) w wyniku zaistnienia określonego zdarzenia. Spójność pomiędzy ARs (rozumiana jako spójność transakcyjna) nie jest zatem zachowana. Gwarantowana jest natomiast ostateczna spójność (**Eventual Consistency**) - każdy AR w końcu zostanie zaktualizowany. 

### Możliwość zatwierdzania równoległych zmian

Można odrzucać równoległe zmiany w aggregacie tylko dla określonych zdarzeń. Np. zmiana adresu użytkownika nie konfiktuje ze zmianą jego statusu. Mechanizm ten szczególnie jest przydatny jeśli klienci pracują w trybie off-line. W momencie synchronizacji z serwerem, prawdopodobieństwo wystąpienia zmian równoległych jest dużo większe.

### Testowanie

Testowanie logiki biznesowej jest czytelne i efektywne. Szkielet metody testującej wygląda następująco:

    // given
    // create AR by replying list of events

    // when
    // dispatch a Command

    // then
    // expect given list of events or exception

W testach weryfikujemy zatem tylko to czy wygenerowane zdarzenia odpowiadają tym oczekiwanym.

## Optymalizacja obsługi zapytań

Widoki mogą być w dowolny sposób budowane (baza sql, baza dokumentowa, nosql). W przypadku użycia bazy sql, widoki mogą być zdenormalizowane (dla zapewnienia maksymalnej wydajności zapytań). W trakcie rozwoju systemu możliwe jest łatwe tworzenie dowolnych nowych widoków / raportów. Wypełnienie nowych widoków danymi historycznymi jest możliwe dzięki odtworzeniu zdarzeń historycznych z Event Store.

### Task based UI

Interfejs użytkownika odzwierciedla komendy akceptowalne przez system.

## Kiedy stosować CQRS

Aby zdefiniować komendy i zdarzenia, wymagane jest dobre zrozumienie domeny i jej dekompozycja. Z uwagi na powyższe, CQRS nie koniecznie nadaje się do zastosowania dla całego systemu. Domeny dla których zastosowanie CQRS niesie największe korzyści to te, które z jednej strony stanowią o wartości biznesowej systemu, z drugiej strony wymagają optymalizacji pod kątem możliwości udostępniania (i modyfikacji) tych samych bądź powiązanych danych wielu użytkownikom systemu jednocześnie (collaborative domains).

## Event Driven Architecture

Stosowanie CQRS z użyciem ES zachęca do budowania systemów sterowanych zdarzeniami. Poszczególne moduły systemu (obsługujące różne dziedziny biznesowe (Bounded Contexts)) mogą komunikować się ze sobą za pomocą zdarzeń (push integration). Każdy moduł korzysta tylko z danych lokalnych, które aktualizuje w oparciu o zdarzenia odbierane z innych modułów. Dzięki takiej architekturze, możliwe jest czasowe wyłączenie poszczególnych modułów bez konsekwencji dla całego systemu.


[http://pkaczor.blogspot.com/2012/02/cqrsdddes-w-piguce.html](http://pkaczor.blogspot.com/2012/02/cqrsdddes-w-piguce.html)

{% include bio_pawel_kaczor.html %}
