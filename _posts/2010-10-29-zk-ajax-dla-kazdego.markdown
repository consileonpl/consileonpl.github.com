---
layout: post
title: ZK - Ajax dla każdego
categories: [zk, framework, mvc]
---
ZK opiera swoją architekturę na technologii Ajax. Komunikacja klient-serwer z wykorzystaniem Ajax-a w całości realizowana jest przez silnik ZK  i jest niewidoczna/przezroczysta z punktu widzenia aplikacji używającej ZK. To framework decyduje kiedy wysłać żądanie do serwera oraz kiedy i jakie elementy strony odświeżyć. Dodając do tego warstwę komponentów i zdarzeń, którą dostarcza ZK, otrzymujemy interfejs programistyczny znany z frameworków desktopowych (np. Swing). Mamy zatem obiekt kontrolera, którego metody wywoływane są w wyniku akcji użytkownika oraz komponenty GUI, którymi kontroler steruje. Kontroler może bezpośrednio wywoływać metody komponentów, bądź modyfikować obiekty modelu, z których komponenty GUI  korzystają. Zarówno komponenty GUI jaki i obiekty modelu definiują zdarzenia jakie wysyłają w wyniku akcji użytkownika bądź wykonania określonego kodu.
Tworzenie aplikacji w ZK nie różni się zatem znacząco od tworzenia aplikacji desktopowej. Co więcej, ZK oferuje nowoczesne rozwiązania niedostępne w starszych technologiach takich jak Swing (np. wbudowany data binding, język tworzenia interfejsu użytkownika oparty na [XUL](https://developer.mozilla.org/En/XUL). 

Tyle teorii, zobaczmy jak wygląda kod aplikacji opartej o ZK analizując konkretne przykłady.  

## Ajax w akcji

{% highlight java %}
class PersonListCtrl extends GenericForwardComposer {

 //GUI components autowired by ZK
 private Listbox personsList;
 private Textbox firstName;
 private Combobox color;
 private Checkbox married;

 public void onAddPerson(Event event) {
  Person personBean = new Person();
  personBean.setFirstname(firstName.getValue());
  personBean.setColor(color.getValue());
  personBean.setMarried(married.isChecked());
  //save person to database and add it to the listbox
  ...
  addPersonRecord(personBean);
 }

 public void addPersonRecord(Person person) {
  Listitem newPersonItem = new Listitem(person.getName());
  List items = Listbox.geItems();
  items.add(newPersonItem);
  ...
 }
}
{% endhighlight %}

W powyższym przykładzie kontroler w metodzie obsługującej zdarzenie ``onAddPerson`` tworzy obiekt osoby (obiekt klasy Person) i wypełnia go danymi wprowadzonymi na stronie przez użytkownika. Dane te odczytywane są bezpośrednio z komponentów GUI (textbox, combobox, checkbox). ZK umożliwia wstrzyknięcie komponentów GUI do kontrolera na podstawie zgodności nazwy zmiennej w kontrolerze i atrybutu id komponentu GUI.
Po zapisaniu obiektu osoby do bazy, wywoływana jest metoda ``addPersonRecord``, w której nazwa osoby (String) dodawana jest do listy wyświetlanej na ekranie (komponent ``personsList`` klasy Listbox). Rezultatem modyfikacji komponentu Listbox będzie odświeżenie listy na stronie przeglądarki. Dzięki technologii Ajax odświeżony zostanie tylko fragment strony zawierający listę osób. 
Jak widać, mechanizm odświeżania działa automatycznie i nie wymaga żadnej ingerencji ze strony obiektu kontrolera.

## Inteligentny model

Komponenty GUI przeznaczone do wyświetlania/edycji danych (listbox, combobox, grid, tree) mogą być powiązane z zewnętrznym obiektem modelu przechowującym dane. Rezultatem użycia modelu jest odseparowanie logiki związanej z tworzeniem/modyfikacją danych od logiki ich wyświetlania (zgodnie z wzorcem **MVC**). Dla komponentu Listbox przewidziano interfejs ListModel i dostarczono wiele implementacji tego interfejsu przeznaczonych do obsługi różnych typów kolekcji np. ListModelArray, ListModelList, ListModelSet, ListModelMap. Po przypisaniu modelu do listy, kontroler nie musi odwoływać się bezpośrednio do komponentu listy. Wszelkie operacje (dodanie, usunięcie elementu, zmiana selekcji) dokonuje na obiekcie modelu:

{% highlight java %}
public void addPersonRecord(Person person) {
  ListModelList model = getModel();
  model.add(person)
}
{% endhighlight %}

Model w momencie modyfikacji (dodanie/usunięcie elementu) generuje zdarzenie, w którym zawarta jest szczegółowa informacja o zaistniałej zmianie. Komponent listy posiada obiekt nasłuchujący na zdarzenia pochodzące z modelu, dzięki czemu jest informowany o tym kiedy i w jakim zakresie musi dokonać odświeżenia swojego stanu. Modyfikacje w warstwie modelu są zatem automatycznie odzwierciedlane na stronie (w przeglądarce).  

## Widok

Logiką wyświetlenia danych dostarczonych przez model zajmuje się **renderer**. W naszym przykładzie metoda ``render``, którą musi zaimplementować renderer listy wygląda następująco:
{% highlight java %}
@Override
public void render(Listitem item, Object data) throws Exception {
  String personName = ((Person)data).getName();
  item.setLabel(personName);
}
{% endhighlight %}

Tworzenie własnego renderera zwykle nie jest jednak konieczne. Prostszą i efektywniejszą metodą jest użycie mechanizmów bindowania w kodzie strony:
{% highlight xml %}
<listbox model="@{controller.model}">
	<listitem self="@{each='person'}" label="@{person.name}"/>
</listbox>
{% endhighlight %}

Stosując **data binding** w wygodny sposób tworzymy powiązanie między komponentami GUI i danymi z modelu, które te komponenty mają wyświetlać.
W podanym przykładzie lista nie jest skomplikowana, wyświetla bowiem tylko nazwę osoby. Jednak stworzenie bardziej skomplikowanej listy (np. dodanie większej ilości kolumn, zagnieżdżenie w wierszu innych komponentów) nie stanowi najmniejszego problemu. Przykład poniżej:

{% highlight xml %}
<listbox model="@{controller.model}">
 <listitem self="@{each='person'}">
  <listcell label="@{person.name}"/>
  <listcell>
   <combobox value="@{person.color}">
    <comboitem label="Red"/>
    <comboitem label="Blue"/>
   </combobox>
  </listcell>
  <listcell>
   <checkbox checked="@{person.married}" label="Are you married?"/>
  </listcell>
 </listitem>
</listbox>
{% endhighlight %}

## MVC bez limitów

Jak już wspomniałem, przedstawiony powyżej przykład to realizacja dobrze znanego wszystkim programistom wzorca MVC (Model-View-Controller). 
Dzięki jego zastosowaniu kontroler odwołuje się tylko do modelu, a stan modelu odzwierciedlany jest po stronie widoku. 
Zauważmy, że widok może odzwierciedlać różnego rodzaju informacje biznesowe, nie tylko dane przeznaczone do wyświetlenia w tabeli, liście czy drzewie. Na przykład może to być informacja o uprawnieniach zalogowanego użytkownika. W zależności czy użytkownik posiada określone uprawnienia czy nie, stan aktywności poszczególnych kontrolek (np. przycisków akcji) może być inny. Co więcej na stan aktywności niektórych kontrolek może wpływać więcej niż jedna informacja.

Jak zrealizować zatem taką funkcjonalność nie łamiąc zasad MVC czyli nie manipulując właściwościami komponentów GUI z poziomu kontrolera?
Jak się okazuje, technologia **data binding** dostępna w ZK w zupełności wystarcza do realizacji tego typu wymagań. 

Załóżmy zatem, że wymaganiem jest aby przycisk ``Delete`` znajdujący się pod listą był aktywny tylko jeśli użytkownik posiada odpowiednie uprawnienia oraz został wybrany element na liście.
W modelu przechowywać będziemy obiekt klasy Person, który reprezentuje aktualnie wybraną z listy osobę oraz obiekt klasy AccessMode reprezentujący
tryb dostępu do danych (VIEW / EDIT) dla bieżącej strony dla aktualnie zalogowanego użytkownika. 

Dane modelu będziemy przechowywać w kontrolerze (alternatywnie moglibyśmy umieścić je w jakiejś oddzielnej klasie modelu, do której nasz widok miałby dostęp).
Mamy zatem następujące pola w kontrolerze: 

{% highlight java %}
private Person selected;
private AccessMode accessMode;
{% endhighlight %}

Tworzymy, metodę która zwróci nam informację o tym czy akcja ``Delete`` jest dostępna dla zalogowanego użytkownika:

{% highlight java %}
public boolean isDeleteDisabled() { 
  return selected == null || accessMode == AccessMode.VIEW;
}
{% endhighlight %}

W następujący sposób tworzymy przycisk ``Delete``, którego stan (enabled/disabled) chcemy powiązać z danymi znajdującymi się w modelu:

{% highlight xml %}
<button disabled="@{controller.deleteDisabled, load-after='listBox.onSelect'}" label="Delete"/>
{% endhighlight %}

Atrybutem **load-after** specyfikujemy kiedy komponent powinien odświeżyć swój stan. W naszym przypadku odświeżenie musi nastąpić  po każdorazowej zmianie selekcji na komponencie listy.  
Zwracam uwagę, iż atrybut ``load-after`` jest konieczny gdyż, ani model ani kontroler nie informują widoku o zmianie danych. 
Jest to wygodne rozwiązanie, widok aktualizuje się automatycznie w momencie wystąpienia określonego zdarzenia (Więcej o zdarzeniach w ZK napisałem w artykule [ZK - tworzenie aplikacji sterowanej zdarzeniami](http://devblog.consileon.pl/2010/10/29/zk-tworzenie-aplikacji-sterowanej-zdarzeniami)).

## Podsumowanie

Chciałbyś napisać aplikację internetową z użyciem Ajax-a i nie wiesz jak się za to zabrać? Dotychczas tworzyłeś aplikacje desktopowe i nie chcesz uczyć się wszystkiego od początku?. Framework ZK będzie dla Ciebie idealnym rozwiązaniem. Tak reklamuje się ZK i jak pokazałem w powyższym artykule, nie ma w tym wiele przesady.


[http://pkaczor.blogspot.com/2010/10/zk-ajax-dla-kazdego.html](http://pkaczor.blogspot.com/2010/10/zk-ajax-dla-kazdego.html)

{% include bio_pawel_kaczor.html %}
