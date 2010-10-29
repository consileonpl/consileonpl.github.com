---
layout: post
title: Dostrajanie warstwy ORM w projekcie wielomodułowym
categories: [orm]
---
Częstym jak sądzę przypadkiem w średnich i większych projektach informatycznych jest współdzielenie modelu domeny przez kilka niezależnych aplikacji. 
Takimi aplikacjami mogą być np.: web portal dla klientów, wewnętrzna aplikacja administracyjna, moduł raportujący.

Wspólne dane, z których korzystają aplikacje, nie są wcale powodem do tworzenia wspólnego modelu domeny. Polecam na ten temat prezentację [DDD - putting model to work](http://www.infoq.com/presentations/model-to-work-evans), której którkie podsumowanie można znaleźć tutaj: [IT-Researches Blog](http://it-researches.blogspot.com/2009/03/eric-evans-ddd-putting-model-to-work.html).

Zakładając jednak, że mamy jeden model (co jest częstą praktyką) pojawia się kwestia współdzielenia modelu ORM zdefiniowanego
jako mapowania obiektów do tabel w bazie relacyjnej. 
Jak się bowiem często okazuje wymagania poszczególnych aplikacji w tym zakresie są różne.
Dotyczyć to może takich kwestii jak sposób inicjalizacji pól encji (lazy vs egear fetching). 

Zagadnienie, jakie dokładnie ustawienia ORM warto dostrajać i kiedy, odłożę na później. 
W tym wpisie chciałbym przedstawić w jaki sposób skonfigurować projekt aby umożliwić poszczególnym aplikacjom dostosowanie warstwy ORM do ich potrzeb oraz jakie problemy 
przy tworzeniu takiej konfiguracji napotkałem.

## Konfiguracja projektu
Wykorzystywane technologie:

 - Maven
 - Spring
 - Hibernate

Mamy zatem projekt wielomodułowy, w skład którego wchodzą poszczególne aplikacje oraz następujące moduły współdzielone:

 - model domeny - (encje/domain objects)
 - dao - konfiguracja dostępu do bazy danych, klasy dao


### Moduł - model domeny

Model domeny stanowią encje (obiekty POJO) opisane adnotacjami Hiberanate Annotations. 
Adnotacje są dobrym sposobem na zdefiniowanie domyślnych mapowań ORM. Poszczególne aplikacje mają bowiem możliwość nadpisania domyślnych mapowań przy użyciu plików konfiguracyjnych xml (hbm.xml). Zwracam uwagę na to, że Hibernate Annotations bazują na specyfikacji **JPA** jednak nie wymagają użycia modułu JPA (dostarczającego interfejs javax.persistence.EntityManager).

### Moduł - dao

Konfigurację SessionFactory tworzymy wykorzystując Spring-ową fabrykę wspierającą Hibernate Annotations.
{% highlight xml %}
	<bean id="sessionFactory" class="org.springframework.orm.hibernate3.annotation.AnnotationSessionFactoryBean" 
		  p:dataSource-ref="dataSource">
		<property name="annotatedClasses">
			<list>
                <value>com.example.domain.FeedCategory</value>
				[...]
			</list>
		</property>
        <property name="mappingDirectoryLocations">
            <list>
                <value>classpath:orm/custom-mappings/</value>
            </list>
        </property>
		[...]
	</bean>
{% endhighlight %}
W parametrze ``annotatedClasses`` podajemy listę naszych encji. Co warte uwagi Spring umożliwia wskazanie pakietu który będzie automatycznie skanowany w poszukiwaniu encji (parametr ``packagesToScan``).
 
Nas jednak bardziej interesuje parametr ``mappingDirectoryLocations``. Wskażemy w nim katalog, z którego załadowane zostaną pliki ``hbm.xml``. 
W ten sposób umożliwiamy aplikacjom dostarczenie własnych mapowań ORM.

## Przykład
Uporawszy się z konfiguracją, przetestujmy jak działa nadpisywanie mapowań na konkretnym przykładzie.

Mamy zatem klasę **FeedCategory**, która dziedziczy po **BaseEntity** i zawiera listę podkategorii (pole ``subCategories``).

{% highlight java %}

@MappedSuperclass
public abstract class BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "CREATED_DATE")
    private Date createdDate;
	
	[...]
}

@Entity
public class FeedCategory extends BaseEntity {
	[...]
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "PARENT_ID")
    private FeedCategory parent;

    @OneToMany(mappedBy = "parent", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private List<FeedCategory> subCategories = new ArrayList<FeedCategory>();
	[...]
}

{% endhighlight %}

Jak widzimy, domyślnie Hibernate załaduje listę podkategorii leniwie (w momencie użycia) co zostało zdefiniowane ustawieniem ``fetch = FetchType.LAZY``.
Załóżmy jednak, że chcemy aby w naszej aplikacji podkategorie były ładowane "chciwie" (ang. eagerly) a więc zaraz po załadowaniu obiektu głównego.

W tym celu tworzymy w module konkretnej aplikacji katalog __orm/custom-mappings__, który wskazaliśmy w konfiguracji SessionFactory (w projekcie maven-owym umieszczamy ten katalog w gałęzi src/main/resources) i umieszczamy w nim plik feedCategory.hbm.xml:

{% highlight xml %}

<hibernate-mapping package="com.example">
	<class name="FeedCategory">
		<id name="id" />
		<property name="createdDate" column="CREATED_DATE" type="date"/>
		[...]		
		<bag name="subCategories" inverse="true" lazy="false">
			<key column="PARENT_ID" />
			<one-to-many entity-name="com.example.FeedCategory"/>
		</bag>
    </class>
</hibernate-mapping>

{% endhighlight %}

Tym razem ustawienie sposobu pobierania listy kategorii definiujemy atrybutem **lazy="false"** (czyli chciwie).

## Problem
Napotykamy problem, który wydawało się nie powinien zaistnieć. Mianowicie adnotacja **@MappedSuperclass** nie ma odpowiednika w konfiguracji mapowań Hibernate.

Obejściem tego problemu jest zdefiniowanie pól z klasy BaseEntity w pliku mapowań klasy FeedCategory. Jednak jest to niewygodne. Wyobraźmy sobie bowiem, że nadpisujemy 10 klas po czym dokonujemy zmiany w domyślnej konfiguracji BaseEntity... Będziemy musieli tę zmianę wprowadzić również w 10 plikach hbm.xml..
Drugim problemem (który być może wynika z pierwszego - temat nie do końca sprawdzony) jest konieczność zdefiniowania wszystkich pól klasy FeedCategory. 
Nie można zatem nadpisać tylko zmienionego elementu konfiguracji, trzeba zdefiniować całe mapowanie na nowo.

##Rozwiązanie
Rozwiązaniem powyższych niedogodności jest skonfigurowanie Hibernate jako dostawcy JPA i zastąpienie mapowań w formacie hbm.xml mapowaniami xml w standarcie JPA.
 
W tym celu konfigurację SessionFactory zastępujemy konfiguracją EntityManagerFactory ponownie korzystając z udogodnień jakie oferuje Spring, tym razem dla JPA: 

{% highlight xml %}
	<bean id="entityManagerFactory"	class="org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean"
		p:persistence-xml-location="classpath:META-INF/persistence.xml"	p:data-source-ref="dataSource">
		[...]		
		<property name="persistenceUnitPostProcessors">
			<list>
				<bean class="com.example.spring.jpa.DefaultPostprocessor" />
			</list>
		</property>
	</bean>
{% endhighlight %}

Szczegółowe ustawienia dostarczamy w pliku **persistence.xml**, w którym również specyfikujemy listę naszych encji 
(ustawiając parametr ``hibernate.archive.autodetection`` nakazujemy Hibernate Entity Manager aby wyszukał encje w określonych lokalizacjach, 
więcej informacji na ten temat tutaj: [Do I need class elements in persistence.xml](http://stackoverflow.com/questions/1780341/do-i-need-class-elements-in-persistence-xml)):

{% highlight xml %}
<persistence version="1.0" xmlns="http://java.sun.com/xml/ns/persistence" [...]>
        <persistence-unit>
				<class>com.example.domain.FeedCategory</class>
				[...]
         </persistence-unit>
</persistence>
{% endhighlight %}

Pozostaje skonfigurować wykrywanie mapowań xml dostarczonych przez poszczególne aplikacje. 
Niestety w przypadku JPA nie mamy analogicznego do ``mappingDirectoryLocations`` parametru zarówno na poziomie konfiguracji w pliku persistence.xml jak i udogodnień Spring-a. 
Rozwiązaniem jest przekazanie do LocalContainerEntityManagerFactoryBean klasy implementującej interfejs 
``PersistenceUnitPostProcessor``. Postprocesor ma możliwość modyfikowanie opcji konfiguracyjnych, w tym dodanie mapowań xml.

{% highlight java %}
public class DefaultPostprocessor implements PersistenceUnitPostProcessor, ResourceLoaderAware {

	private ResourceLoader resourceLoader;

	@Override
	public void postProcessPersistenceUnitInfo(MutablePersistenceUnitInfo pui) {
		Resource resource = resourceLoader.getResource("classpath:orm.xml");
		if (resource.exists()) {
			pui.addMappingFileName("orm.xml");
		}
		
	}

	@Override
	public void setResourceLoader(ResourceLoader resourceLoader) {
		this.resourceLoader = resourceLoader;
	}
}
{% endhighlight %}

Możemy zatem w aplikacji nadpisać mapowania domyślne tworząc plik **orm.xml** (jest to standardowa nazwa pliku określona w specyfikacji JPA, aczkolwiek plików z mapowaniami może być wiele).
W naszym przykładzie plik orm.xml wygląda następująco:

{% highlight xml %}
	<entity-mappings xmlns="http://java.sun.com/xml/ns/persistence/orm" [...]>

		<entity class="com.example.domain.FeedCategory">
			<attributes>
				<one-to-many name="subCategories" target-entity="com.example.domain.FeedCategory" mapped-by="parent" fetch="LAZY"/>
			</attributes>
		</entity>

	</entity-mappings>
{% endhighlight %}

Jak widać, ostatecznie udało się osiągnąć cel czyli nadpisać tylko to co wymagało dostosowania.
Niestety wymagało to zmiany konfiguracji projektu w celu integracji standardu JPA.

[http://pkaczor.blogspot.com/2010/10/dostrajanie-warstwy-orm-w-projekcie.html](http://pkaczor.blogspot.com/2010/10/dostrajanie-warstwy-orm-w-projekcie.html)

{% include bio_pawel_kaczor.html %}
