---
layout: post
title: Axon Framework - DDD and EDA meet together
categories: [cqrs]
---
**[CQRS](http://martinfowler.com/bliki/CQRS.html)** (Command Query Responsibility Segregation) is a new approach towards building scalable and distributed systems that is based on simple pattern know as Command Query Separation ([CQS](http://martinfowler.com/bliki/CommandQuerySeparation.html)). In short, you should design your system in a way that it either processes a command or serves response to a query. CQRS in its core is quite simple. Just split your service interface into two parts: Query Service and Command Service and you are done. But what is important is that by making this simple separation, you make your system open to many opportunities for architecture that may otherwise not exist. In this article I will not show you what is possible when fully applying CQRS (check this [CQRS Starting Page](http://abdullin.com/cqrs/) for details). Instead I will present you how some design patterns can effectively be applied to standard ORM-based application when you decide to split your interface into Commands and Queries and use [Axon](http://code.google.com/p/axonframework/) - CQRS framework for Java. But first we must talk about [DDD](http://www.domaindrivendesign.org/resources/what_is_ddd) as it plays crucial role in building scalable and maintainable systems and fits very well to CQRS-based architecture. 

## DDD shortly
Generally DDD is about domain model that, when expressed in Ubiquitous Language, can be shared by developers and domain experts allowing them to communicate effectively. From technical point of view DDD is about modeling your core domain using aggregate roots (AR), entities, value objects and some other artifacts like domain services and repositories. What is important, when applying DDD to medium or large domains (generally complex domains are good candidates for DDD), you should not be expecting one model to arise representing all areas covered by the system. Each area will likely be modeled separately (inside its own [Bounded Context](http://www.domaindrivendesign.org/node/91). This aspect is very important, especially if your application starts to grow covering more and more business activities. If you stick with one model aka EDM (Enterprise Domain Model) (that typically reassembles model of relations inside your sql database), you will end up with monolithic system not capable of adjusting to business requirements. 
Therefore building application DDD-way should be seen as completely different approach comparing to standard approach (``one model to rule them all`` approach). You will need additional means to express communication between your different models (Bounded Contexts). 
Thats where EDA - event based communication comes in. 

Let's see how to apply DDD and EDA to standard ORM-based application with use of Axon.

## Axon introduction
Axon framework provides building blocks for CQRS applications. Some blocks, i.e. [event sourcing](http://martinfowler.com/eaaDev/EventSourcing.html), asynchronous processing of commands (no response from Command Handler)) are optional and can be omitted. If you are not ready for (or just don't need) full CQRS, you can still benefit from other goodies such as synchronous command handling, events, sagas and others. Additionally Axon integrates deeply with Spring making configuration a trivial task (just use built in namespaces (xml part) and annotations). Unique feature of Axon is that it allows to integrate existing JPA-based application. To make your entities become Aggregate Roots extend ``AbstractAggregateRoot`` class, to load your ARs from database use ``GenericJpaRepository`` (or even better ``HybridJpaRepository`` if you want to use EventStore). For detailed instructions see User's Guide. Lets start working with code.

## Get rid of Trasaction Script
When applying DDD, we tend to build rich entities that encapsulate behavior.
In contrast to standard approach with [anemic domain model](http://martinfowler.com/bliki/AnemicDomainModel.html) and procedural code inside Application Services (see: [Transaction Script](http://martinfowler.com/eaaCatalog/transactionScript.html)), most of business logic should be handled inside Aggregate Roots. When a command comes in, it is dispatched to Command Handler whose only job should be to get AR from Repository and invoke single method on it.

Lets imagine a system that manages user accounts (Account AR). One of Account's properties is ``state``. To activate an account, ``AccountActivateCommand`` must be sent by the client. In order to handle this command, we must register and implement specialized Command Handler:

{% highlight java %}
class AccountCommandHandler {
	@CommandHandler
	public Account activate(AccountActivateCommand command) {
		Account account = accountRepository.findById(command.getAggregateId());
		account.activate();
		return account;
	}
}
{% endhighlight %}

That's it. Nothing special. Clean code so far.

## Implementing business logic - uniformed approach
First, we need to extend our model in order to make it more interesting :) Our system must support handling user's payments related to Payment Period. The following requirements are added: 

 1) when Account is activated, Payment Period must be created that will be used to keep track of payments related to the Account
 
 2) after Payment Period expires, subsequent Payment Period must be created, but expired Payment Period should still be accessible

We could model our Account like this:
{% highlight java %}
class Account extends AbstractAggregateRoot {
    {...}
    @OneToMany
    private List<PaymentPeriod> paymentPeriods;

    private int currentPaymentPeriod;
    {...}
}

class PaymentPeriod {

  @ManyToOne
  private Account account;
  {...}
}
{% endhighlight %}
In this model, Account is responsible for managing Payment Periods. It sounds good, we can implement account activation inside Account class:

{% highlight java %} 
public void activate() {
  validateTransitionToStatus(ACTIVE)

  apply(new AccountActivatedEvent())

  // handle AccountActivatedEvent
  status = ACTIVE
  currentPaymentPeriod++;
  paymentPeriods.add(new PaymentPeriod(...))
}
{% endhighlight %}
Please notice three blocks of code in this method and theirs order. This separation is dictated by CQRS-based design. You should have all these blocks in every method that is invoked by Command Handler. The blocks are:

 1) validation - checking if operation is allowed and will not break consistency of the Aggregate
 
 2) raising event - creating a Domain Event containing information about Aggregate's change
 
 3) handling event - updating state of the Aggregate (no exceptions, no logic here!)

Every change of Aggregate's state must be signaled with an Event (Domain Event). All Domain Events will be stored in Event Store (if configured) (just serialized as Blobs or Clobs to single table).

If our Aggregate Root is event-sourced (is reconstructed from Event Store instead or being created by EntityManager), we should move event handling code to separate method:

{% highlight java %}
@EventHandler
private void accountActivated(AccountActivatedEvent event) {
  status = ACTIVE
  currentPaymentPeriod++;
}
{% endhighlight %}
We will not discuss Event Sourcing in this article, as we don't want to get rid of our powerful ORM, or do we? (actually in CQRS world ORM is 
persona non grata - you were warned ;)

## Keep your ARs lously coupled
Going back to our model, after thinking a little bit longer, we realize that it doesn't fit well our needs... One of the requirements is to process commands related directly to Payment Periods. These commands should be dispatched directly to Payment Period entity rather than go through Account AR. Payment Period should be an AR on its own. When we think more about this (and talk with our Domain Expert (if we have one;)), the separation of Account and Payment Period will become even more obvious. We could easily imagine two services Account Service (responsible for accounts management) and Payment Service (responsible for payment registration) working independently.

So we can simplify Account AR and upgrade Payment Period to AR:

{% highlight java %}
class Account extends AbstractAggregateRoot {
    {...}
    private int currentPaymentPeriod;

    public void activate() {
      validateTransitionToStatus(ACTIVE)

      apply(new AccountActivatedEvent())

      // handle AccountActivatedEvent
      status = ACTIVE
      currentPaymentPeriod++;
    }
    {...}
}

class PaymentPeriod extends AbstractAggregateRoot {
    {...}
    @ManyToOne
    private Account account;
    
    public PaymentPeriod(Account account) {
      apply(new PaymentPeriodCreated(account.getAggregateId()));
    }
    {...}
}
{% endhighlight %}
Now account activation is implemented partially (Payment Period is not being created). We could implement Application Service that would first call Account#activate and than create new Payment Period, but implementing business logic within Application Service layer leads to Transaction Script that we are trying to avoid (we want to avoid both ARs (Account and Payment Period) forcibly be invoked in the same transaction - it hurts system scalability).
Lets think of our ARs on higher level. They belong to different contexts/services (virtual Account Service and Payment Service). The way to communicate between different contexts (services) is to use Domain Events!

## Events to the rescue
We already have implemented raising of the ``AccountActivatedEvent`` in activate() method of Account AR. Now we must create Event Listener that will listen for this event and will send ``PaymentPeriodCreate`` command.
With Axon it is as simple as creating new class:

{% highlight java %} 
@Component
public class PaymentService {

  @Autowired
  private CommandBus commandBus;

  @EventHandler
  public void createPaymentPeriodOnAccountActivation(AccountActivatedEvent event) {
    commandBus.dispatch(
      new PaymentPeriodCreateCommand(event.getAccountId())
    );
  }
}
{% endhighlight %}
Of course, we need to implement a command handler that will handle ``PaymentPeriodCreateCommand`` by creating Payment Period AR and adding it to Repository.
Thats all. Now we have independent ARs that communicate with events.
This design leads us in direction of autonomous components (services) communicating asynchronously in publish-subscribe model (aka: push integration model), possibly via some kind of EventBus or Broker (see: [Avoid a Failed SOA: Business & Autonomous Components to the Rescue](http://www.infoq.com/presentations/SOA-Business-Autonomous-Components) by [Udi Dahan](http://www.udidahan.com/))
But we will not go so far.

There are many other benefits from applying EDA. One of them is ability to keep detailed history of Events:

## History of Events (Audit)
By storing Events in database (Event Store) we keep log of changes. We can easily create additional table containing following data:
 
 - aggregate root class 
 - aggregate root id
 - event class
 - user

The table like this can serve basic reporting purposes. If we want to create more sophisticated reports in the future, we can reply events stored in Event Store and populate any report table we need. **All** history of changes is kept in Event Store.

Now lets see how we can model long running process with SAGA! In case you forgot the requirements, short reminder: new Payment Period must be created after the current one expires.

## Enter SAGA
Saga is a stateful component (its state is persisted across invocations) that is capable of receiving events (including timeout events) (similar to Event Listener). Saga represents business process instance, in other words business process associated with particular AR(s).

{% highlight java %} 
class PaymentPeriodSaga extends AbstractSaga {

	@StartSaga
	@SagaEventHandler(associationProperty = "paymentPeriodId")
	public void paymentPeriodCreated(PaymentPeriodCreatedEvent event) {
		associateWith("accountId", event.getAccountId());
		getEventScheduler().schedule(
		  // trigger datetime
		  event.getValidityInterval().getEnd(), 
		  // the event to publish
		  new PaymentPeriodExpiredEvent(event.getContext(), event.getAggregateId())
	        );
	}

	@SagaEventHandler(associationProperty = "paymentPeriodId")
	public void paymentPeriodExpired(PaymentPeriodExpiredEvent event) {
		RenewAccountCommand command = new RenewAccountCommand.Builder(event.getContext())
			.accountId(getAssociatedId("accountId"))
			.build();
		
		getCommandBus().dispatch(command);
	}
}
{% endhighlight %}
First method will be invoked on ``PaymentPeriodCreatedEvent`` and will result in creation of new Saga associated with Payment Period being created and related Account. Inside method body we schedule the ``PaymentPeriodExpiredEvent`` that will be triggered when validity interval of Payment Period ends (Axon provides Quartz-based implementation of Event Scheduler) .
The second method is called when payment expiration happens (when ``PaymentPeriodExpiredEvent`` is triggered by the Event Scheduler).
The only thing this method does is sending a command that will be processed by our Account Service (currentPaymentPeriod must be increased) and eventually by Payment Service (new Payment Period will be created).

Lets see how easy we can test our Saga with use of Test Fixture provided by Axon:

{% highlight java %} 
class PaymentPeriodSagaTest {
    AggregateIdentifier newPaymentPeriodId = ...
    AggregateIdentifier accountId = ...
    Interval validityInterval = new Interval(new DateTime(), new DateTime().plusDays(1));

    getFixture(PaymentPeriodSaga.class)
    // given
    .givenAggregate(newPaymentPeriodId)
	  .published(new PaymentPeriodCreatedEvent(accountId, validityInterval))
    // when
    .whenTimeAdvancesTo(validityInterval.getEnd())
    // then
    .expectDispatchedCommandsEqualTo(
	  new RenewPaymentPeriodCommand(accountId)
    );
}
{% endhighlight %}
Finally, I want to discuss one more topic related to DDD.

## Don't pollute your core domain model

What is common mistake DDD beginners make is that they try to apply DDD totally (put all application logic into ARs boundaries). Let's take an example and add new requirement to our application: 
All entities (including Account) are separated by Sales Areas. Any operation on Account (creation, activation, etc.) can be performed only if the owning Sales Area is in status ACTIVE. 

First, we will modify our model by adding the following JPA mapping to the Account AR:

{% highlight java %} 
class Account extends AbstractAggregateRoot {
    {...}
    @ManyToOne
    private SalesArea salesArea;
    private int currentPaymentPeriod;
    
    public void activate() {
	{...}
    }
}
{% endhighlight %}
Now lets think of the requirement. Where should we put the checking if the Sales Area is active? The ``activate()`` method of Account AR seems to be the perfect place. But if we think more, we realize that Sales Area does not belong to our core domain! Checking status of the Sales Area inside Account AR will pollute the code (checking must be done before any modification of Account's state). So our new model is broken! There should be no Account -> Sales Area mapping. But we can not remove it, because we reuse the same model for serving queries (we don't follow CQRS in this aspect) and we need to be able to filter Accounts by Sales Area easily. 
Ok, so the better place to put the checking would be a Command Handler (``AccountCommandHandler``). But it may be necessary to reuse this logic across different commands. What we need is some kind of interceptor that will prevent particular commands (account related or other) reaching Command Handlers. Not surprisingly Axon provides ``CommandHandlerInterceptor`` interface that allows for customized command handler invocation chains. No example this time, as it is quite easy to imagine:)


[http://pkaczor.blogspot.com/2011/08/axon-framework-ddd-and-eda-meet.html](http://pkaczor.blogspot.com/2011/08/axon-framework-ddd-and-eda-meet.html)

{% include bio_pawel_kaczor.html %}
