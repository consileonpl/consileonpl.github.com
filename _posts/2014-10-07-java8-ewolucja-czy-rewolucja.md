---
layout: post
title: Java 8 - ewolucja czy rewolucja?
categories: [java]
---




Najnowsza wersja Javy jest dostępna od jakiegoś czasu - wygląda na stabilną, powoli zaczyna być akceptowana przez firmy, które pozwalają swojm działom IT zrobić upgrade w środowiskach produkcyjnych.

Najczęściej wymieniane i dyskutowane zmiany w stosunku do 1.7 to:

 - metody default w interfejsach
 - wyrażenia lambda
 - Stream API 
 - parallel streams
 - silnik JavaScript (Nashhorn) w JVM
 
poza tym, jest też kilka innych, moim zdaniem istotnych, ale już mniej znanych:

 - nowe metody w java.lang.Process - destroyForcibly(), isAlive() i waitFor() - pozwalają lepiej kontrolować procesy systemu operacyjnego utworzone z poziomu Javy
 - nowe date-time API (java.time.*)
 - atomowe typy i sumatory (adders) - zapewniające atomowość operacji przy wielu wątkach (java.util.concurrent.atomic.*) - i to bez blokowania
 - '*Exact' w java.util.Math - wersje metod dla operacji na liczbach, które sprawdzają czy nie nastąpiło przepełnienie (overflow) dla typu który jest używany do obliczeń
 - bezpieczne generowanie liczb losowych (SecureRandom.getInstanceStrong()) - bardzo istotne w przypadku szyfrowania
- Optional<T> - sposób na jawne określenie czy zmienna może być null - (żegnaj NullPointerException?)

Oczywiście jest tego trochę więcej (w samym JVM), ale z punktu widzenia programisty patrzącego na możliwości języka, to byłyby rzeczy najbardziej istotne.

  OK, na pierwszy rzut oka wygląda to podobnie jak ewolucja w przypadku wcześniejszych wersji - 1.4, 1.5, 1.6 czy 1.7. Trochę nowych rzeczy, trochę 'syntactic sugar', sporo programistów się ucieszy, paru zdenerwuje (vide: runtime generics type erasure... wrr) - nic wielkiego. Czy na pewno?
  Java dotychczas była postrzegana jako język w którym króluje paradygmat OO - przekazywanie zachowania było, może nie niemożliwe, ale bardzo uciążliwe i wymagało niepotrzebnego mnożenia bytów (klas). Kod robił się zagmatwany i nieczytelny. Z pewnością wprowadzanie elementów programowania funkcyjnego nie było czymś naturalnym - takie rozwiązania stosowane są raczej w odosobnionych przypadkach, kiedy jest to oczywisty wybór.
  Wraz z pojawieniem się lambd mamy teraz do czynienia z możliwością diametralnej zmiany w sposobie pisania kodu. 
Co prawda wciąż, gdy chcemy zrobić cokolwiek pojawiają się nowe i nowe klasy, co jest specjalnością Javy (konieczność utworzenia nowej klasy, tyko żeby napisać 'hello world' w konsoli dość dobrze ilustruje problem...) ale otworzyło się przed nami bogactwo nowych możliwości.

  Spróbuję pokazać jak wygląda kod który bardzo intensywnie wykorzystuje nowości z Java 8.

  Załóżmy sobie, że mamy następujący problem do rozwiązania: plik CSV z danymi dotyczącymi siły wiatru w węzłach (takie osobiste skrzywienie będące skutkiem uprawiania sportu zależnego od wiatru :) ) oraz opadów z podziałem z dokładnością co do 1 godziny każdego dnia, takiej oto postaci:

{% highlight text %}

DATE	00h	01h	02h	03h	04h	05h	06h	07h	08h	09h	10h	11h	12h	13h	14h	15h	16h	17h	18h	19h	20h	21h	22h	23h	00h	01h	02h	03h	04h	05h	06h	07h	08h	09h	10h	11h	12h	13h	14h	15h	16h	17h	18h	19h	20h	21h	22h	23h
01.01.2014	10	9	10	10	10	10	10	10	10	10	10	9	9	9	9	10	9	9	10	7	8	8	8	8	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	
02.01.2014	9	7	8	9	10	10	11	9	10	11	12	11	12	10	10	11	11	11	11	8	8	9	9	10	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	0.1	
03.01.2014	10	8	8	8	9	8	9	7	7	7	8	8	9	7	9	11	12	13	14	12	13	13	14	13	0.3	0.2	0.3	0.1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	0.2	0.2	
04.01.2014	14	12	15	16	16	16	15	13	13	12	10	9	9	7	8	9	10	11	12	10	14	16	16	17	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	0.3	
05.01.2014	17	16	14	12	11	11	11	8	11	11	11	11	11	9	10	11	11	12	11	11	12	11	10	11	1.2	1	1	1.1	1	0.7	0.1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	-1	0.5	0.8	0.7	0.3	-1	
0
...

{% endhighlight %}


i zadanie znalezienia miesięcy w których był przynajmniej jeden dzień w którym w godzinach, powiedzmy 9:00-18:00 wiał wiatr o sile przynajmniej 16kt i średni opad w tym czasie wynosił poniżej 0.2. Załóżmy też, że ilość danych wejściowym może być na tyle duża, że będziemy unikać przetwarzania całości w pamięci. W pierwszej wersji będziemy je pobierać z pliku CSV ale potencjalnie może być to też web-service, więc dobrze byłoby zachować odpowiedni poziom abstrakcji co do źródła danych.
Mając do dyspozycji nowinki z Java 8, można ten problem rozwiązać szybko i dosyć elegancko. Wykorzystamy nowe metody w java.nio.*, Stream API, oczywiście wyrażenia lambda, nowe klasy/metody do operacji na czasie (java.time.*, java.time.format.*).

Najpierw przyda się klasa, która będzie reprezentowała wiersz w naszym pliku CSV, który jest dosyć specyficzny:
- 1. kolumna to data w formacie dd.MM.yyyy
- kolumny 2-25 to wartości (liczby całkowite) siły wiatru dla kolejnych godzin 00h, 01h...23h
- kolumny 26-49 to wartości (zmiennoprzecinkowe) średnich opadów w kolejnych godzinach 00h, 01h...23h
Czyli potrzebujemy pobrać pierwszą kolumnę, skonwertować na datę, oraz pozostałe rozdzielić na 2 tablice o różnych typach, np. tak:

{% highlight java %}

class WindDataRow {
	LocalDate date;
	int wind[];
	double percip[];

	public WindDataRow(LocalDate date, int[] wind, double[] percip) {
		super();
		this.date = date;
		this.wind = wind;
		this.percip = percip;
	}

	private static final DateTimeFormatter  dateFormatter = DateTimeFormatter.ofPattern("dd.MM.yyyy");
	
	public static WindDataRow fromCSVLine(String[] columns) {
		LocalDate date = LocalDate.parse(columns[0], dateFormatter);

		int[] wind = Arrays.stream(columns).skip(1).limit(24)
                                       .mapToInt(Integer::valueOf).toArray();
		double percip[] = Arrays.stream(columns).skip(25)
                                            .mapToDouble(Double::valueOf).toArray();

		return new WindDataRow(date, wind, percip);
	}
}
{% endhighlight %}

  Wszystko wygląda dosyć standardowo, za wyjątkiem użycia stream'ów do konwersji strumienia String'ów na tablice int[] i double[].Użyty został także nowy lepszy (w końcu!) typ LocalDate dla reprezentacji czasu oraz tread-safe DateTimeFormatter zamiast popularnego SimpleDateFormat (który z jakiegoś niezrozumiałego powodu jest wewnętrznie modyfikowalny i ma stan).

Teraz zabierzmy się za pobranie danych:


{% highlight java %}

	public List<LocalDate> findTheGoodTimes(Path path, 
			Predicate<WindDataRow> filterPredicateFunc, 
			TimeSpanHours hours, double minWind, double minPerc) throws IOException, ParseException {
							
		Objects.requireNonNull(path);

		List<LocalDate> results;
		try (Stream<String> linesStream = Files.lines(path)) {

			Stream<WindDataRow> objStream = linesStream.skip(1)
					.map(line -> line.split("\t")).map(WindDataRow::fromCSVLine);
			
			results = processData(filterPredicateFunc, hours, minWind, minPerc, objStream);

		}

		return results;

	}

{% endhighlight %}

  Tu ciekawie - po pierwsze użyłem konstrukcji 'try-with-resources' korzystając z faktu, że Stream<T> implementuje interfejs java.lang.AutoCloseable (niezależnie jak został utworzony). Po drugie - bardzo eleganckiej metody Files.lines(), która potrafi dostarczyć nam zawartość pliku linia po linii jako strumień. Krótko i konkretnie, nigdy czytanie plików w Javie nie było takie proste.

  Z innych ciekawostek - dodałem jako parametr możliwość przekazania funkcji (Predicate), która wykona jakiś rodzaj filtrowania na strumieniu naszych obiektów WindDataRow, którą postaram się wpleść jakoś w kod przetwarzający dane wejściowe.

  Zaczynamy przetwarzać strumień - pomijamy pierwszą linię (skip(int)), tniemy (mapujemy) linię na kolumny prostym String.split("\t") a następnie mapujemy tablicę String'ów na nasz POJO podając po prostu metodę która ma zostać użyta do konwersji. Wygląda jak C++, prawda? ;) Jako bonus - użyłem nową metodę Objects.requireNonNull() która rzuci wyjątek gdy argumenty metody nie będą spełniały kryteriów.

  Teraz mamy już strumień POJO z posegregowanymi danymi - wystarczy przefiltrować dane na różne sposoby oraz pogrupować wyniki miesiącami, co można zrobić tak:

{% highlight java %}	

  public List<LocalDate> findTheGoodTimes(Path path, 
			Function<Stream<WindDataRow>, Stream<WindDataRow>> extraFilterFunc, 
			int startHour, int endHour, double minWind, double minPerc) throws IOException, ParseException {

		Objects.requireNonNull(path);
		int hourLimit = endHour - startHour;

		List<LocalDate> results;
		try (Stream<String> linesStream = Files.lines(path)) {

			Stream<WindDataRow> objStream = linesStream.skip(1)
					.map(line -> line.split("\t")).map(WindDataRow::fromCSVLine);
			
			Map<LocalDate, List<WindDataRow>> groupedByMonths = 
					extraFilterFunc.apply(objStream)
					.filter(e -> Arrays.stream(e.percip).skip(startHour).limit(hourLimit)
									.average().getAsDouble() < minPerc)
					.filter(e -> Arrays.stream(e.wind)
									.skip(startHour).limit(hourLimit)
									.average().getAsDouble() > minWind )
					.collect( 
							Collectors.groupingBy(
									e -> LocalDate.of(e.date.getYear(), e.date.getMonthValue(), 1)
							)
					);
			
			results = groupedByMonths.keySet().stream().sorted()
					.peek(System.out::println)
					.collect(Collectors.toList());

		}

		return results;
  }

{% endhighlight %}

Mamy tutaj najpierw użycie arbitralnego wyrażenia Predicate przekazanego 'z góry' (nie wiemy i nie musimy wiedzieć co potencjalnie ono robi) oraz kolejno filtry z wyrażeń lambda, które obliczają średnią (oczywiście z użyciem Stream API) z danych dot. wiatru i wilgotności w zadanych godzinach i porównują wynik z warunkami min/max. Mamy już podzbiór danych, które spełniają kryteria, teraz trzeba je zebrać ( .collect() ), grupując miesiącami, co ułatwia predefiniowany Collectors.gruppingBy(...). Zbiór kluczy z wynikowej mapy (czyli miesiące) sortujemy i zamieniamy na listę, która jest końcowym wynikiem. W ramach podglądu - dodałem wywołanie .peek(...) które jest sposobem na zrobienie czegoś z pośrednim wynikiem przetwarzania strumienia, bez jego modyfikacji - z reguły do logowania i debugowania (można w zasadzie wszystko, ale 'side-effects' spowodują komplikacje przy próbie równoległego wykonania...).


  Przydałoby się jakoś ten cały nowoczesny kod uruchomić, więc dodam klasę z metodą main() i zdefiniuję sobie jeszcze dodatkową funkcję (Predicate) który przefiltruje strumień naszych POJO pod kątem zadanego przedziału czasowego. Oczywiście przekażę tą funkcję jako zwykły parametr (ot tak, bo mogę!). Niestety, typy generyczne powodują, że nie wygląda to idealnie przejrzyście, ale coś za coś...:

{% highlight java %}

	public static void main(String[] args) throws IOException, ParseException {
		
		LocalDate startDate = LocalDate.of(2013, Month.DECEMBER, 31);
		LocalDate endDate = LocalDate.of(2014, Month.JULY, 1);
		
		final TimeSpanHours hours = new TimeSpanHours(9, 18);
		
		
		Predicate<WindDataRow> filterByTimePredicateFunc = 
				e  -> e.date.isAfter(startDate) && e.date.isBefore(endDate);
		
		new WeatherStatsAnalyzer().findTheGoodTimes(
				Paths.get("wg_data.csv"), filterByTimePredicateFunc, hours, 16, 0.2
		);
	}

{% endhighlight %}

(TimeSpanHours to tylko małe 'opakowanie' dla przedziału czasowego w godzinach)

Wynik uruchomienia to: 

{% highlight text %}
2014-01-01
2014-02-01
2014-03-01
{% endhighlight %}

wypisane na konsoli (dzięki wywołaniu .peek(...) ). Gotowe :)



  Podsumowując, zadanie nie było bardzo skomplikowane i prawdopodobnie szybciej i łatwiej byłoby wrzucić dane do relacyjnej bazy danych jednym poleceniem z poziomu Bash'a i wyciągnąć dane jednym, choć dosyć złożonym, zapytaniem SQL. Z tą różnicą, że w powyższym przypadku nie ogranicza nas ilość danych wejściowych. Całe przetwarzanie odbywa się linia po linii. Bardzo łątwo jest zmodyfikować kod tak, żeby dane nie były pobierane z pliku tylko z jakiegokolwiek źródła - np. WebService poprzez podstawienie innego strumienia zamiast naszego 'linesStream'. Nie musimy w ogóle dotykać kodu który przetwarza później dane (i zrobić strumień parametrem metody). 
  Możemy też, w przypadku gdy źródło jest wolne - dodać magiczne słowko 'parallel' gdy tworzymy strumień i przetwarzanie zostanie wykonane na wszystkich dostępnych rdzeniach CPU. Tutaj uwaga: należy być ostrożnym w przypadku gdy nie jest to program samodzielny i pulą wątków zarządza np. web server - każdy wątek przetwarzający request zacznie sam mnożyć wątki... i możemy osiągnąć skutek odwrotny do zamierzonego.
  W powyższym rozwiązaniu jest jednakże pewne silne podobieństwo do języka SQL - wynika to z faktu, że kod stał się dużo bardziej deklaratywny niż imperatywny. W SQL nie mówimy przecież jak silnik BD ma iterować po encjach, jak obliczać średnią czy ma to robić na 1 czy wielu wątkach, po prostu mówimy czego oczekujemy. Tak jak, w dużej mierze, w naszym przykładzie. Zadziwiające, że manipulowaliśmy na kilku tablicach, listach i mapach i nie użyliśmy ani razu pętli programowej (for/while), prawda?

 Programiści używający chociażby Pythona uśmiechną się teraz z politowaniem, ale, moim skromnym zdaniem, dla Javy to z pewnością jest rewolucja. Możliwość swobodnego przekazywania zachowania a nie tylko samych danych ma szansę mocno zmienić styl programowania w Javie nie tylko w detalach ale również na poziomie struktury aplikacji.
  Ja osobiście widzę wzorce projektowe jako usystematyzowane sposoby na obejście niedoskonałości i ograniczeń konkretnego języka programowania. Mam tu na myśli wzorce dotyczące konstrukcji programów, nie bardziej ogólne dot. architektury (np. MVC). Niestety, trzeba przyznać, że Java ma wyjątkowo dużo wzorców projektowych, co wcale nie jest konsekwencją wspaniale rozwiniętego środowiska programistów, ale właśnie bardzo ograniczonego (sztywnego) języka.
Mając do dyspozycji Javę 8 wygląda, że należy się przyjrzeć krytycznie zwłaszcza tzw. behavioral design patterns, takim jak Command, Observer, Template Method, Strategy czy Chain of Responsibility. Z pomocą wyrażeń lambda, można je uprościć albo całkiem wyeliminować i może przestać nazywać wzorcami projektowymi, skoro są czymś oczywistym i taki np. CoR można zaimplementować tworząc ciąg wyrażeń lambda, Command z kolei to... po prostu lambda a i np. Decorator pattern da się często sprowadzić również do użycia lambdy...

  Czas pokaże, na ile zmieni się sposób programowania w Javie i czy koncepcje OO wciąż będą remedium na wszystkie problemy.

[kompletny kod jest dostępny jako [repozytorium GIT'a][1]]

{% include bio_bartlomiej_nicka.html %}

[1]: https://github.com/bartolomeon/java8_exercise_1
