---
layout: post
title: ZK - tworzenie aplikacji sterowanej zdarzeniami
categories: [zk, framework]
---
Większość frameworków/bibliotek odpowiedzialnych za obsługę interfejsu użytkownika definiuje zdarzenia i dostarcza szereg mechanizmów służących do przechwytywania i przetwarzania zdarzeń.
Komponenty GUI oferowane przez te biblioteki specyfikują jakie zdarzenia i kiedy są przez nie generowane oraz na jakie zdarzenia i w jakim celu nasłuchują. Zdarzenia to nie tylko akcje wykonane przez użytkownika takie jak kliknięcie myszką na przycisk, wybór elementu na liście czy naciśnięcie klawisza Enter w polu tekstowym. Komponenty używają bowiem zdarzeń również do komunikacji między sobą dzięki czemu powiązania między komponentami są luźne. Jest to jeden z ważnych czynników  zwiększających elastyczność architektury systemu. 

Dlaczego zatem nie wprowadzić zdarzeń do warstwy logiki biznesowej? Nie jest to nowa koncepcja, aczkolwiek rzadko spotykana w typowych aplikacjach biznesowych. Wynika to m.in. z braku odpowiedniego wsparcia ze strony frameworków aplikacyjnych. Z nadejściem JEE 6 sytuacja może się zmienić. Specyfikacja CDI definiuje prosty w użyciu model generowania i odbierania zdarzeń (podobny model od dawna oferuje Seam). Model ten jest uniwersalny i może mieć zastosowanie w różnych obszarach/warstwach aplikacji. 
W poniższym artykule zaprezentuję rozwiązanie jakie w tym zakresie oferuje [framework ZK](http://www.zkoss.org). 

## Przykładowa aplikacja

W typowej aplikacji biznesowej mamy zwykle do zaimplementowania obsługę grupy operacji określanej skrótem CRUD (tworzenie, zmiana, usuwanie) wykonywanych przez użytkownika na różnych obiektach biznesowych. W naszej przykładowej aplikacji zamodelujmy obsługę ról użytkowników. Mamy zatem ekran z listą ról oraz ekran edycji/tworzenia roli wyświetlany w oknie dialogowym. Rysunki poniżej.

## Zdarzenie biznesowe

Zdarzenie w ZK definiowane jest jako obiekt klasy **Event** posiadający nazwę (name). Dodatkowo zdarzenie może mieć przypisany komponent docelowy (target) oraz dowolny obiekt z danymi (data).

Zdefiniujmy zatem zdarzenia biznesowe, które chcielibyśmy obsłużyć w naszej aplikacji:

 - onEdit - użytkownik wykonał akcję mającą na celu przejście do trybu edycji wybranego obiektu biznesowego

 - onAdd - użytkownik wykonał akcję mającą na celu przejście do trybu edycji nowego obiektu biznesowego

 - onDelete - użytkownik wykonał akcję mającą na celu usunięcie wybranego obiektu biznesowego

 - onSave - użytkownik wykonał akcję mającą na celu zapisanie zmian (modyfikacja bądź utworzenie obiektu biznesowego)

## Przypisanie zdarzenia biznesowego do akcji użytkownika

W naszej aplikacji edycja następuje po kliknięciu na element listy, a tworzenie elementu po naciśnięciu przycisku znajdującego się pod listą. W obu przypadkach nastąpi wyświetlenie okna edycji (popup).

{% highlight xml %}
<window id="windowRoleList" apply="${roleListCtrl}">
  <listbox model="@{controller.listModel}" selectedItem="@{controller.selected}">
   <listitem self="@{each='role'}">
    <listcell>
      <a label="@{role.name}" forward="onClick=onEdit"/>
    </listcell>
    <listcell label="@{role.description}" />
   </listitem>
  </listbox>
  <toolbar>
   <button id="btnAdd" forward="onClick=onAdd"/>
   <button id="btnDelete" forward="onClick=onDelete"/>
  </toolbar>
 </window>
{% endhighlight %}

Zwróćmy uwagę na atrybuty **forward** zdefiniowane dla linku (element a w wierszu listy) i przycisku pod listą (element button).  
W atrybucie forward podajemy nazwę zdarzenia jakie zostanie propagowane w górę drzewa komponentów. Propagowanie odbywa się poprzez utworzenie nowego zdarzenia (o nazwie podanej po znaku równości) zawierającego zdarzenie źródłowe (o nazwie podanej przed znakiem równości). W naszym przypadku zdarzeniem źródłowym jest zdarzenie systemowe ``onClick`` (kliknięcie na przycisk/link). W przypadku nie podania zdarzenia źródłowego, przyjmowane jest domyślne, różne w zależności od komponentu dla jakiego specyfikujemy atrybut forward.
W przypadku linka i przycisku jest to zdarzenie ``onClick``. Zatem oba zapisy są tożsame: 

{% highlight xml %}
<button forward="onClick=onAdd"/>
<button forward="onAdd"/>
{% endhighlight %}

Zdefiniowaliśmy zatem, po jakiej akcji użytkownika nastąpi określone zdarzenie biznesowe. 
Odseparowaliśmy tym samym logikę interfejsu użytkownika od logiki biznesowej. Gdybyśmy dla innego obiektu biznesowego edycję chcieli przeprowadzić nie w osobnym oknie, lecz w tym samym, w którym znajduje się lista wyboru, zdarzenie ``onEdit`` moglibyśmy zdefiniować jako następstwo wyboru elementu na liście:   

{% highlight xml %}
<listbox model="@{controller.listModel}" selectedItem="@{controller.selected}" 
   forward="onSelect=onEdit"/>

{% endhighlight %}

W obu przypadkach logika obsługi zdarzenia ``onEdit`` będzie taka sama.
Przyjrzyjmy się zatem jak obsłużyć zdarzenie w kodzie aplikacji.

## Obsługa zdarzenia

Zdarzenie propagowane jest aż do komponentu okna (window) i następnie zostaje przekazane do kontrolera podpiętego pod to okno (kontroler definiujemy atrybutem <b>apply</b>). W naszym przypadku kontroler jest bean-em zarządzanym przez Springa o nazwie ``roleListCtrl`` (użycie Spring-a jest opcjonalne).

Kontroler musi zdefiniować metodę odpowiadającą nazwie zdarzenia:

{% highlight java %}
public void onEdit(Event event);
{% endhighlight %}


Wiemy zatem, w jaki sposób nasze zdarzenie biznesowe może być utworzone i obsłużone w wyniku akcji podjętej przez użytkownika.
Spyta ktoś, czym to rozwiązanie różni się od klasycznego podejścia używanego w innych frameworkach np. Seam, gdzie możemy analogicznie wywołać metodę w kontrolerze: 

{% highlight xml %}
<button action="#{controller.onEdit()}"/>
{% endhighlight %}

Rozpatrzmy różnice między oboma podejściami z punktu widzenia interfejsu wywołania/obsługi komunikatu :

**Seam**: w metodzie możemy przekazywać dowolną ilość argumentów, dowolnego typu.

**ZK**: W zdarzeniu możemy przekazać jeden obiekt danych (możemy np. przekazać wybraną rolę:  ``forward=onEdit(role)``) . Typem danych jest zawsze Object. Porównując zatem z wywołaniem metody, mamy ograniczoną ilość argumentów i konieczność rzutowania typu po stronie kontrolera. Zwykle jednak nie ma konieczności przekazywania większej liczby argumentów (w naszym przykładzie nie musimy przekazywać roli w zdarzeniu, gdyż framework potrafi wstrzyknąć do kontrolera wybraną rolę automatycznie).
Podkreślić należy, że oba problemy wynikają z ograniczeń jakie niesie ze sobą propagowanie zdarzeń przy przy pomocy atrybutu forward. Nie istnieje tutaj możliwość stworzenia własnej klasy zdarzenia. Gdy wysyłamy zdarzenie w kodzie aplikacji (przykład później),problemy powyższe nie istnieją.

Przejdźmy w końcu do przykładów, gdzie zdarzenia zaczynają pokazywać swoją moc:)

## Zdarzenia w akcji

W przypadku gdy wyświetlamy kilka okien na stronie możemy używać zdarzeń do komunikacji między oknami sterując w ten sposób logiką aplikacji.

Dodajmy na naszej stronie z listą ról nowy panel z listą użytkowników. Lista ról niech wyświetla tylko role dla wybranego użytkownika (z możliwością ich edycji). Obie listy umieszczamy w oddzielnych oknach (komponentach window) dzięki czemu obie listy możemy obsługiwać oddzielnymi kontrolerami (w obu oknach chcemy obsłużyć logikę CRUD). 
Odświeżenie listy ról po wybraniu użytkownika obsługujemy następująco:

{% highlight java %}
//Kontroler użytkowników

public void onSelect(Event event) {
 	//inform role list window on selection change
 	Component roleListWindow = self.getFellow("windowRoleList");
	Events.postEvent(new Event("onUserSelected", roleListWindow, getSelected()));
}
{% endhighlight %}
{% highlight java %}
//Kontroler ról

public void onUserSelected(Event event) {
	selectedUser = (User)event.getData();
	refreshList();
}
{% endhighlight %}

Dzięki temu, że zdefiniowaliśmy zdarzenie ``onUserSelected``,  możemy zarejestrować słuchaczy obserwujących to zdarzenia w celu zaimplementowania dodatkowej logiki. Jako przykład wykorzystam wbudowany w ZK mechanizm sterowania bindowaniem danych. Co to jest bindowanie? Jest to możliwość bezpośredniego połączenia warstwy modelu (danych) z kontrolkami wyświetlającymi/modyfikującymi te dane. W ZK bindowanie może obejmować dowolne właściwości kontrolek np. stan kontrolki (czy kontrolka jest aktywna czy nie (enabled/disabled)). 
Dodajmy zatem wymaganie w naszej aplikacji aby usunięcie roli było możliwe tylko dla użytkownika nowo utworzonego (dla którego pole registered = false). Musimy zatem przy zmianie selekcji użytkownika deaktywować bądź aktywować przycisk Delete pod listą ról.
Korzystając z możliwości mechanizmu bindowania ZK konfigurujemy właściwość ``disabled`` dla przycisku Delete:

{% highlight xml %}
<button id="btnDelete" forward="onDelete"
	    disabled="@{controller.selectedUser.registered, load-after='windowRoleList.onUserSelected'}"/>
{% endhighlight %}

Użycie **@** w wyrażeniu oznacza zastosowanie bindingu. W naszym przypadku odczytujemy pole ``registered`` z obiektu użytkownika przekazanego uprzednio do kontrolera (patrz kod wyżej). Za pomocą parametru ``load-after``, wskazujemy zdarzenie, po nastąpieniu którego nastąpi odświeżenie przycisku (odczytanie danych z modelu). Framework automatycznie zarejestruje odpowiedniego listenera w komponencie naszego okna nasłuchującego na zdarzenie ``onUserSelected``.

Zauważmy co zyskujemy. Kod obsługujący zdarzenie onUserSelected jest czysty. Modyfikujemy w nim tylko stan modelu, czyli ustawiamy zmienną selectedUser i odświeżamy listę ról (model). Zarówno przy odświeżaniu listy ról jak i odświeżaniu przycisku na stronie zostanie odczytane pole selectedUser. Kontroler nie musi wiedzieć kiedy odświeżyć przycisk, nie musi nawet wiedzieć o jego istnieniu.

## Zdarzenia globalne

Przedstawione dotychczas zdarzenia były wysyłane do konkretnego komponentu. Nie zawsze jest to pożądane. Jedną z podstawowych cech architektur sterowanych zdarzeniami jest możliwość niezależnego wysyłania i odbierania zdarzeń. Emitent zdarzenia nie musi znać odbiorców. Odbiorca nie musi wiedzieć skąd zdarzenie pochodzi. Jak tę funkcjonalność zrealizować w ZK pokaże znowu na konkretnym przykładzie. 
Dodajmy na górze naszej strony panel zawierający nazwę zalogowanego użytkownika. Pojawia się kwestia odświeżenia zawartości panelu w momencie modyfikacji nazwy aktualnie zalogowanego użytkownika. W kontrolerze obsługującym okno edycji użytkownika implementujemy obsługę zdarzenia ``onSave``. 

{% highlight java %}
public void onSave(Event event) {
	//save user
	....
	//inform potential listeners
	EventQueue lookup = EventQueues.lookup("QUEUE_GLOBAL", true);
	lookup.publish(new UserChangedEvent("onUserChanged", user));
}
{% endhighlight %}


Wysyłamy zatem zdarzenie ``onUserChanged`` bez adresata do kolejki o zdefiniowanej przez nas nazwie ``QUEUE_GLOBAL``.
Zauważmy, że tym razem zdefiniowaliśmy własną klasę zdarzenia (``UserChangedEvent``), w której przekazujemy obiekt użytkownika. Standardowo, rejestracja w kontrolerze słuchacza zdarzeń z tej kolejki wygląda w następujący sposób: 

{% highlight java %}
//kontroler nagłówka
 public void onCreate(Event event) {
  EventQueues.lookup("QUEUE_GLOBAL", EventQueues.DESKTOP, true)
   .subscribe(new EventListener() {
    @Override
    public void onEvent(Event event) throws Exception {
     //process event 
    }
   });
 }
{% endhighlight %}

Rejestrację można uprościć i jednocześnie ułatwić kontrolerowi obsługę zdarzenia tworząc klasę pośrednicząca w odbieraniu i przekazywaniu zdarzeń do wybranego przez nas komponentu (nazwijmy ją ``EventsManager``):

{% highlight java %}
public class EventsManager {
 public static void subscribe(String queue, final Component component) {
  EventQueues.lookup(queue, EventQueues.DESKTOP, true)
   .subscribe(new EventListener() {
    @Override
    public void onEvent(Event event) throws Exception {
     Events.sendEvent(component, event);
    }
   });
 }
}
{% endhighlight %}


Teraz w kontrolerze nagłówka możemy w sposób standardowy zaimplementować obsługę zdarzenia ``onUserChanged``.

{% highlight java %}
// kontroler nagłówka

public void onCreate(Event event) {
  //register self (window component) as listener of events from QUEUE_GLOBAL
  EventsManager.subscribe("QUEUE_GLOBAL", self);
}

public void onUserChanged(UserChangedEvent event) {
  if (event.getUser().eqauls(getUserWorkspace().getLoggedInUser()) {
   //refresh component displaying user name
   ...   
  }
}
{% endhighlight %}

Używając zdarzeń globalnych uwalniamy emitenta zdarzenia od konieczności znajdowania komponentu docelowego. Jednocześnie uwalniamy odbiorcę od rejestracji nasłuchiwania w konkretnym komponencie. Wystarczy, że obie strony uzgodnią kanał (kolejkę) komunikacji. 
Zdarzenia globalne domyślnie wysyłane i odbierane są w kontekście strony przeglądarki (desktop-level).  
ZK pozwala również funkcjonować zdarzeniom w kontekście całej aplikacji. Dzięki temu strona może zostać odświeżona pomimo braku akcji ze strony zalogowanego użytkownika (np. na skutek operacji wykonanej przez scheduler-a uruchomionego na serwerze). Umożliwia to technologia **Push Server**, oferowana wewnątrz ZK.

[http://pkaczor.blogspot.com/2010/10/zk-tworzenie-aplikacji-sterowanej.html](http://pkaczor.blogspot.com/2010/10/zk-tworzenie-aplikacji-sterowanej.html)

{% include bio_pawel_kaczor.html %}
