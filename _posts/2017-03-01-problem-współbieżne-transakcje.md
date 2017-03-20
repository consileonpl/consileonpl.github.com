---
layout: post
title: Problem z transakcjami współbieżnymi
categories: [architecture,orm]
---

## Technologia

* Red Hat Jboss Enterprise Application Platform 6.4 
* Oracle 11 
* Aplikacja webowa: Wicket, EJB, Hibernate 4.1
* encje hibernate nie wspierają optimistic-locking

## Wymaganie

Wymaganiem klienta jest aby zainicjowany przez użytkowanika proces biznesowy polegający na przetworzeniu dużej ilości encji (kilka tysięcy) wykonał się jak najszybciej, w tle. 

## Problem

Uruchomione w tle przetwarzanie wsadowe (EJB, Hibernate) powoduje, że niektóre strony wyświetlają się z dużym opóźnieniem.

## Problem - wyjaśnienie

Podczas przetwarzania żądania wyświetlenia strony wywoływana jest metoda EJB typu kwerenda (dane są odczytywane z bazy danych, nie są modyfikowane). Odczyt danych delegowany jest do wartwy JPA (Hibernate), następuje zatem materializacja danych w postaci encji Hibernate w sesji Hibernate związanej z bieżącą transakcją EJB (transakcją on-line). W tym samym czasie, proces wsadowy ma otworzoną transakcję EJB, w której część zmaterializowanych encji jest modyfikowana. Pojedyńcza transakcja procesu wsadowego może trwać nawet kilkanaście sekund. Jeżeli proces wsadowy zmodyfikował encję, która została załadowana przez transakcję on-line, transakcja on-line "zawiesza się" podczas commit-u, do czasu zakończenia transkacji procesu wsadowego. Przyczyna "zawieszania się" nie została precyzyjnie wyjaśniona. Zostało natomiast ustalone, że po aktywacji mechanizmu optimistic-locking w warstwie JPA, transakcja on-line w momencie commit-u, nie "zawiesza się", ale rzuca wyjątek `OptimisticLockingException` (co również jest niakceptowalne).


## Rozwiązanie

Odseparowanie transakcji on-line od transakcji wsadowych, w taki sposób aby nie współdzieliły tej samej Jednostki Utrwalania (Persistent Unit) (PU). 


## Realizacja

Utworzenie oddzielnej aplikacji EAR, do której przeniesiono serwis odpowiedzialny za uruchamianie procesów wsadowych. Definicja PU, znajdująca się we współdzielonym module encji, została sparametryzowana (wartości ```jboss.entity.manager.factory.jndi.name``` i ```jta-data-source``` ustawiane są ze zmiennych środowiskowych).

{% include bio_pawel_kaczor.html %}