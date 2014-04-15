---
layout: post
title: Reactive DDD with Akka
categories: [cqrs,ddd,akka]
---

When comparing traditional and DDD/CQRS architectures (see my [previous article](http://devblog.consileon.pl/2013/11/26/axon-behavior-driven-testing)) I said that the goal of DDD model is to decompose complex business domain into manageable pieces taking into account scalability and consistency requirements. What it means is that by bringing concepts like bounded contexts, transaction boundaries and event based communication DDD and CQRS are great enablers for building scalable software. But so far, example services I have presented, were supposed to be run on top of relational database and within global transactions. This is very limiting architecture not suited for building scalable software. Continuous consistency of underlying data that is guaranteed by global transactions should not be perceived as standard requirement of any (including enterprise-class) system. It's an artificial requirement that we all got used to but does not addresses real requirements of the customer. To fully benefit from DDD/CQRS architecture we should change the underlying technology. Today we have a choice. There is a lot of NoSQL databases and there are a few platforms that address scalability as first concern. For JVM, **Akka** (part of [Typesafe platform](http://typesafe.com/platform)) is the most robust open-sourced platform for building event-driven applications. Recently akka-persistence module has been released that takes care of handling long-running/persistable processes (this is what Aggregate Roots and Sagas are all about). This is a great feature that allows thinking of Akka as complete platform for building enterprise applications.

Lets then start building event-driven, scalable, resilient and responsive (in short **reactive**) application using Akka and other goodies from Typesafe platform. 
I have already started a project on [Github](https://github.com/pawelkaczor/ddd-leaven-akka). You are welcome to contribute! 

Below is the first lesson I learned from the project and wanted to share it with you. Hopefully more lessons will come (see [open tickets](https://github.com/pawelkaczor/ddd-leaven-akka/issues?state=open) on Github).


## Lesson 1 - Aggregate root is an actor

The source code for lesson 1 is available [here](https://github.com/pawelkaczor/ddd-leaven-akka/tree/Lesson1)

The goal of lesson 1 is to learn how to build event sourced Aggregate Root (AR) on Akka.
The idea is simple. Aggregate Root should be modeled as stateful `Actor` that accepts Commands and produces Events. Because actor is message driven, we can send `Command` messages directly to Aggregate Root avoiding "command to method call" transformation.

As already mentioned akka-persistence provides necessary artifacts for building persistable/stateful actors. The key component is `akka.persistence.Processor` trait. Processor is an actor capable of restoring its state (aka recovering) during reincarnation (start or restart of the actor). The type of underlying storage is append-only pluggable journal. 

### Command sourcing

Any message of type `Persistent` that comes to a processor is stored in a journal before it is processed. During recovery, persistent messages are replayed to the processor so that it can restore internal state from these messages. 
This pattern (called Command sourcing) is not particularly applicable for Aggregate Roots because replying of command that has not yet been validated is not desired. 

### Event sourcing

To build AR we need to extend from `EventsourcedProcessor` that adds event sourcing capability (`Eventsourced` trait) to `Processor` trait - only produced events will be stored in the journal. This means we need to explicitly invoke `persist(event)` method of `Eventsourced` trait to store produced event in the journal after command message has been validated (by validation I mean ensuring AR's invariants will not be compromised by the command). Since `persist` method persists events asynchronously (does not block the current thread) it accepts a callback (event handler) as the second argument. Main responsibility of event sourced AR is to provide event handler that will update internal state of AR and handle the event by publishing it and/or sending a response to the client/command sender. Handling of event should be customizable.

### AggregateRoot trait

Let's see how to build abstract event sourced [AggregateRoot](https://github.com/pawelkaczor/ddd-leaven-akka/blob/Lesson1/src/main/scala/ddd/support/domain/AggregateRoot.scala) class.

Abstract `AggregateRoot` keeps state using private variable member of type `AggregateState` (abstract) and takes care of updating this variable whenever an event is produced/raised (`raise` method) or replayed (`receiveRecovery` method). State itself (concrete implementation of `AbstractState`) should be immutable class implementing method `apply` that defines state transitions for each event (except initialization). Initialization of the state is performed by `AggregateRootFactory` - the abstract member of AR that must be overridden in concrete implementation of AR. Initialization is event-driven as well which means that `AggregateRootFactory` creates initial state from an event. To complete the picture, the **raise(event)** method calls `persist` method and, after event is persisted, it either calls default handler or handler provided as the second (optional) argument of the `raise` method. Default handler publishes an event to event bus (provided by Akka) and sends `Acknowledged` message back to the sender.

### Reservation AR

Please take a look at implementation of concrete Aggregate Root ([Reservation](https://github.com/pawelkaczor/ddd-leaven-akka/blob/Lesson1/src/main/scala/ecommerce/sales/domain/reservation/Reservation.scala)). The code should be self explanatory. Command processing consists of validation and raising an event.

[ReservationSpec](https://github.com/pawelkaczor/ddd-leaven-akka/blob/Lesson1/src/test/scala/ecommerce/sales/domain/reservation/ReservationSpec.scala) verifies if Reservation AR is in fact stateful component, capable of handling reservation process. The test just simply sends several commands to Reservation AR in valid order and verifies if expected events have been persisted. In the middle of the process Reservation actor is restarted to verify if it preserves the state. And in fact it is since subsequent commands are handled successfully.

### Errors handling

By default if any exception of type java.lang.Exception is thrown by the actor the actor is restarted by its supervisor (this is defined in default `SupervisionStrategy`). Exceptions are not propagated to the command sender automatically as you might expect. We can either catch exception and send them back to the sender from within `receiveCommand` method or send the exception from within `preRestart` method that takes exception as `reason` argument. Overriding `preRestart` method seems to be a simpler approach. Now we can test if exceptions are returned to the sender: [ReservationFailuresSpec](https://github.com/pawelkaczor/ddd-leaven-akka/blob/Lesson1/src/test/scala/ecommerce/sales/domain/reservation/ReservationFailuresSpec.scala).

### In next lesson...

Currently the client needs to get a reference to particular instance of AggregateRoot before sending the command. It would be much easier for him if he could just send the command to some command gateway. This will be the topic of the next lesson.

[http://pkaczor.blogspot.com/2014/04/reactive-ddd-with-akka.html](http://pkaczor.blogspot.com/2014/04/reactive-ddd-with-akka.html)

{% include bio_pawel_kaczor.html %}
