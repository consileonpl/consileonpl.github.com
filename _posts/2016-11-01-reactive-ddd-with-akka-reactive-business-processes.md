---
layout: post
title: Reactive DDD with Akka - Reactive business processes
categories: [cqrs,ddd,akka]
---

#### Introduction

In the last episode we have learned how to implement a sample ordering service using the [Akka-DDD]() framework. The service exposed the `Reservation Office` responsible for preparing and confirming the reservation of products the client added to his/her shopping cart. We have learned that an office is a command handling business entity whose sole responsibility is to validate and process commands. If the command validation succeeds, an appropriate event is written to the office journal. The Reservation office alone is obviously not able to execute the whole ordering process engaging activities like payment processing, invoicing and goods delivery. Therefore, to extend functionality of the system we need to introduce two new subsystems / services: `invoicing` and `shipping`, hosting `Invoicing Office` and `Shipping Office` respectively. The question arises how to employ multiple offices to work on a business process and coordinate the workflow so that the process is executed as defined by the business. To answer this question we will first need to learn how to model a **business process** in a distributed system. Then we will see how Akka-DDD facilitates the implementation of business processes in a distributed system. Finally we will review the implementation of a sample ordering process developed under the [ddd-leaven-akka-v2]() project.

#### Business processes and SOA

To deliver a business value, an enterprise needs to perform its activities in a coordinated manner. Regardless if it is a production line or a decision chain, activities needs to be performed in a specific order accordingly to the rules defined by the business. Business process thus defines precisely what activities, in which order and under which conditions need to be performed so that the desired business goal is achieved. The coordination of the activities implies the information exchange between the collaborators. In the past, business processes were driven by the paper documents flying back and forth between process actors. Nowadays, when more and more activities are performed by computers and robots, the business process execution is realized as message flow between services. Unfortunately though, according to many [reports](), implementation of the **Service-Oriented Architecture (SOA)** ends up easily with a **Big Ball of Mud** as well as scalability and reliability issues (just to name a few) in the runtime. 

The recent move towards the **SOA 2.0** / Event-driven SOA / "SOA done Right" / Microservices (choose your favorite buzzword) enables delivering more light-weight, reliable / fault-tolerant and scalable SOA implementations. When it comes to modeling and executing business processes, the key realization is that since **business processes are event-driven**, the same events that get written to the office journals could be used to trigger the start or the continuation of a business process. If so, any business process can be implemented as an **event-sourced actor** (called **Process Manager**) assuming it gets subscribed to a single stream of events (coming from an arbitrary number of offices) he is interested in. Once an event is received, the Process Manager executes an action, usually by sending a command to an office, and updates it's state by writing the event to its journal. In this way, the Process Manager coordinates the work of the offices within the process. What is important is that **the logic of a business process is expressed in terms of incoming events, state transitions and outgoing commands**. This seems to be a quite powerful domain specific language for describing business processes. Let's take a look at the definition of an sample [Ordering]() process, that is written using the DSL offered by the Akka-DDD:

#### Ordering process - definition  

{% highlight scala %}

	startWhen {

		case _: ReservationConfirmed => New

	} andThen {

		case New => {

		  case ReservationConfirmed(reservationId, customerId, totalAmount) =>
		    WaitingForPayment {
		      ⟶ (CreateInvoice(sagaId, reservationId, customerId, totalAmount, now()))
		      ⟵ (PaymentExpired(sagaId, reservationId)) in 3.minutes
		    }
		}

		case WaitingForPayment => {

		  case PaymentExpired(invoiceId, orderId) =>
		      ⟶ (CancelInvoice(invoiceId, orderId))

		  case OrderBilled(_, orderId, _, _) =>
		    DeliveryInProgress {
		      ⟶ (CloseReservation(orderId))
		      ⟶ (CreateShipment(UUID(), orderId))
		    }

		  case OrderBillingFailed(_, orderId) =>
		    Failed {
		      ⟶ (CancelReservation(orderId))
		    }
		}

	}

{% endhighlight %}

An order is represented as a process that is triggered by the `ReservationConfirmed` event published by the `Reservation Office`. As soon as the order is created, the `CreateInvoice` command is issued to the `Invoicing Office` and the status of the order is changed to `WaitingForPayment`. If the payment succeeds (the `OrderBilled` event is received from the `Invoicing` office within 3 minutes) the `CreateShipment` command is issued to the `Shipping Office` and the status of the order is changed to `DeliveryInProgress`. But, if the scheduled timeout message `PaymentExpired` is received while the order is still not billed, the `CancelInvoice`commands is issued to the `Invoicing Office` and eventually the process ends with a `Failed` status. 

I hope you agree that the logic of the `Ordering` process is easy to grasp by looking at the code above. We simply declare a set of state transitions with associated triggering events and resulting commands. Please note that ```⟵ (PaymentExpired(...)) in 3.minutes``` resolves to the following command: (```⟶ ScheduleEvent(PaymentExpired(...), now + 3.minutes)```) that will be issued to the specialized `Scheduling Office`.

#### Fault-tollerant business process

As the business process participants are distributed and communicate asynchronously (just like the human actors in the real world!) the only way to deal with a failure is to incorporate it into the business process logic. If a failure happens (command rejected by the office, command not processed at all (office stopped), event not received within configured timeout), the counteraction, called compensation, must be executed. For example, the creation of an invoice is compensated by its cancellation (see the Ordering process above). Following this rule, we break the long running conversation (the business process) into multiple smaller actions and counteractions that can be coordinated in distributed environment without the global / distributed transaction. This pattern for reaching distributed consensus without distributed transaction is called `Saga` and was first introduced by the Hector Garcia-Molina in the 1987. Saga pattern can be implemented with or without the central component (coordinator) (see: Orchestration vs. Choreography). Implementation of the `Ordering` process follows the Orchestration pattern - the `Ordering` process is managed by an actor, that is external to all process participants. 

#### Process Managers and Coordination Office

The execution of the logic of a particular business process instance is handled by the **Process Manager** actor. The Process Manager is a stateful / event-sourced actor, just like the regular Aggregate Root actor, except it receives the events instead of the commands. Just like the Aggregate Root actors, Process Manager actors work in the offices. Both the **Command Office** (hosting Aggregate Roots) and the **Coordination Office** (hosting Process Managers) can be started using the [pl.newicom.dddd.office.OfficeFactory#office]() method:

{% highlight scala %}

	office[Scheduler] 			// start Scheduling Command Office
	
	office[OrderProcessManager] // start Ordering Coordination Office

{% endhighlight %}


#### Let the events flow

Coordination Office is expected to correlate the received events with the business process instances using the `CorrelationID` meta-attribute of the event. Therefore to stream the events from the event store to a particular Coordination Office we need to create a `Source` (see: [Reading events from a journal]()) emitting only these events that 1) belong to the domain of the particular business process and 2) were assigned the `CorrelationID` meta-attribute. One way to address the first requirement is to create a journal ([aggregated business process journal](http://pkaczor.blogspot.com/2015/12/akka-ddd-integrating-eventstore.html#business_process_journal)), that aggregates the events belonging to the domain of a particular business process. Some Akka Persistence journal providers may support the automatic creation of journals that group events by [tags](http://doc.akka.io/api/akka/2.4/?akka.persistence.journal.Tagged#akka.persistence.journal.Tagged). Unfortunately, this functionality is not [yet](https://github.com/EventStore/EventStore.Akka.Persistence/issues/26) supported by the Event Store plugin, that is used by the Akka-DDD. Luckily though, using the Event Store projection mechanism, we can create the journal of the Ordering process by activating the following projection:

{% highlight javascript %}
fromStreams(['$ce-Reservation', '$ce-Invoice', 'currentDeadlines-global']).
    when({
        'ecommerce.sales.ReservationConfirmed' : function(s,e) {
            linkTo('order', e);
        },
        'ecommerce.invoicing.OrderBilled' : function(s,e) {
            linkTo('order', e);
        },
        'ecommerce.invoicing.OrderBillingFailed' : function(s,e) {
            linkTo('order', e);
        },
        'ecommerce.invoicing.PaymentExpired' : function(s,e) {
            linkTo('order', e);
        }
    });
{% endhighlight %}

[Source](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/master/headquarters/write-back/src/main/resources/projections/order-process.js)

Now, the events from the `order` journal need to be assigned the `CorrelationID` and directed to the responsible Coordination Office. What is important and challenging though is to ensure that the events are delivered in a reliable manner. 

#### Reliable events propagation

By reliable delivery I mean effectively-once delivery, which takes place when: 

- message is delivered **at least once** [link to ALOD]()
- message is processed (by the destination actor) **exactly-once**
- messages are processed (by the destination actor) in the order they were stored in the source journal 

Effectively-once delivery can easily be accomplished if both the sender and the receiver keep track of the messages being sent/processed. In our scenario, we already have the event-sourced Process Manager on the receiving side (Coordination Office is just a transparent proxy). The missing component is the event-sourced actor on the sending side. As it is an infrastructure level component, it will automatically be created by the Akka-DDD framework, just after the Coordination Office is started. The overall behavior of the actor that needs to be created matches the concept of the [Receptor](https://en.wikipedia.org/wiki/Transduction_(physiology)) - a sensor that reacts to a signal (stimulus), transforms it and propagates (stimulus transduction). The Akka-DDD provides implementation of the `Receptor` that supports *reliable* event propagation including the **back-pressure** mechanism.   


#### Receptor

The `Receptor` is created by the [factory method](pl.newicom.dddd.process.ReceptorSupport#receptor) based on the provided [configuration object](ReceptorConfiguration). The configuration can be build using the simple [Receptor DSL](pl.newicom.dddd.coordination.ReceptorGrammar). 

The `Receptor` actor is a [durable subscriber](). During the initialization, it subscribes itself to the event journal of the business entity that was provided as the `stimuliSource` in the configuration object. After the event has been received and stored in the receptor journal, the transormation function gets called and the result is sent to the configured receiver. The `receiverResolver` function can be provided in the configuration, if the receiver address should be obtained from the event being propagated. 

You might complain about event being stored twice in the event store (first time in the office journal, second time in the receptor journal). I have to clarify that this does not happen. The receptor is by default configured to use an **in-memory journal** and the only messages that get persisted are the snapshots of the receptor state. The snapshots get written to the snapshot store on a regular basis (every `n` events, where `n` is configurable) and contain the messages awaiting the delivery receipt.  

#### Coordination Office Receptor

Having learned how to build a receptor, it should be easy to understand the behaviour of the Coordination Office receptor by examining its [configuration](https://github.com/pawelkaczor/akka-ddd/blob/master/akka-ddd-messaging/src/main/scala/pl/newicom/dddd/saga/CoordinationOffice.scala#L14). As we can see, the receptor reacts to events from the aggregated process journal, adds the `CorrelationID` meta-attribute to the event message and propagets the event message to the Coordination Office representative actor. The name of the aggregated process journal and the `CorrelationID` resolver function are retrieved from the `ProcessConfig` object - an implicit parameter of the `office` factory method. To conclude, the Coordination Office receptor will automatically be created based on the configuration of the business process. Let's see then the [OrderProcessConfiguration](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/master/headquarters/write-back/src/main/scala/ecommerce/headquarters/processes/OrderProcessManager.scala#L31):


{% highlight scala %}

  implicit object OrderProcessConfig extends ProcessConfig[OrderProcessManager]("order", dpartment) {
    def correlationIdResolver = {
      case ReservationConfirmed(reservationId, _, _) => reservationId // orderId
      case OrderBilled(_, orderId, _, _) => orderId
      case OrderBillingFailed(_, orderId) => orderId
      case PaymentExpired(_, orderId) => orderId
    }
  }

{% endhighlight %}

The aggregated process journal was given the name: `order`. The `correlationIdResolver` function was implemented to return the `CorrelationID` from the `orderId` attribute of the event, for all events, except the `ReservationConfirmed`. For `ReservationConfirmed` event, the `CorrelationID` / `order ID` must be generated, becasue the `Ordering` process at the time the `ReservationConfirmed` event is processed, is not yet started.

#### The message flow - complete picture 

After the initial, triggering event has been received and processed by the Process Manager, the business process instance is started. Process Manager will take care of continuing the process by sending the commands to Coordination Offices and reacting to the result events.

The following diagram visualizes the flow of the commands and events within the system that occurs when the business process is running.   

![](https://pawelkaczor.github.io/images/akka-ddd/MessageFlow.svg)

Please note that reliable delivery channel is arranged automatically by the Akka-DDD framework not only between Receptor actor and Saga Manager actors but also between Process Manager and Aggregate Root actors. 

#### Business process journal

Before reacting upon an event, the Process Manager writes the event to its journal. The journal of a Process Manager is de facto a journal of a business process instance - it keeps the events related to particular business process instance in order they were processed by the Process Manager.
