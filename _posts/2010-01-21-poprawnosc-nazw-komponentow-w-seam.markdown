---
layout: post
title: Poprawność nazw komponentów w Seam
description: Jakie są ograniczenia co do poprawnej nazwy komponentu w Seam-ie
categories: [seam, java]
---
Ostatnio jakoś tak natchnęło mnie na eksperymentowanie (związane również z wymyślaniem pytań na [JavaBlackBelt](http://www.javablackbelt.com/Home.wwa)). Zastanowiło mnie jak właściwie powinna wyglądać prawidłowa nazwa komponentu [Seam](http://seamframework.org/). Czy są jakieś ograniczenia co do znaków? Intuicja podpowiada mi, że są (podpowiada nawet jakie to mogą być ograniczenia), jednakże moja intuicja potrafi być zawodna toteż postanowiłem przeglądnąć co na ten temat mówi dokumentacja.

Zacząłem od przeglądu dokumentacji online. Oficjalna [strona](http://docs.jboss.com/seam/latest/reference/en-US/html/concepts.html#d0e3886), mówi mi tylko, że nazwę komponentu mogę nadać za pomocą adnotacji `@Name`. No to zerkam do jej [javadoc-a](http://docs.jboss.org/seam/2.2.0.GA/api/). Tutaj informacji jeszcze mniej. Dowiadujemy się tylko, że adnotacja ta nadaje nazwę komponentu, ale w jakim celu, jak powinna wyglądać prawidłowa nazwa i do czego ją wykorzystywać ani słowa!

No dobra, na dokumentacji online nikt nie zarabia, toteż nikt się nie stara aby była porządna. Przejdźmy zatem do książek. W "Seam in Action" również dowiaduję się, że nazwy nadaje się za pomocą adnotacji `@Name` a dodatkowo wymienione są komponenty, które mogą posiadać nazwę. Idziemy dalej, "Seam Framework - Experience the Evolution of Java EE" bez skutku, "Beginning JBoss Seam - From Novice to Profiessional" i też mi się nie udało.

No to skoro się nie udało znaleźć w dokumentacji przejdźmy do eksperymentów metodą doktora Macajewa. Szybka konfiguracja projektu w `seam-gen` i dodaję taką klasę:

{% highlight java %}
@Name("!@#$%^*()component")
public class TestComponent {
}
{% endhighlight %}

Deploy, uruchamianie serwera i dostaję:

{% highlight java %}
java.lang.RuntimeException: Could not create Component: !@#$%^*()component
        at org.jboss.seam.init.Initialization.addComponent(Initialization.java:1202)
        at org.jboss.seam.init.Initialization.installComponents(Initialization.java:1118)
        at org.jboss.seam.init.Initialization.init(Initialization.java:733)
        at org.jboss.seam.servlet.SeamListener.contextInitialized(SeamListener.java:36)
        ...
Caused by: java.lang.IllegalStateException: not a valid Seam component name: !@#$%^*()component
        at org.jboss.seam.Component.checkName(Component.java:266)
        at org.jboss.seam.Component.<init>(Component.java:220)
        at org.jboss.seam.Component.<init>(Component.java:205)
        at org.jboss.seam.init.Initialization.addComponent(Initialization.java:1186)
        ... 72 more
{% endhighlight %}

Także widać, że Seam jawnie sprawdza poprawność nazwy komponentu (metoda `checkName` klasy `Component`) ale dlaczego nie jest nigdzie udokumentowane jaka powinna być prawidłowa nazwa?!

Rzućmy okiem na metodę sprawdzającą poprawność nazwy:

{% highlight java %}
private void checkName()
{
   for ( char c: name.toCharArray() )
   {
      if ( !Character.isJavaIdentifierPart(c) && c!='.' )
      {
         throw new IllegalStateException("not a valid Seam component name: " + name);
      }
   }
}
{% endhighlight %}

Jak widać poprawna nazwa komponentu to taka, która składa się ze znaków dozwolonych dla identyfikatorów w Javie plus znak '.' (kropka). Szybko test dla klasy:

{% highlight java %}
@Name("$component_123")
public class TestComponent {
}
{% endhighlight %}

I działa. Czy naprawdę tak ciężko byłoby jednym zdaniem podsumować jak powinna wyglądać prawidłowa nazwa komponentu chociażby w javadoc-u?

Niestety dokumentacyjne niedbalstwo jest wszechobecne w frameworkach spod stajni ludzi odpowiedzialnych za Seama. Wystarczy sobie przeglądnąć dokumentację Hibernate'a. Aż czasami człowieka krew zalewa. Do tego nie ma takiego poręcznego narzędzia jak `irb` w Ruby aby można było sobie coś szybko sprawdzić. Całe szczęście, że prostą aplikację w Seam można sobie szybko wygenerować, ale problem ten dotyczy też innych frameworków, dla których stworzenie aplikacji nie jest takie szybkie.

Ja już się przyzwyczaiłem, że klasy i metody w Seam są bardzo słabo (o ile w ogóle) udokumentowane, jednakże źle to świadczy o twórcach tego frameworka. Jako coś co ma być wykorzystywane głównie ze względu na swoje API nie może posiadać nieudokumentowanego API!
  

Ref: [http://michalorman.pl/blog/2010/01/poprawnosc-nazw-komponentow-w-seam/](http://michalorman.pl/blog/2010/01/poprawnosc-nazw-komponentow-w-seam/)

{% include bio_michal_orman.html %}