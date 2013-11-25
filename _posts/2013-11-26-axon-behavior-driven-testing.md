---
layout: post
title: Axon framework - behavior driven testing
categories: [cqrs,ddd,orm,testowanie]
---

Rich domain model that emerges from application of **DDD** techniques has many advantages over anemic model but is hard (or even impossible) to deliver when modeled entities need to be stored in relational database. The reason lays deeply in the mismatch between goals of DDD and ORM models. Without going into details, the main difference is that the goal of ORM models is to enable "easy" persistence/storage and retrieval (including ad-hoc queries) of modeled objects leveraging SQL/RDBMS technology while the goal of DDD models is to decompose complex business domain into manageable pieces taking into account scalability and consistency requirements. Therefore applying both DDD and ORM modeling techniques simultaneously seems to be at least risky endeavor. But with help of Axon framework doing DDD on top of ORM is possible and may lead to better overall design.

In my previous article in this series [Axon Framework - DDD and EDA meet together](http://devblog.consileon.pl/2011/08/02/Axon-Framework-DDD-EDA-meet-together) (which I recommend to read before proceeding) I have introduced **Axon** framework and described how it enables application of DDD, CQRS, SAGA design techniques. I have also described key building blocks of DDD (Aggregates and Events) and mentioned event sourcing as "optional building block".

In this article I will show how to upgrade **JPA managed entities** (shortly **persistent entities**) that play role of Aggregate Roots to **event sourced Aggregate Roots**, so that they can be loaded from an event stream. The goal is not to replace relational database with event store (we are not ready yet to be eventual consistent ;-), but to improve quality of unit tests of ARs (remember, ARs are not simple data container, they contain business logic and thus deserve careful testing). As we will see, having possibility to construct ARs from events will let us write self-documenting unit tests expressed purely in terms of events and commands.

The main problem that needs to be addressed when modeling Aggregate Roots that are both persistent and event sourced entities is lack of consistency boundary concept in ORM model. Persistent entity can hold direct reference to any other persistent entity, while Aggregate Root can't hold direct reference to other Aggregate Root. Let's take a closer look at this problem and try to enumerate possible solutions. 

## Direct dependencies between Aggregate Roots

We can easily load persistent entity that contains graph of other persistent entities because `EntityManager` can execute any series of SQL select statements (using joins if possible) while fetching the entity. There is nothing that prevents `EntityManager` from assembling single graph containing several different persistent entities even if we modeled those entities as different Aggregate Roots. When dealing with event sourced ARs, its not the case. Event sourced repository only knows how to load single AR. Thus, to be able to load AR from event stream we need to ensure that it has no direct dependencies to other ARs. 

*Note that it is perfectly valid for AR to keep direct references to owned entities. When loading from event store, AR is responsible for recreating all owned entities.*

Of course, by definition AR should not have reference to other AR, but because our ARs are persistent entities direct references in some cases might occur because they are for some reasons convenient or even necessary. Lets think of those reasons.

### Entities need to be queried

Sometimes we model dependencies between persistent entities just to be able to perform effective queries using JPQL. The solution in this case is easy: **referencing by id**.
It turns out we can easily replace object reference to related entity with its identifier (aka primary key) by providing `targetEntity` parameter in mapping annotation (probably not very commonly used JPA feature):

{% highlight java %}
@Entity
class OrderItem {
  @ManyToOne(targetEntity = Product.class)
  private Long productId;
}
{% endhighlight %}

And that's it. Problem solved.

### Entities should not contain duplicated data

There is another reason for corrupting boundaries between ARs when modeling on top of relational database: avoiding data duplication (aka normalization). The normalization leads to complexity that can be easily noticed by looking at any "robust enough" ERD diagram (ex.: [on-line shop data model](http://www.erdiagrams.com/datamodel-online-shop-idef1x.html)). 
Complexity shows up in the code of business logic. It quickly turns out that logic of any business operation (except some simple CRUD operations) requires access to data from multiply entities.
In example below Payment Period (AR) (part of operational domain/context) implements `register payment` operation that performs check if received payment is complete (the received payment amount is equal to amount defined in Payment Plan (AR)(part of planning domain/context)) and thus accesses `paymentAmount` property of `PaymentPlanAR`:

{% highlight java %}
@Entity
public class PaymentPeriodAR {
    @ManyToOne
    private PaymentPlanAR paymentPlan;
    private BigDecimal paidAmount;

    public void registerPayment(BigDecimal paymentAmount) {
        if (isCompletePayment(paymentAmount)) {
            apply(new SuccessfulPaymentRegisteredEvent(paymentAmount));
        } else {
            apply(new FailedPaymentRegisteredEvent(paymentAmount))
        }
    }

    private boolean isCompletePayment(BigDecimal paymentAmount) {
        // return if paymentAmount == paymentPlan.paymentAmount - paidAmount
    }
}
{% endhighlight %}

We can get rid of direct relationship to payment plan AR by simply duplicating payment amount in Payment Plan and Payment Period (we would copy the value from `PaymentPlanAR` during creation of `PaymentPeriodAR`). That way we keep both ARs (contexts) separated.
So solution in that case is simple: data duplication.

**(There is also a third possibility: model the activity as business process (SAGA) that can interact with many ARs, but we will not consider this option here).**

OK, but lets assume we can't do it (duplicate data). The reason we can't could be that we want payment amount to be editable and we don't want to care about synchronization of changes between payment plan and payment period, assuming such synchronization would be necessary...

Shortly, lets assume we need to keep direct references between some ARs...

Now, we still want to be able to construct ARs from events for testing purposes. 
Fortunately, Axon framework allows registering `AggregateFactory` that can assist AR construction and initialization from event stream.

## Aggregate Factory
Lets introduce subscription plan (AR) that holds reference to subscription pool (AR):

{% highlight java %}
public class SubscriptionPlanAR extends AbstractAggregateRoot {
    @ManyToOne
    private SubscriptionPoolAR pool;
    [...]
}
{% endhighlight %}

When loading the subscription plan from jpa repository (production environment), the pool will be automatically initialized by underlying JPA provider. When loading from event sourced repository (test environment) Axon framework will check if `AggregateFactory`is registered for `SupscriptionPlanAR` type and call `AggregateFactory#doCreateAggregate` method providing **aggregate identifier** and **first event** from the event stream to create empty AR instance (AggregateFactory does not fill business properties of AR, they will be initialized when applying events from event stream).

Thus, we need to implement `SubscriptionPlanFactory` capable of instantiating `SubscriptionPlanAR` with `SubscriptionPoolAR` injected:

{% highlight java %}
public class SubscriptionPlanFactory extends AbstractAggregateFactory<SubscriptionPlanAR> {
    @Override
    protected SubscriptionPlanAR doCreateAggregate(Object aggregateIdentifier, DomainEventMessage firstEvent) {
        SubscriptionPlanCreatedEvent event = (SubscriptionPlanCreatedEvent) firstEvent.getPayload();
        return instantiate(event.getPrototype());
    }

    private SubscriptionPlanAR instantiate(SubscriptionPlanAR prototype) {
        SubscriptionPlanAR entity = new SubscriptionPlanAR();
        // use injected subscription pool repository to load the pool
        entity.setPool(getSubscriptionPoolRepository().load(prototype.getPool().getKey()));
        return entity;
    }
}
{% endhighlight %}

 Logic inside `SubscriptionPlanFactory#instantiate` is also used by command handler when processing `SubscriptionPlanCreateCommand` so good idea is to promote SubscriptionPlanFactory to standard factory for SubscriptionPlanAR that is not only able to instantiate empty aggregate root but also create new valid aggregate root as dictated by business requirements. To do so we will add public `create` method to the factory:

{% highlight java %}
public class SubscriptionPlanFactory extends AbstractAggregateFactory<SubscriptionPlanAR> {
    //[..]
    public SubscriptionPlanAR create(SubscriptionPlanAR prototype) {
        return instantiate(prototype).create(generateId(), prototype);
    }
}   
{% endhighlight %}

Please note that event sourced ARs can't rely on auto-generated identifiers (identifiers generated after AR is saved to database), that's why our factory generates identifier before creating AR (previously it was responsibility of command handler).

Please also note that main construction logic (application and handling of `SubscriptionPlanCreatedEvent`) is still placed inside AR itself, but now it is contained in `create` method instead of constructor:

{% highlight java %}
public class SubscriptionPlanAR extends AbstractAggregateRoot {
    // no constructors, use factory to create valid instances
    public SubscriptionPlanEntity create(AggregateIdentifier identifier, SubscriptionPlanAR prototype) {
        apply(new SubscriptionPlanCreatedEvent(identifier, prototype));
        return this;
    }

    @EventHandler
    public void handle(SubscriptionPlanCreatedEvent event) {
        setId(event.getAggregateId());
        this.actionOnReSubscription = event.getActionOnReSubscription();
        //[..]
    }
}
{% endhighlight %}

Worth noting is separation between event publishing (`create` method) and event application (`handle` method). Previously (without support for event sourcing) both operations could be implemented in one method (or constructor) (see: [Account.java](https://gist.github.com/pawelkaczor/1117130/raw/db5caeb2815d91f41fe8bf0564049d2ca52dea26/Account.java)), now they need to be split so that loading aggregate root from event stream is possible.

Now, implementation of command handler is straightforward:

{% highlight java %}
public class SubscriptionPlanCommandHandler {
    @CommandHandler
    public SubscriptionPlanAR create(SubscriptionPlanCreateCommand command) {
        SubscriptionPlanAR prototype = new SubscriptionPlanAR.PrototypeBuilder()
            .pool(command.getSubscriptionPoolKey())
            .actionOnReSubscription(command.getActionOnReSubscription())
            .build();
        // use provided factory
        SubscriptionPlanAR subscriptionPlan = getSubscriptionPlanFactory().create(prototype); 

        getSubscriptionPlanRepository().add(subscriptionPlan);

        return subscriptionPlan;
    }
}
{% endhighlight %}

## Test fixture
We are now ready to configure Axon's given-when-then test fixture that can be used for testing different types of Aggregate Roots:

{% highlight java %}
public abstract class ARTestBase<T extends AbstractAggregateRoot> {

    // need to be implemented in concrete test classes
    protected abstract Class<T> getAggregateType();
    protected abstract AggregateFactory<T> getAggregateFactory();
    protected abstract AbstractCommandHandler getCommandHandler();

    @Before
    public void configureTestFixture() {
        AggregateFactory<T> aggregateFactory = getAggregateFactory();
        AnnotatedCommandHandler commandHandler = getCommandHandler();

        FixtureConfiguration fixture = Fixtures.newGivenWhenThenFixture(getAggregateType());
        fixture.registerAggregateFactory(aggregateFactory);
        fixture.registerAnnotatedCommandHandler(commandHandler);

        commandHandler.setRepository(fixture.getRepository());
    }
}
{% endhighlight %}

Concrete implementation of test class will need to define aggregate type, aggregate factory (Axon provides `GenericAggregateFactory` that can be used if no custom initialization of AR is required) and command handler. Both aggregate factory and command handler are then passed to specialized registration methods of Axon's `FixtureConfiguration`. At the end, command handler is passed reference to repository that was created by `GivenWhenThenFixture` (in production scenario command handler works with JPA-based implementation of Repository interface, in test scenario the repository (of class `EventSourcingRepository`) and event store are constructed by Axon's test framework).

Finally we can implement unit tests by simply declaring commands and events using given-when-then style as following:

 - Given: a set of historic events
 - When: I send a command
 - Then: expect certain events

Sometimes it is shorter to declare commands instead of events in `given` section as one command can result in multiply events. Axon supports that too. It is also possible to assert return value or exception returned/thrown by command handler. It should be noted that all events or commands should refer only to single AR. If you want to test Saga classes (interactions between different ARs) you need to use AnnotatedSagaTestFixture.

Let's see couple of example tests:

{% highlight java %}
public class SubscriptionPlanTest extends ARTestBase<SubscriptionPlanAR> {
    @Test
    public void should_activate_subscription_plan() {
        fixture.given(
            new SubscriptionPlanCreatedEvent(S_PLAN_ID, prototype)
        ).when(
            new SubscriptionPlanActivateCommand(ACTIVATION_DATE)
        ).expectEventsMatching(Matchers.payloadsMatching(exactly(
            new SubscriptionPlanActivatedEvent(ACTIVATION_DATE)))
        );
    }

    @Test
    public void should_add_credit_plan() {
        fixture.givenCommands(
            new SubscriptionPlanCreateCommand(S_PLAN_ID)
        ).when(
            new CreditPlanCreateCommand(S_PLAN_ID, PERIOD, CREDIT_AMOUNT)
        ).expectEventsMatching(Matchers.payloadsMatching(exactly(
            new CreditPlanAddedEvent(S_PLAN_ID, PERIOD, CREDIT_AMOUNT)))
        );
    }

    @Test
    public void should_fail_adding_credit_plan_if_already_exists_for_given_period() {
        givenCommands(
            new SubscriptionPlanCreateCommand(S_PLAN_ID),
            new CreditPlanCreateCommand(S_PLAN_ID, PERIOD, CREDIT_AMOUNT)
        ).when(
            new CreditPlanCreateCommand(S_PLAN_ID, PERIOD, CREDIT_AMOUNT)
        ).expectException(matching(
            new SubscriptionManagementException(Error.ClreditPlanAlreadyExists)
        );
    }
}
{% endhighlight %}

What happens in the background when test is executed can be described in a few steps:
 - given section
    - given events (or events published as the result of given commands execution) are saved to in-memory event store
 - when section
    - command handler is invoked 
    - command handler asks repository to load aggregate root by id
    - repository loads AR from event store (aggregate factory creates empty AR and then events are applied to that AR)
    - command handler invokes appropriate business method on AR

Looking at test class you can see that there is no code related to infrastructure (no dependency to jpa, sql import statements, etc.), we don't care about persistence layer at all. We test external interface represented by command (input) and events (output) decoupling tests from actual AR being tested. Tests are self-explanatory out of the box. Creating a test in this way could be easily supported by some gui tool that would allow building the test by dragging widgets representing events, commands, entities and exceptions into a form (containing given, when, then section) and filling their properties :)  

[http://pkaczor.blogspot.com/2013/11/axon-framework-behavior-driven-testing.html](http://pkaczor.blogspot.com/2013/11/axon-framework-behaviour-driven-testing.html)

{% include bio_pawel_kaczor.html %}
