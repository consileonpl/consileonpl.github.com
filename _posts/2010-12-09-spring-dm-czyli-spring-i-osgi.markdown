---
layout: post
title: Spring DM - czyli Spring i OSGi
categories: [spring, osgi]
---
Uff, ale dawno nie wrzuciłem żadnego posta na bloga. Czas nadrobić nieco zaległości, a ostatnie tygodnie stały u
mnie pod znakiem **Spring'a**. Obecnie przyglądam się integracji tego frameworka z ciekawą technologią [OSGi](http://en.wikipedia.org/wiki/OSGi),
która ostatnio staje się coraz bardziej modna. Spring w swojej rodzinie frameworków posiada jeden o nazwie
[Spring Dynamic Modules](http://www.springsource.org/osgi), który służy do integracji komponentów Spring'owych z
platformą OSGi (i na odwrót).

## Krótko o platformie OSGi

Jak dotąd platforma Java nie dorobiła się porządnego wsparcia dla modularnych aplikacji. Oczywiście istnieją
wzorce pozwalające nam na modularyzację aplikacji, jednakże z punktu widzenia maszyny wirtualnej jest to wciąż
jedna, monolityczna aplikacja. Czego zatem brakuje Javie, do pełnej modularyzacji?

 * Jasnej definicji tego, czym jest moduł.
 * Określania zakresu widoczności modułu dla innych modułów.
 * Określenia cyklu życia modułu.
 * Określenia sposobów interakcji modułów.

Jak łatwo się domyśleć technologia OSGi została opracowana w celu wypełnienia tej niszy i oferuje platformę,
która zapewnia nam funkcjonalności, których brakuje w standardowej Javie.

To co oferuje nam OSGi to lekką platformę dla komponentowych, oraz zorientowanych na usługi aplikacji w
ramach wirtualnej maszyny Javy (JVM). Możemy dynamicznie, w czasie działania aplikacji, modyfikować rejestr
komponentów (*bundle* - w terminologii OSGi) dodając nowe i podmieniając istniejące komponenty. Platforma
OSGi zapewnia nam pełną izolację komponentów, dzięki czemu mamy pewność, że nie będą one przeszkadzały
sobie nawzajem (np. poprzez konflikty wersji zależnych bibliotek JAR).

## Krótko o Spring DM

**Spring Dynamic Modules** łączy technologię Spring z platformą OSGi. Framework ten nie przynosi żadnej
dodatkowej funkcjonalności dla OSGi a jedynie obserwuje rejestrowane komponenty tworząc dla nich Spring'owe
konteksty aplkiacji. Framework ten potrafi udostępnić komponenty Spring'owe jako komponenty OSGi (widoczne
dla innych komponentów OSGi), oraz dowolny komponent OSGi, nawet nie Spring'owy, zainstalować w kontenerze
Springa.

## Integracja Spring'a z OSGi

No dobra, starczy tej teorii, zobaczmy jak wygląda integracja tych platform w kodzie.

Będziemy potrzebować dwóch komponentów, z których jeden będzie dostarczał usługę, a drugi z niej korzystał.
Oba komponenty utworzone zostaną jako osobne komponenty OSGi.

Najpierw musimy określić interfejs dla naszej usługi:

{% highlight java %}
public interface AuthorizationService {
    boolean authorize(String username, String password);
}
{% endhighlight %}

Teraz możemy utworzyć trywialną implementację tego interfejsu:

{% highlight java %}
public class DefaultAuthorizationService implements AuthorizationService {
    public boolean authorize(String username, String password) {
        return "foo".equals(username) && "secret".equals(password);
    }
}
{% endhighlight %}

Kolejny krok to utworzenie konfiguracji Spring'owej. Framework Spring DM wymaga, aby taka konfiguracja
znajdowała się w katalogu ``META-INF/spring``:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:osgi="http://www.springframework.org/schema/osgi"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd http://www.springframework.org/schema/osgi http://www.springframework.org/schema/osgi/spring-osgi-1.2.xsd">

    <context:component-scan base-package="demo.springdm" />

    <osgi:service interface="demo.springdm.api.AuthorizationService">
        <bean class="demo.springdm.api.impl.DefaultAuthorizationService" />
    </osgi:service>

</beans>
{% endhighlight %}

Najważniejszym elementem tej konfiguracji jest ``<osgi:service>``, który deklaruje Springowy komponent
jako komponent OSGi widoczny dla innych komponentów zainstalowanych w ramach tej platformy. Spring DM
za nas zainstaluje komponent w rejestrze usług (ang. *service registry*) platformy OSGi przez co stanie
się on dostępny dla innych komponentów.

Ok, moduł dostarczający usługe jest gotowy, teraz możemy przejść do modułu korzystającego z usługi.
Utwórzmy zatem komponent Spring'owy do którego wstrzykniemy komponent zainstalowany w platformie OSGi:

{% highlight java %}
@Component
public class AuthorizationClient {
    @Autowired
    private AuthorizationService authorizationService;

    @PostConstruct
    public void authorize() {
        System.out.println("Authorization for foo:bar : " + authorizationService.authorize("foo", "bar"));
        System.out.println("Authorization for foo:secret : " + authorizationService.authorize("foo", "secret"));
    }
}
{% endhighlight %}

Jak widać, jest to typowa klasa POJO z kilkoma adnotacjami typowymi dla Spring'a. Nic magicznego się
tutaj nie dzieje. Aby kod ten działał potrzebujemy jednak komponentu ``authorizationService``:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:osgi="http://www.springframework.org/schema/osgi"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd http://www.springframework.org/schema/osgi http://www.springframework.org/schema/osgi/spring-osgi-1.2.xsd">

    <context:component-scan base-package="demo.springdm" />

    <osgi:reference id="authorizationService" interface="demo.springdm.api.AuthorizationService" />

</beans>
{% endhighlight %}

W tym wypadku importujemy komponent OSGi jako komponent Spring'owy za pomocą ``<osgi:reference>``.

Teraz pozostaje już tylko zainstalowanie komponentów w kontenerze OSGi (ja korzystam z 
[Equinoxa](http://www.eclipse.org/equinox/)):

{% highlight bash %}
$ java -jar org.eclipse.osgi_3.6.1.R36x_v20100806.jar -console

osgi> ss

Framework is launched.

id	  State       Bundle
0	  ACTIVE      org.eclipse.osgi_3.6.1.R36x_v20100806
1	  ACTIVE      org.springframework.osgi.io_2.0.0.M1
2	  ACTIVE      org.springframework.osgi.core_2.0.0.M1
3	  ACTIVE      org.springframework.osgi.extender_2.0.0.M1
4	  ACTIVE      org.springframework.aop_3.0.5.RELEASE
5	  ACTIVE      org.springframework.asm_3.0.5.RELEASE
6	  ACTIVE      org.springframework.beans_3.0.5.RELEASE
7	  ACTIVE      org.springframework.context_3.0.5.RELEASE
8	  ACTIVE      org.springframework.context.support_3.0.5.RELEASE
9	  ACTIVE      org.springframework.core_3.0.5.RELEASE
10	  ACTIVE      org.springframework.expression_3.0.5.RELEASE
11	  ACTIVE      com.springsource.org.aopalliance_1.0.0
12	  ACTIVE      com.springsource.net.sf.cglib_2.1.3
13	  ACTIVE      com.springsource.slf4j.api_1.6.1
	              Fragments=15
14	  ACTIVE      com.springsource.slf4j.org.apache.commons.logging_1.6.1
15	  RESOLVED    com.springsource.slf4j.nop_1.6.1
	              Master=13
16	  ACTIVE      com.springsource.ch.qos.logback.core_0.9.24
17	  ACTIVE      com.springsource.ch.qos.logback.classic_0.9.24

osgi> install file:bundles/spring-demo/spring-dm-demo-producer-1.0.jar
Bundle id is 18

osgi> start 18 

osgi> install file:bundles/spring-demo/spring-dm-demo-consumer-1.0.jar
Bundle id is 19

osgi> start 19

osgi> Authorization for foo:bar : false
Authorization for foo:secret : true

osgi> ss

Framework is launched.

id	  State       Bundle
0	  ACTIVE      org.eclipse.osgi_3.6.1.R36x_v20100806
...
18	  ACTIVE      demo.springdm.spring-dm-demo-producer_1.0.0
19	  ACTIVE      demo.springdm.spring-dm-demo-consumer_1.0.0
{% endhighlight %}

Działa. Pierwsza integracja Spring'a z OSGi za pomocą frameworka Spring Dynamic Modules
gotowa.

## Podsumowanie

Platforma OSGi ma na celu wypełnienie luki jaka istnieje w Javie dotyczącej wsparcia dla
aplikacji wielomodułowych. To co oferuje nam Java, czyli różne typy archiwów (JAR, WAR czy EAR)
okazują się niewystarczające. OSGi jasno definiuje czym jest moduł, jaki jest jego cykl życia
oraz izoluje moduły od siebie udostępniając tylko te usługi, które trzeba.

Spring Dynamic Modules to framework, który pozwala instalować komponenty Springo'we w kontenerze
OSGi a także używać dostępnych komponentów i wstrzykiwać je do komponentów Springa. Całość
dzieje się jedynie z pomocą odrobiny deklaracji w plikach XML-owych.

Działający kod aplikacji powstałej do tego posta można znaleźć pod adresem:
[https://github.com/michalorman/michalorman.github.com/tree/master/przyklady/spring-dm-czyli-spring-i-osgi](https://github.com/michalorman/michalorman.github.com/tree/master/przyklady/spring-dm-czyli-spring-i-osgi)

Znajduje się tam także Equinox skonfigurowany pod Spring DM 2.0.0.M1 oraz Spring'a 3.0.5.RELEASE
(a nie 3.0.0.RC1 z jaką domyślnie jest Spring DM).

[http://michalorman.pl/blog/2010/12/spring-dm-czyli-spring-i-osgi/](http://michalorman.pl/blog/2010/12/spring-dm-czyli-spring-i-osgi/)

{% include bio_michal_orman.html %}