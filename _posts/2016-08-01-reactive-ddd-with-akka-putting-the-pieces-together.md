---
layout: post
title: Reactive DDD with Akka - putting the pieces together
categories: [cqrs,ddd,akka]
---

#### Introduction

In this episode we will learn how to assemble a subsystem that encapsulates functionality of a sub-domain of an e-commerce enterprise. The subsystem will be built on top of the Akka platform following a [CQRS/DDDD](http://abdullin.com/post/dddd-cqrs-and-other-enterprise-development-buzz-words)-based approach. We will use the [Akka-DDD](https://github.com/pawelkaczor/akka-ddd) framework, as it already implements concepts discussed [previously](http://pkaczor.blogspot.com/2014/04/reactive-ddd-with-akka.html), such as `Aggregate Root` and `Office`, and also provides other goodies (see the [Readme](https://github.com/pawelkaczor/akka-ddd/blob/master/README.md) page for the details). 

The primary goal is to get familiar with the code structure of a concrete subsystem / service implementation before we take a deep dive into the topic of inter-service communication (business processes) in the next episode. 

#### Subsystem components

As the architecture of the service adheres to the CQRS pattern, the subsystem will consist of the independent write- and read-side applications as presented on the following diagram:    

![](https://docs.google.com/drawings/d/12Lwwq3WROlu2pkXsIwICQvuWiPNKW5XQwc7bRtLaauI/pub?w=722&amp;h=620)

On the write-side, the **commands** (in the form of HTTP POST requests) gets accepted by the **write-front** application and forwarded to the backend cluster (**write-back** applications) for processing. If a command succeeds, then the resulting event gets stored to the Event Store. 

On the read-side, the **queries** (in the form of HTTP GET requests) gets accepted and executed against the View Store by the **read-front** application. The **read-back** application hosts the View Update Service, responsible for updating the View Store in reaction to the events streamed from the Event Store.

All applications can be started / restarted independently of each other.   

#### The Sales Service

Let's checkout the code of the [Sales Service](https://github.com/pawelkaczor/ddd-leaven-akka-v2/tree/20160731/sales), that is one of the services of a sample e-commerce system developed under the [ddd-leaven-akka-v2](https://github.com/pawelkaczor/ddd-leaven-akka-v2) project.

The `Sales` sub-domain of the e-commerce enterprise covers the preliminary phase of the `Order Process` during which a customer adds or removes products to his/her shopping-cart and eventually confirms or cancels the order. To fulfill this functionality the `Sales Service` exposes a `Reservation` office.

#### The contract of the Reservation Office

The protocol/contract that the `Reservation` office publishes to the outside world consists of commands (the `Reservation` office is ready to handle) and events (the `Reservation` office is writing to its journal) together with referenced, [shared](http://ddd.fed.wiki.org/view/shared-kernel) domain objects (such as Product and Money). All these classes are contained in the [contracts](https://github.com/pawelkaczor/ddd-leaven-akka-v2/tree/20160731/sales/contracts) module which other write- and read-side modules depend on. A client application (that wishes to send a command) or a service consumer (for example a `Receptor` from another subsystem that subscribes to the `Reservation` events) must adhere to the contract.
As different subsystems can get released / redeployed independently (which is a great advantage over the monolith system), changes in the contract of one service can break its consumers. Therefore in the long run, it is necessary to apply [schema evolutions techniques](http://doc.akka.io/docs/akka/current/scala/persistence-schema-evolution.html), such as schema versioning or extensible serialization formats.

Akka-DDD supports json format as it is natively supported by the underlying [Event Store provider](https://geteventstore.com/). The currently used json library is [Json4s](http://json4s.org/). If you implement the commands and events as simple Scala `case classes` (no polymorphic lists, no Scala's Enumeration, etc) you don't need to worry about serialization layer at all. If for some reason, you need to deal with such "extensions", don't forget to provide the `serialization hints` by [implementing](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/contracts/src/main/scala/ecommerce/sales/SalesSerializationHintsProvider.scala) and [registering](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/contracts/src/main/resources/reference.conf#L1) the `JsonSerializationHintsProvider` class.

The office should also publish its identifier to be used across the system by the service consumers and client applications.  
The office identifier should allow obtaining the identifier of the office journal and the identifiers of the journals of the individual clerks.

Akka-DDD provides the [RemoteOfficeId](https://github.com/pawelkaczor/akka-ddd/blob/31.07.2016/akka-ddd-messaging/src/main/scala/pl/newicom/dddd/office/Office.scala#L19) class to be used for that purpose:

The [identifier](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/contracts/src/main/scala/ecommerce/sales/package.scala#L7) of the Reservation office is shown below:

{% highlight scala %}
  RemoteOfficeId(
    id           = "Reservation",
    department   = "Sales",
    messageClass = classOf[sales.Command]
  )
{% endhighlight %}

The `messageClass` property defines the base class of all message classes that the office is ready to handle (this information helps to auto-configure the command dispatching that is performed by the write-front application).


#### The Sales Service backend application [write-back] 

The executable [SalesBackendApp](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/write-back/src/main/scala/ecommerce/sales/app/SalesBackendApp.scala) class, located in the `write-back` module, starts the `Sales` Actor System based on provided [configuration file](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/write-back/src/main/resources/application.conf). The configuration must contain the following entries:
 
 * entries that enable Akka Cluster capabilities,
 * entry that enables [Cluster Client Receptionist](http://doc.akka.io/docs/akka/2.4.8/scala/cluster-client.html) extension, 
 * entries that indicate the journal and the snapshot-store plugins. 

 The Cluster Client Receptionist extensions allows direct communication between actors from the write-front application and the backend cluster.  

The [startup](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/write-back/src/main/scala/ecommerce/sales/app/SalesBackendApp.scala#L22) procedure of the `Sales Service` backend application is straightforward. First the `Sales` Actor System joins the cluster using seed nodes. Addresses of the seed nodes are obtained from a file that is specified using the `APP_SEEDS_FILE` environment variable. If the file is missing, the address is constructed from the `app.host` (defaults to `localhost`) and `app.port` configuration entries. Then the `Reservation` office gets created:

{% highlight scala %}
	OfficeFactory.office[Reservation]
{% endhighlight %}


Assuming the `newicom.dddd.cluster` package object is available in the scope of the startup procedure (the package object is imported), the actual office creation is delegated to the cluster-aware / sharding-capable [OfficeFactory](https://github.com/pawelkaczor/akka-ddd/blob/31.07.2016/akka-ddd-core/src/main/scala/pl/newicom/dddd/cluster/ShardingSupport.scala#L13) object that is injected automatically as an implicit argument of the `office` method. The office factory requires a clerk factory and a shard allocation strategy to be implicitly provided for the given AggregateRoot (clerk) class. For the `Reservation` these objects are defined in the [SalesBackendConfiguration](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/write-back/src/main/scala/ecommerce/sales/app/SalesBackendConfiguration.scala) trait that the `SalesBackendApp` mixes-in. The [Office](https://github.com/pawelkaczor/akka-ddd/blob/31.07.2016/akka-ddd-messaging/src/main/scala/pl/newicom/dddd/office/Office.scala#L33) object that is eventually created contains the office identifier and the address (in the form of an ActorPath) of the office representative Actor.


##### The Reservation clerk (Aggregate Root) 

Implementation of the [Reservation](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/write-back/src/main/scala/ecommerce/sales/Reservation.scala) clerk and the corresponding [test](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/write-back/src/test/scala/ecommerce/sales/ReservationSpec.scala) is rather simple and self-explaining. 

Please note that the office factory requires one more parameter to be implicitly provided for the given clerk class: the local office identifier ([LocalOfficeId](https://github.com/pawelkaczor/akka-ddd/blob/31.07.2016/akka-ddd-messaging/src/main/scala/pl/newicom/dddd/office/Office.scala#L27)). This is an alternative form of the office identifier, prescribed to be used locally, within the write-back application. The local office identifier must indicate the class of the clerk, so the best place to define it, is the companion object of the clerk class (see [Reservation#officeId](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/write-back/src/main/scala/ecommerce/sales/Reservation.scala#L14)).  

#### The write-front application

Most of the building blocks of the write-front application is provided by the `akka-ddd-write-front` module that is part of the Akka-DDD framework. 

##### The Command Dispatcher

The Command Dispatcher is the core component of the write-front application. [CommandDispatcher](https://github.com/pawelkaczor/akka-ddd/blob/31.07.2016/akka-ddd-write-front/src/main/scala/pl/newicom/dddd/writefront/CommandDispatcher.scala) trait takes care of forwarding the incoming commands to the appropriate offices based on the provided remote office identifiers. The forwarding is performed using the [Cluster Client](http://doc.akka.io/docs/akka/2.4.8/scala/cluster-client.html) (`ClusterClientReceptionist` extension must be enabled).  

##### The HTTP Command Handler

To make the offices available to the wide range of client applications, the write-front application should accept commands in the form of HTTP POST requests. The [HttpCommandHandler](https://github.com/pawelkaczor/akka-ddd/blob/31.07.2016/akka-ddd-write-front/src/main/scala/pl/newicom/dddd/writefront/HttpCommandHandler.scala) is the component that implements all the steps of the command handling logic in the write-front application. First of all it takes care of unmarshalling the command from the incoming request. The request must contain `Command-Type` attribute in its header, to indicate the class of the command that is passed in the request body. JSON is the expected format in which the command is encoded. Once the command is unmarshalled, the HTTP Command Handler passes it further to the Command Dispatcher. Eventually, once the command is processed on the backend and the response is received from the office (asynchronously), the handler converts it to an appropriate HTTP response that needs to be returned to the client. 

The processing logic encapsulated in the HTTP Command Handler, is exposed as the [Akka HTTP](http://doc.akka.io/docs/akka/2.4/scala/http/index.html) `Route` object being the result of calling the `handle` method:

{% highlight scala %}
  def handle[A <: Command](implicit f: Formats): Route
{% endhighlight %}

The route returned by the HTTP Command Handler, is a building block of the complete route that needs to be implemented by the write-front application. Thanks to the Akka HTTP the complete http handler can be easily assembled. Just take a look at the `route` method of the [write-front HTTP Server](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/write-front/src/main/scala/ecommerce/sales/app/HttpService.scala#L31) of the Sales Service:

{% highlight scala %}
  def route = 
    pathPrefix("ecommerce") {
      path("sales") {
        handle[ecommerce.sales.Command]
      }
    }
{% endhighlight %}

And that's all for now when it comes to the write side of the system. We didn't cover Receptors and Sagas which are to be presented in the forthcoming episode. 

To test if the write side of the Sales Service is operating properly we can start the `sales-write-back` and `sales-write-front` applications (see the [Wiki](https://github.com/pawelkaczor/ddd-leaven-akka-v2/wiki) for detailed instructions) and send a `CreateReservation` command. We will use [httpie](http://httpie.org/) for this:

{% highlight bash %}
http :9100/ecommerce/sales Command-Type:ecommerce.sales.CreateReservation reservationId="r1" customerId="customer-1"
{% endhighlight %}

Hopefully you get the successful result (200 OK).  

#### The Sales View Update Service [read-back]

The view side of the system is not that much interesting as the write side. Again, the logic of the processing is provided by the Akka-DDD. Please see a big picture of the [View Update Service](https://github.com/pawelkaczor/akka-ddd/wiki/View-Update-Service). In order to create a View Update Service for the SQL-based View Store provider, we need to extend the [SqlViewUpdateService](https://github.com/pawelkaczor/akka-ddd/blob/31.07.2016/view-update-sql/src/main/scala/pl/newicom/dddd/view/sql/SqlViewUpdateService.scala) abstract class and provide simple configuration objects. The configuration object defines a sequence of projections for a given office (see: [SalesViewUpdateService](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/read-back/src/main/scala/ecommerce/sales/SalesViewUpdateService.scala)). The implementation of the projection is self-documenting: 

{% highlight scala %}
class ReservationProjection(dao: ReservationDao)(implicit ec: ExecutionContext) extends Projection {

  override def consume(eventMsg: OfficeEventMessage): ProjectionAction[Write] = {
    eventMsg.event match {

      case ReservationCreated(id, clientId) =>
        val newView = ReservationView(id, clientId, Opened, new Date(now().getMillis))
        dao.createOrUpdate(newView)

      case ReservationConfirmed(id, clientId, _) =>
          dao.updateStatus(id, Confirmed)
    }
  }
}
{% endhighlight %}

The `consume` method must return an instance of a parameterized `ProjectionAction[E <: Effect]` which is a type alias of [slick.dbio.DBIOAction[Unit, NoStream, E]](http://slick.lightbend.com/doc/3.0.0/dbio.html)    

Projections can easily be tested using the in-memory H2 database. See the [ReservationProjectionSpec](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/read-back/src/test/scala/ecommerce/sales/view/ReservationProjectionSpec.scala).

#### The Reservation View Endpoint [read-front]  

Finally we need to expose the views to the client applications via HTTP interface. This is a role of the read-front application. The HTTP server is implemented using Akka-HTTP in similar way as for the write-front application. The abstract `route` method that is defined in the abstract [ViewEndpoint](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/read-front/src/main/scala/ecommerce/sales/ReadEndpoint.scala) must be implemented. The method takes `viewStore` of type `slick.jdbc.JdbcBackend` as an input parameter. The view is serialized using json format before it is returned to the client. Please see the implementation of the [ReservationViewEndpoint](https://github.com/pawelkaczor/ddd-leaven-akka-v2/blob/20160731/sales/read-front/src/main/scala/ecommerce/sales/app/ReservationViewEndpoint.scala). Note that the view access layer is reused from the read-back application. 

After starting the `sales-read-back` and `sales-read-front` applications we should be able to fetch a view of the Reservation, that we created previously, using a http client: 

{% highlight bash %}
http :9110/ecommerce/sales/reservation/r1
{% endhighlight %}

#### "Microservices come in systems"

Since ["One microservice is no microservice"](https://www.youtube.com/watch?v=PYXqVbVCIBA), in the next episode, we will see how to implement a business logic that can't be fulfilled by Sales Service alone. Stay tuned.

[http://pkaczor.blogspot.com/2016/08/reactive-ddd-with-akka-putting-the-pieces-together.html](http://pkaczor.blogspot.com/2016/08/reactive-ddd-with-akka-putting-the-pieces-together.html)

{% include bio_pawel_kaczor.html %}