---
layout: post
title: Reactive DDD with Akka - integrating the Event Store
categories: [cqrs,ddd,akka]
---

#### Introduction

It has been a while since I wrote the last episode in my series: ["The Reactive DDD with Akka"](http://pkaczor.blogspot.com/search/label/Reactive-DDD). In that time, in 2015, I managed to release the two new projects:

* [Akka-DDD](https://github.com/pawelkaczor/akka-ddd) - project that contains reusable artifacts for building applications on top of the Akka platform, following CQRS/DDDD-based approach,
* [ddd-leaven-akka-v2](https://github.com/pawelkaczor/ddd-leaven-akka-v2) - follow-up project of the ddd-leaven-akka that makes usage of Akka-DDD artifacts

As both projects are in a good shape now, it is a high time for me to resume the series and hopefully get more feedback from the developer community. But first, let's recall what we learned so far.

Previously we discovered that the Akka with its Akka Persistence module provided a solid platform for building micro-services, using the DDD/CQRS design principles and patterns. We learned:

* how to implement event-sourced **Aggregate Roots** as persistent actors (aka **clerks**) [1],  
* how the command dispatching is performed by **offices** in the standalone and the distributed environment and 
* how the events produced by the Aggregate Roots can be transmitted reliably to other actors.

[1] Please see [Don't call me, call my office](http://pkaczor.blogspot.com/2014/04/reactive-ddd-with-akka-lesson-2.html#office) for explanation of the office & clerk concept.

Further, I noticed the lack of support of the query side of the system in the Akka Persistence, and we found out how to overcome this limitation by using an external message broker. We also noticed that if we used the [Event Store](https://geteventstore.com/) as an underlying event store, we could reliably feed the query side of the system by executing the Event Store Projections (thus avoiding the necessity of introducing a message broker into the system). In my view this idea was so interesting that I decided to give it a try and that is why I started the Akka-DDD project. 

In this episode we will learn how to create two kinds of journals using the Event Store Projections mechanism:

* office journals - containing events emitted by a concrete office
* business process journals - containing events related to a concrete business process

From the point of view of the business application requirements, these two kinds of journals are much more useful than the journals of the single Aggregate Roots (the clerk journals). We will learn how the specialized services such as View Updaters and Receptors can subscribe to these journals using the [Event Store JVM Client](https://github.com/EventStore/EventStore.JVM). 

Recently a new version of Akka Persistence has been [released](http://akka.io/news/2015/09/30/akka-2.4.0-released.html) that contains Query Support on its feature list. So consequently, do we still need to use the Event Store API directly? We will answer this interesting question at the end.

However, now, we will begin  with introduction to the Event Store (as a component that we want to integrate with the Akka-DDD) by looking at it from the two opposite sides: 

* ‘the write side’ - the Event Store as a journal provider
* ‘the read side’ - the Event Store as the event bus

#### The Event Store as a journal provider

##### The clerk's journal

The [EventStore Akka Persistence](https://github.com/EventStore/EventStore.Akka.Persistence) is a storage plug-in (journal provider) implemented for the Event Store. Under the hood the plug-in uses [Event Store JVM Client](https://github.com/EventStore/EventStore.JVM). When a persistent actor requests the persisting of an event message, the journal tells the Event Store to write the given event message to a stream with a `streamId`, equal to the actor's [persistenceId](https://github.com/akka/akka/blob/v2.4.1/akka-persistence/src/main/scala/akka/persistence/Persistence.scala#L78). If a stream with the given ID does not exist, it is automatically created by the Event Store. The Akka-DDD defines `persistenceId` of a persistent actor as a concatenation of `officeId` and `clerkId` (separated by a dash), where `officeId` must be implicitly provided for each Aggregate Root class (via `OfficeId` type class) and `clerkId` is defined as actor's ID [2]. The `[officeId]-[clerkId]` is thus the ID of a stream in the Event Store being a journal of a clerk (identified by `clerkId`) within an office (identified by `officeId`).

[2] The ID of a persistent and sharded actor is extracted from the first command message, it receives.

##### The journal entry format

The Event Store requires the following data to create a journal entry:

* EventId - used internally by the Event Store for idempotency
* EventType - an arbitrary string — commonly used for events selection (see paragraph about Projections)
* Data - actual data in a serialized form (according to the ContentType)
* ContentType - for instance json, binary, etc
* Metadata (optional) - additional data associated with the entry in a serialized form (according to the MetadataContentType)
* MetadataContentType (optional) - for instance json, binary, etc.

##### Transforming an event to a journal entry

Before a domain event is written to an actor’s journal, it is first wrapped by the Akka-DDD in an `EventMessage` envelope (see: [AggregateRoot#raise](https://github.com/pawelkaczor/akka-ddd/blob/01.01.2016/akka-ddd-core/src/main/scala/pl/newicom/dddd/aggregate/AggregateRoot.scala#L45)) and then the `EventMessage` is wrapped by Akka in a `PersistentRepr` envelope. Eventually the journal plug-in is executed to store the `PersistentRepr` in the actor's journal.
 
```
Event (Domain) → EventMessage (Akka-DDD) → PersistentRepr (Akka) → Journal entry (EventStore plug-in)
```

The `EventMessage` envelope allows adding an arbitrary number of meta attributes. The Akka-DDD takes care of handling the following meta attributes:  

* id - the application level message ID (independent from the internal ID used by the Event Store) 
* timestamp - the record of the time the event was created at
* causationId - the application level ID of some other message that caused this message (ie. `commandId` for the events raised by the clerks) 
* correlationId (optional) - the application level ID of a business process, that the event message is associated with
* _deliveryId (optional) - it is used between actors that communicate using the At-Least-Once delivery semantics 


The actual serialization of the `PersistentRepr` to the journal entry format is performed by a [specialized serializer](https://github.com/pawelkaczor/akka-ddd/blob/01.01.2016/eventstore-akka-persistence/src/main/scala/pl/newicom/eventstore/plugin/EventStoreSerializer.scala) that is automatically [registered](https://github.com/pawelkaczor/akka-ddd/blob/01.01.2016/eventstore-akka-persistence/src/main/resources/reference.conf) by the Akka-DDD. The serializer uses json format, taking advantage of the fact that the Event Store natively supports json. The `EventType` attribute is set to a name of an event class. The serializer also takes care of the serializing of the metadata defined in the `EventMessage`. Here is an example of a journal entry for a `ReservationCreated` event, read from `Reservation-57d868` stream (office ID: Reservation, clerk ID: 57d868): 

{% highlight javascript %}
EventType: ecommerce.sales.ReservationCreated

ContentType: json

Data: {
  "jsonClass": "akka.persistence.PersistentImpl",
  "payload": {
    "jsonClass": "ecommerce.sales.ReservationCreated",
    "reservationId": "57d868",
    "customerId": "063a80"
  },
  "sequenceNr": 1,
  "persistenceId": "Reservation-57d868",
  "manifest": "",
  "deleted": false,
  "sender": null,
  "writerUuid": "e653b38f-a034-40dd-814e-de3b02129e4d"
}

Metadata-ContentType: json				

Metadata: {
  "jsonClass": "pl.newicom.dddd.messaging.MetaData",
  "content": {
    "causationId": "8d606b8126884714b1ddfea5d0724c3c",  
    "id": "d5073d7c771246b8ac541c86a9329000",
    "timestamp": "2015-12-30T09:55:01Z"
  }
}
{% endhighlight %}

As you can see, although the `Data` element contains a json representation of an object instance of a `PersistentImpl` class (a class implementing a `PersistentRepr` trait), the `EventType` element contains a value that refers to the actual event. The event itself is stored under the `payload` attribute of the `PersistentImpl` object.

Please, notice also the `sequenceNr` attribute of the `PersistentImpl`. It is generated by Akka and represents a position of the entry in the actor's journal. Since the `sequenceNr` is available only after an event message has been stored, the Akka-DDD distinguishes between the `EventMessage` - the event message to be stored in the journal and the `OfficeEventMessage` - the event message fetched from the journal. 

#### The Event Store as the event bus

In general, the event bus is a layer that allows a ‘publish - subscribe’ style communication between components without requiring the components to explicitly register with one another. So far we have discussed how events get published (written to the journals) from ‘the write side’ of the system. Now it is time to describe the event subscribers - the actors that want to be notified about the published events. There are two types of the event subscribers available in the Akka-DDD:

* View Updaters - responsible for the updating of ‘the read side’ of the system. They are interested in the events from the particular office journal.
* Receptors - responsible for the event-driven interaction between the subsystems (event choreography), including long-running processes (sagas). They are interested in the events from a particular office journal or a particular business process journal.

For the next paragraph, let's leave the question how the office journals and the business process journals get created. Let’s assume, they can be created. 

Knowing the ID of a stream, we can use the Event Store API to register a subscriber, interested in getting events from that stream. A subscription can be defined as a ‘live-only’ (only new events get pushed to the subscriber) or a ‘catch-up’ one. A ‘catch-up’ subscription works in a very similar way to a ‘live-only’ subscription, with one notable difference: subscriber specifies the position, from which events will get pushed. A ‘catch-up’ subscription thus allows creating the durable subscribers. Such subscribers can resume processing the events as long as they are able to record position of the last processed event. 
The subscribers resume the processing after they were stopped or terminated and then restarted e.g. as the result of system crash.
In the next episode, we will learn how toimplement the View Updaters and the Receptors using the ‘catch-up’ subscriptions. 
But now, let's see how we can create new streams using the Event Store Projections. 

#### Creating streams using the Event Store Projections

The Event Store is able to execute the built-in or a user defined projection - a chunk of javascript code containing the following elements: 

* The identifier(s) of the input event stream(s)
* The event(s) selection(s)
* The function(s) that accepts an event and a state as a parameter. The function can call the  `linkTo(streamId, event)` function to write the input event into an arbitrary stream or it can call the `emit(streamId, eventType, event)` function to emit a new event into an arbitrary stream.

A projection will be stopped automatically after all historical events are processed unless it is started in the continuous mode. If so, also the new events will be processed as they are added to the input stream(s).

Let's see an example. The projection below will watch the built-in `$stats-[ip:host]` stream containing low level system statistics for events of the type: `$statsCollected` and will emit a new event (of the type: `heavyCpuFound`) to the new `heavycpu` stream whenever a value of the `sys-cpu` statistic, read from the caught event, would exceed 40:

{% highlight javascript %}
fromStream('$stats-127.0.0.1:2113').
    when({
        "$statsCollected" : function(s,e) {
              var currentCpu = e.body["sys-cpu"];
              if(currentCpu > 40) {
                   emit("heavycpu", "heavyCpuFound", {"level" : currentCpu})
              }
         }
    });
{% endhighlight %}

##### Creating an office journal

We learned that the stream with ID: `Reservation-57d868` represents a journal of a clerk `57d868` working in the `Reservation` office. Now we want to create a journal that contains the events emitted by all clerks working in the `Reservation` office. To accomplish this, we need to use the `$by_category` system (built-in) projection. It turns out that the Event Store is able to extract a category of a stream from its id (treating dash (`-`) as a category separator). The `$by_category` projection, once enabled (all system projections are disabled by default), will detect the `Reservation` category and will create a `$ce-Reservation` journal for the `Reservation` office automatically. Similarly it will create appropriate office journals for all other offices already existing in the system or created in the future (all the system projections are running in continuous mode so we don't need to restart them in the future anymore).

##### Creating a business process journal 

Now, when we know how to create the office journals, we can use them as input streams for the business process journals. For example let's create an `invoicing` journal that will contain all the events related to the [invoicing business process](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/master/invoicing/write-back/src/main/scala/ecommerce/invoicing/InvoicingSaga.scala):

{% highlight javascript %}
fromStreams(['$ce-Reservation', '$ce-Invoice']).
    when({
        'ecommerce.sales.ReservationConfirmed' : function(s,e) {
            linkTo('invoicing', e);
        },
        'ecommerce.invoicing.OrderBilled' : function(s,e) {
            linkTo('invoicing', e);
        },
        'ecommerce.invoicing.OrderBillingFailed' : function(s,e) {
            linkTo('invoicing', e);
        }
    });
{% endhighlight %}

[Source](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/master/invoicing/write-back/src/main/resources/projections/invoicing-process.js)

This time we have defined journals of the two offices (`Reservation` and `Invoice`) as input streams. Then for each type of an event, relevant to the invoicing business process, we have defined a function that simply "inserts" the original event into an `invoicing` stream. [↓3]

[↑3] In fact, when using the `linkTo` function, the event inserted into the output stream is not the original event (or its copy), but a special link event containing only a pointer to the original event.

Please notice that the `invoicing` stream does not represent a journal of a concrete instance of the invoicing business process (an invoicing process for a concrete customer/order). Once we learn about the [Saga Office](https://github.com/pawelkaczor/akka-ddd/wiki/Saga) (in the upcoming episode in the series) we will also learn how a special receptor (called `SagaManager`) takes care of forwarding the events, read from the `invoicing` stream to the `Invoicing Saga Office` that in turn forwards/routes them to the concrete clerks responsible for the management of the single business process instances. The clerks then decide which events to store in their own journals - the journals representing the single process instances. 

#### Reading events from a journal

It is a time to learn how to implement a durable event subscriber using the Akka-DDD framework. The trait we will need to use is [EventSourceProvider](https://github.com/pawelkaczor/akka-ddd/blob/01.01.2016/eventstore-akka-persistence/src/main/scala/pl/newicom/eventstore/EventSourceProvider.scala) located in the `eventstore-akka-persistence` module. The trait exposes the `eventSource(esConnection, observable, fromPositionExclusive): Source[EventMessageRecord, Unit]` method. As the method's signature suggests, it accepts some observable object (next to the Event Store connection object and the start position) and returns an object that is a source of the [EventMessageEntry](https://github.com/pawelkaczor/akka-ddd/blob/01.01.2016/akka-ddd-messaging/src/main/scala/pl/newicom/dddd/messaging/event/EventMessageEntry.scala) objects. The [Source](http://doc.akka.io/api/akka-stream-and-http-experimental/2.0.1/#akka.stream.scaladsl.Source) class is Akka's representation of [Publisher](http://www.reactive-streams.org/reactive-streams-1.0.0-javadoc/org/reactivestreams/Publisher.html) as defined by the [Reactive Streams](http://www.reactive-streams.org/) standard. 

The `eventSource` method takes an observable [BusinessEntity](https://github.com/pawelkaczor/akka-ddd/blob/01.01.2016/akka-ddd-messaging/src/main/scala/pl/newicom/dddd/aggregate/BusinessEntity.scala) and obtains `streamId` from it by calling the [StreamIdResolver](https://github.com/pawelkaczor/akka-ddd/blob/01.01.2016/eventstore-akka-persistence/src/main/scala/pl/newicom/eventstore/StreamIdResolver.scala#L10). The `StreamIdResolver` knows how to resolve a `streamId` regardless whether the given entity is a clerk, an office or a saga office. The method then uses the obtained `streamId` to create a `Publisher` by calling the `streamPublisher(streamId, position, ...)` method provided by the [EventStore JVM Client Reactive Streams API](https://github.com/EventStore/EventStore.JVM#reactive-streams). Finally the method converts the `Publisher` object to a `Source` object that is instructed to emit the event messages (discussed previously) wrapped into an `EventMessageEntry` envelope.    

The Akka-DDD makes use of the `EventSourceProvider` trait to implement the two types of the durable subscribers: the View Update Service and the Receptor. We will not dive into the implementation details of these services in this article, but as you can imagine, the stream processing is the preferred pattern used there.

#### The Akka Persistence Query

As stated in the [docs](http://doc.akka.io/docs/akka/2.4.1/scala/persistence-query.html#persistence-query-scala), since version 2.4, the Akka Persistence provides a universal asynchronous stream based query interface that various journal plug-ins can implement in order to expose their query capabilities. The interface exposes the `ReadJournal` trait family that provides two groups of methods for the reading events from the journal: ??:

The methods that return a source, that is emitting the historical events: 

* currentEventsByPersistenceId(id)
* currentEventsByTag(tag)

The methods that return a "live" source, that is emitting both, the past and the upcoming events: 

* eventsByPersistenceId(id)
* eventsByTag(tag)

**The journal plug-ins are not obliged to support all types of queries so they must explicitly document which types of queries they support.**

As you can see, the interface supports not only queries for the events from a single journal but also the queries for the "tagged" events from an arbitrary number of journals. 

Some journal plug-ins may support the `EventsByTag` queries out of the box by requiring events to be wrapped in an `akka.persistence.journal.Tagged` before they get written to the journal. (Such a wrapping could be implemented using [Event Adapters](http://doc.akka.io/docs/akka/2.4.1/scala/persistence.html#Event_Adapters)). 
Other plug-ins may treat tags as identifiers of the arbitrary event journals such as office journals or business process journals. These journals could be managed externally (for example using the Projections in case of the Event Store (as we have seen above)).

Going back to the Akka-DDD, would it be possible to use the Akka Persistence Query instead of the EventStore JVM Client and thus to gain more interoperability? Well, currently this is not possible, because the Eventstore Akka Persistence plug-in supports only the queries for the events from a single journal (the `EventsByTag` queries are not supported).So the following code will not work unfortunately:

{% highlight scala %}
val sourceOfReservationEvents: Source[EventEnvelope, Unit] = readJournal.eventsByTag("$ce-Reservation")
{% endhighlight %}

#### Conclusion

Although the Akka Query is marked as “experimental” and the Event Store Projections are still in “Beta” version, I think, they both are worth considering when thinking about developing a new system, that is implementing the DDD/EDA/CQRS (or Microservices, if you like) architecture. 
Being able to easily create the arbitrary streams of events to which the interested actors can subscribe using the standard protocol (Reactive Streams) is great when heading for a loose coupling and reactiveness.


[http://pkaczor.blogspot.com/2015/12/akka-ddd-integrating-eventstore.html](http://pkaczor.blogspot.com/2015/12/akka-ddd-integrating-eventstore.html)

{% include bio_pawel_kaczor.html %}