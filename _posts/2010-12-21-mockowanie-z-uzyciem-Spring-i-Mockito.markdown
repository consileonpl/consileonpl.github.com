---
layout: post
title: Mockowanie z użyciem Spring i Mockito
categories: [spring, testowanie]
---
W poniższym wpisie chciałbym przedstawić jak efektywnie skonfigurować testy integracyjne w Spring z użyciem mocków.

## Testy integracyjne w Spring

Tworzenie i uruchamianie testów integracyjnych w Spring jest dziecinnie proste dzięki dobrodziejstwom jakie dostarcza [Spring TestContext Framework](http://static.springsource.org/spring/docs/3.0.x/reference/testing.html#testcontext-framework). 
Zakładając, że plik xml konfiguracji kontekstu aplikacji Spring (Spring Application Context) w module aplikacji, który chcemy testować, nazwaliśmy ``applicationContext.xml``, uruchomienie testu integracyjnego JUnit dla takiego moduły wygląda następująco: 

{% highlight java %}
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = {
		"classpath:applicationConfig.xml" 
})
public class DoSthTest {

@Test
public void shouldDoSth() {}

}
{% endhighlight %}

Jest to najprostszy sposób na przetestowanie poprawności pliku konfiguracji kontekstu aplikacji, w którym zdefiniowane są zależności pomiędzy klasami zarządzanymi przez Spring.

No dobrze, ale chcemy przetestować konkretny serwis, który stworzyliśmy. Zatem do naszego testu wstrzykujemy serwis i tworzymy dla niego metodę testującą:

{% highlight java %}
@Autowired
private DoSthService serviceToTest 

@Test
public void shouldReturnSth() {
	// when
	Object result = serviceToTest.doSth();
	
	// then
	assertNotNull(result)
}
{% endhighlight %}

## Tworzenie mocka

Nasz serwis korzysta z kilku innych serwisów, w tym z serwisu ``HttpClient``, który w naszym teście musimy zastąpić mockiem. 
Jednym ze sposobów jest ręczna zmiana zależności w kodzie testu: 

{% highlight java %}
@Test
public void shouldReturnSth() {
	// given
	HttpClient mockHttpClient = Mockito.mock(HttpClient.class);
	serviceToTest.setHttpClient(mockHttpClient);
	...
}
{% endhighlight %}

Sposób ten ma jednak kilka wad:

 - Dla każdego testu (metody testującej) musimy sami tworzyć i przypisywać mocka

 - Serwis musi dostarczać settera dla zależności mockowanej, podczas gdy w przypadku wstrzykiwania zależności za pomocą adnotacji setter nie jest wymagany

 - Mockujemy tylko konkretną zależność między dwoma beanami. Jeżeli serwis który mockujemy jest używany przez inny serwis biorący udział w teście (np. ``DoSthService`` używa ``HttpClient`` i ``OtherService``, a ``OtherService`` używa ``HttpClient``) , musimy mockować każdą zależność osobno

Lepszym rozwiązaniem jest podmiana serwisu ``HttpClient`` bezpośrednio w kontekście aplikacji. Oczywiście nie możemy zmienić pliku ``applicationContext.xml``, musimy stworzyć odrębny kontekst aplikacji i wskazać go w konfiguracji naszego testu:

{% highlight java %}
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = {
		"classpath:applicationConfig-test.xml" 
})
public class DoSthTest {

@Test
public void shouldReturnSth() {
	// when
	Object result = serviceToTest.doSth();
	...
}
}
{% endhighlight %}

No dobrze, ale jak stworzyć mocka w pliku konfiguracji kontekstu aplikacji, skoro nasz mock nie jest utworzoną przez nas osobną klasą, ale został wygenerowany automatycznie przez framework [Mockito](http://mockito.org) ( ``Mockito.mock(HttpClient.class)`` ) ?

Rozwiązanie jest proste. Metodę ``Mockito.mock`` należy zadeklarować jako metodę fabrykującą naszego mocka podając jako argument tej metody klasę obiektu mockowanego:

{% highlight xml %}
<bean id="httpClient" class="org.mockito.Mockito" factory-method="mock">
	<constructor-arg value="org.apache.http.client.HttpClient"/> 
</bean>
{% endhighlight %}


## Dostrajanie konfiguracji

Kopiowanie całej konfiguracji kontekstu aplikacji w celu nadpisania jednego serwisu prowadzi do redundancji kodu (kodu konfiguracji), a zatem zwiększa koszt utrzymania aplikacji.
Jeżeli chcemy tego uniknąć, możemy zdefiniować dwa pliki konfiguracji kontekstu aplikacji w konfiguracji naszego testu:

{% highlight java %}
@ContextConfiguration(locations = {
		"classpath:applicationConfig.xml", 
		"classpath:applicationConfig-test.xml" 
})
public class DoSthTest {
...
}
{% endhighlight %}

W pliku ``applicationConfig-test.xml`` definiujemy tylko mocki, które zastąpią istniejące beany w konfiguracji głównej.
Zwróćmy uwagę na kolejność deklaracji plików konfiguracji. Ważne jest aby deklaracja pliku konfiguracji mocków następowała po deklaracji pliku głównego konfiguracji.

## Autowstrzykiwanie mocków
 
W przypadku gdy korzystamy z autowstrzykiwania zależności, nasz mock będzie dostępny tylko gdy wstrzykiwanie zależności odbywa się na podstawie nazwy. A zatem mock nie zostanie znaleziony jeśli używamy adnotacji ``@Autowired``, dla której wstrzykiwanie odbywa się na podstawie typu. Rozwiązaniem może być dodanie kwalifikatora wskazującego nazwę zależności:

{% highlight java %}
@Autowired
@Qualifier(value="httpClient")
private HttpClient httpClient;
{% endhighlight %}

Jednak lepszym rozwiązaniem jest zastosowanie adnotacji ``@javax.annotation.Resource``. W tym przypadku zależność najpierw wyszukiwana jest po nazwie, a w przypadku braku pasującej nazwy, po typie.

## Włączanie/wyłączanie mocków

Czasami ten sam test integracyjny chcemy uruchamiać zarówno z serwisem w postaci mocka jak i z serwisem rzeczywistym. Jeśli stosujemy opisaną powyżej metodę nadpisywania beanów z konfiguracji głównej mockami z konfiguracji testowej, włączenie/wyłączenie mocka można łatwo osiągnąć modyfikując plik konfiguracji mocków (dodając bądź usuwając mocka). Jednak co z kodem sterującym zachowaniem mocka (patrz kod poniżej)? 

{% highlight java %}
@Autowired
private DoSthService serviceToTest 

@Resource
private HttpClient httpClient;

@Test
public void shouldReturnSth() {
	// given
	//httpClient must be a mock!
	given(httpClient.execute(any(HttpUriRequest.class)))
		.willReturn(myResponse);

	// when
	Object result = serviceToTest.doSth();
	...
}
{% endhighlight %}

Uruchomienie tego kodu na obiekcie nie będącym mockiem zakończy się wyjątkiem. Należy zatem kod sterujący mockiem wykonać warunkowo tylko jeśli obiekt rzeczywiście jest mockiem. Sprawdzenie implementujemy następująco:

{% highlight java %}
// given
if (!httpClient.getClass().isAssignableFrom(HttpClient.class)) {
	given(httpClient.execute(any(HttpUriRequest.class)))
		.willReturn(myResponse);
}
{% endhighlight %}

## Współdzielenie mocków
Jeżeli chcielibyśmy użyć tego samego mocka w kilku metodach testowych musimy pamiętać o zresetowania stanu mocka przed każdym testem.
Najprostszym rozwiązaniem jest dodanie do klasy testu metody ``resetMocks`` z adnotacją ``@org.junit.Before``:
 
{% highlight java %}
@Before
public void resetMocks() {
	Mockito.reset(httpClient);
}
{% endhighlight %}


## Mockowanie częściowe

Na koniec przedstawię w jaki sposób utworzyć w konfiguracji kontekstu aplikacji częściowego mocka, czyli obiekt, którego zachowanie tylko w części chcemy mockować (np. zmieniając tylko rezultat wywołania metody):

{% highlight xml %}
	<bean id="httpClient" class="org.apache.http.client.HttpClient"/>
 	<bean id="httpClientPartiallyMocked" class="org.mockito.Mockito" factory-method="spy">
		<constructor-arg ref="httpClient" /> 
	</bean>
{% endhighlight %}

W tym przypadku tworzymy mocka przy pomocy metody fabrykującej ``Mockito.spy``, podając jako argument tej metody referencję do istniejącego bean-a. 


[http://pkaczor.blogspot.com/2010/12/mockowanie-przy-uzyciu-spring-i-mockito.html](http://pkaczor.blogspot.com/2010/12/mockowanie-przy-uzyciu-spring-i-mockito.html)

{% include bio_pawel_kaczor.html %}
