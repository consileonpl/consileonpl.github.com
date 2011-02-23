---
layout: post
title: JPA - stronicowanie wyników kwerendy
categories: [orm]
---
Interfejs kwerendy zdefiniowany w JPA (``javax.persistence.Query``) umożliwia stronicowanie listy wyników (**paging**). Służą do tego metody: 

{% highlight java %}
setFirstResult(int startPosition)
setMaxResults(int maxResult)
{% endhighlight %}

Wynikiem kwerendy ze stronicowaniem jest podzbiór obiektów czyli strona, której numer i rozmiar określają odpowiednio parametry ``startPosition`` i ``maxResult``.
Stronicowanie przyspiesza działanie aplikacji (mniejsza ilość danych do przetwarzania) oraz ułatwia użytkownikowi nawigację i wyszukiwanie określonych rekordów. Jednak jak to zwykle w świecie ORM bywa, każde rozwiązanie ma swoje "problemy", które w przypadku stronicowania objawiają się wraz z użyciem mechanizmu ładowania wyprzedzającego elementów kolekcji.

## Ładowanie wyprzedzające ze stronicowaniem

Ładowanie wyprzedzające generalnie polega na wykonaniu kwerendy w taki sposób, aby razem z głównymi obiektami pobrane zostały obiekty powiązane (pojedyncze obiekty bądź kolekcje). Najbardziej popularnym sposobem ładowania wyprzedzającego jest złączenie tabel w kwerendzie (**join fetching**). Niestety, metoda ta nie nadaje się do zapytań ze stronicowaniem. Zobaczmy dlaczego.

## Przykład

Mamy obiekt zamówienia (``Order``) zawierający pozycje (``LineItem``):

{% highlight java %}
@Entity
public class Order {
  // ... ...
  @OneToMany
  private List<LineItem> lineItems;

 @Temporal(DATE)
 private Date orderDate;
}
{% endhighlight %}

Załóżmy, że chcemy wyświetlić użytkownikowi stronę z listą zamówień. Jednocześnie dla każdego zamówienia chcemy załadować jego pozycje. W tym celu tworzymy kwerendę na obiekcie ``Order``, ze stronicowaniem oraz ze złączeniem kolekcji ``lineItems``:

{% highlight java %}
Query query = em.createQuery("SELECT o FROM Order o LEFT JOIN FETCH o.lineItems");
query.setFirstResult(1);
query.setMaxResults(3);
List<Order> page = query.getResultList();
{% endhighlight %}

Złączenie definiujemy w JPQL za pomocą klauzuli ``JOIN FETCH``.

**Oczekiwania wobec dostawcy JPA**

Załóżmy, że w bazie mamy 3 zamówienia z różną ilością pozycji. 
Oczekujemy, że zarządca utrwalania (``EntityManager``) wykona pojedyncze zapytanie sql (z klauzulą ``left outer join``) i zwróci listę zawierającą 3 obiekty ``Order``. Dodatkowo oczekujemy, że w każdym obiekcie ``Order``, kolekcja ``lineItems`` będzie załadowana.

**Realizacja**

 - Hibernate

Hibernate co prawda zwraca oczekiwany wynik, ale generuje podejrzanie brzmiący komunikat:
``firstResult/maxResults specified with collection fetch; applying in memory!``

 - EclipseLink

EclipseLink zwraca 2 obiekty ``Order``.

**Wyjaśnienie**

Aby zrozumieć co się stało, zobaczmy jak dokładnie wygląda wynik naszej kwerendy na poziomie rekordów bazy danych bez uwzględnienia stronicowania:

| order_id     | line_id    | cust_name       | sku 
|--------------------------------------------------------
| 1            | 1          | Jan Kowalski    | 232342342   
| 1            | 2          | Jan Kowalski    | 345345443   
| 2            | 3          | Paweł Kaczor    | 655624323   
| 3            | 4          | Jerzy Dudek     | 673454345   
| 3            | 5          | Jerzy Dudek     | 563425676   
| 3            | 6          | Jerzy Dudek     | 234576854   

Widzimy, że w wyniku złączenia, otrzymujemy zbiór rekordów liczebnością przekraczający ilość zamówień. Jeśli z takiego zbioru będziemy chcieli wyciągnąć stronę o rozmiarze 3, otrzymamy tylko pierwsze **trzy** rekordy zawierające zamówienia z id 1 i 2. Zamówienie z id 3 zostanie wykluczone. Otrzymamy zatem **dwa** zamówienia zamiast **trzech**! Wniosek: stronicowanie na poziomie rekordów w kwerendzie ze złączeniem ``outer join``  jest niedokładne.

Teraz już wiemy dlaczego EclipseLink zwrócił dwa zamówienia. Ale jakim sposobem Hibernate zwrócił trzy zamówienia? Odpowiedź jest prosta (ale bolesna). Hibernate omija problem poprzez załadowanie wszystkich rekordów z tabeli i wyselekcjonowanie strony w pamięci (stąd magiczne: "applying in memory"!). Rozwiązanie to zwiększa zużycie zasobów (procesora i pamięci), co przeczy głównemu celowi (zwiększeniu wydajności), dla którego stosujemy stronicowanie. Należy poszukać lepszego rozwiązania.

## Ładowanie wsadowe ze stronicowaniem

Ładowanie wsadowe (**batch fetching**) to bardziej zaawansowany sposób pobierania wyprzedzającego. Obiekty powiązane nie są ładowane w kwerendzie głównej, ale w dodatkowej kwerendzie, której ostateczna postać zależy od wybranego (o ile dostawca na to pozwala) typu ładowania wsadowego. 

Stronicowanie wykonywane jest bezproblemowo w kwerendzie głównej, która nie zawiera klauzuli ``outer join``.

**Konfiguracja -  Hibernate**

Dla kolekcji ``lineItems`` specyfikujemy ładowanie wsadowe używając adnotacji ``@org.hibernate.annotations.BatchSize``:  

{% highlight java %}
@OneToMany
@BatchSize(size = 20)
private List<LineItem> lineItems;
{% endhighlight %}

Parametr ``size`` w adnotacji ``@BatchSize`` oznacza ilość elementów kolekcji, jaka zostanie załadowana w pojedynczej kwerendzie sql.

**Konfiguracja -  EclipseLink**

Ten sam sposób ładowania wsadowego konfigurujemy w EclipseLink następująco: 

{% highlight java %}
@OneToMany
@BatchFetch(BatchFetchType.IN, size = 20)
private List<LineItem> lineItems;
{% endhighlight %}

**Realizacja**

Tworzymy kwerendę JPA tym razem bez klauzuli ``JOIN FETCH``. W celu lepszego zobrazowania działania pobierania wsadowego, dodajemy warunek na pole ``orderDate``.

{% highlight java %}
Query query = em.createQuery("SELECT o FROM Order o WHERE o.orderDate = CURRENT_DATE");
query.setFirstResult(1);
query.setMaxResults(3);
List<Order> page = query.getResultList();
{% endhighlight %}

Wygenerowane zostają dwa zapytania sql:

 - kwerenda główna zamówień (ze stronicowaniem)
{% highlight sql %}
SELECT * 
FROM Order o
WHERE o.ORDER_DATE = ? LIMIT ? OFFSET ?
{% endhighlight %}

 - kwerenda dodatkowa - załadowanie wsadowe pozycji zamówień
{% highlight sql %}
SELECT *
FROM Order o, LineItem li 
WHERE o.ID = li.ORDER_ID AND li.ORDER_ID IN (?,?)
{% endhighlight %}

Jak widzimy, w celu załadowania pozycji tylko dla zamówień pobranych w kwerendzie głównej, w kwerendzie dodatkowej została użyta klauzula **``IN``**.

**Optymalizacja - EclipseLink**

EclipseLink pozwala skonfigurować trzy typy pobierania wsadowego: (``IN, JOIN, EXISTS``)
Typ ``IN`` już znamy. Mankamentem jest tutaj ograniczona ilość elementów kolekcji, które mogą być załadowane w jednej kwerendzie sql. Efektywniejszym rozwiązaniem jest użycie kryteriów selekcji z kwerendy głównej w kwerendzie dodatkowej (typ ``JOIN`` - "The original query's selection criteria is joined with the batch query").  

**Konfiguracja:**

{% highlight java %}
@OneToMany
@BatchFetch(BatchFetchType.JOIN)
private List<LineItem> lineItems;
{% endhighlight %}

Wygenerowana kwerenda dodatkowa wygląda następująco:

{% highlight sql %}
SELECT *
FROM Order o1, Order o2, LineItem li 
WHERE o1.ID = li.order_id AND (o2.ID = li.order_id AND o1.ORDER_DATE = ?)
{% endhighlight %}

Widzimy, że problematyczna klauzula ``IN`` zastąpiona została kryterium wyboru identycznym jak w kwerendzie głównej. 

## Podsumowanie

W powyższym artykule przedstawiłem w jaki sposób stosować stronicowanie (**paging**) w kwerendach JPA. Szczegółowo omówiłem problem stronicowania, kiedy w kwerendzie używane jest ładowanie wyprzedzające elementów kolekcji.

[http://pkaczor.blogspot.com/2011/02/jpa-stronicowanie-wynikow-kwerendy.html](http://pkaczor.blogspot.com/2011/02/jpa-stronicowanie-wynikow-kwerendy.html)

{% include bio_pawel_kaczor.html %}
