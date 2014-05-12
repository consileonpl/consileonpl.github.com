---
layout: post
title: Reactive DDD with Akka - lesson 2
categories: [cqrs,ddd,akka]
---

## Recap of lesson 1

In [previous lesson](http://devblog.consileon.pl/2014/04/15/reactive-ddd-with-akka/) we have managed to implement abstraction of event sourced Aggregate Root (AR) using akka-persistence and use it to develop concrete AR class representing Reservation process. We have shown that AR is message driven component that reacts on command messages. If command (i.e `ReserveProduct`) is accepted AR produces event message representing this fact (i.e `ProductReserved`) and once the event is persisted AR sends back acknowledgment message and propagates the event to outside world. If command is rejected, AR simply responds with failure message. All messaging happens asynchronously.

Inside AR we have separated concept of AR's state (`AggregateState`) and concept of AR's state factory (`AggregateRootFactory`), both modeled as state machines that compute next state based on the current state and incoming event.

The separation of AR actor and its internal state allows looking at AR creation from two different perspective. First one is domain-centric: `AggregateRootFactory` encapsulates domain logic only. Second one is technical: AR is an actor that lives somewhere in actor system, thus, for example, it should be provided references to other actors it needs to communicate with. But how actually AR actor is created? Apparently, we have not touched this topic in lesson 1. It's time to get it cleared. The complete code for lesson 2 is available [here](https://github.com/pawelkaczor/ddd-leaven-akka/tree/Lesson2)

## Aggregate Root actor creation

In traditional DDD/CQRS architecture, command handler is responsible for creating AR and adding it to repository. When handling subsequent commands, command handler is instantiating the AR by fetching it from repository. With our new architecture we need to rethink these patterns. First of all we don't need another command handling component since AR actor is already a command handler. Secondly, repository of actors does not seem to be a good abstraction. Actors are being created, started, killed, restarted, but not added/loaded to/from repository. In Akka, they are **created and supervised by their parents**. Let's see how client's interaction with Reservation process can be simplified if we make use of **actors supervision pattern**.

### Don't call me, call my office

Going back to our sales domain and reservation process from lesson 1, each client, before creating a reservation, first had to obtain reference to actor instance (reservation actor) responsible for handling this particular reservation process. We created a method `getReservationActor` for that purpose:

{% highlight scala %}
  def getReservationActor(name: String) = {
    getActor(Props[Reservation])(name)
  }
   
  var reservation = getReservationActor(reservationId)
  reservation ! CreateReservation(reservationId, "client1")
{% endhighlight %}

From the client perspective this pattern is more complicated than it should be. The client just wants to send a command to an actor that knows how to deal with it. He should not be troubled with finding an actor he can talk to. I think it's pretty obvious now that we need a single actor serving all reservation related requests from the clients. The actor should hide the logic of passing messages between clients and reservation actors which means he should be able to manage reservation actors (create them and kill them on demand or in case of failure). In Akka this kind of relationship is called parental supervision. All actors in Akka (excluding internal top-level actors) are created by other actors (their parents) that become their supervisors.
To introduce just discovered pattern to our reservation domain we need to find some friendly and meaningful name for it. The client should not be contacted with "supervising parent of Reservation actors" but rather he should be talking to **reservation office**.

### Office and clerks

Reservation office takes care of handling reservation requests from the clients. The actual job is performed by **clerks**. Clerks are working on **cases** they are **assigned** to (where case id is aggregate id, example: "reservation-1"). AR actor is thus a clerk with assigned case.
I find this analogy quite useful but if you have a better one just drop me a comment.

Implementation of `Office` actor class should be generic, not tied to particular domain. When request (command) comes in, office should resolve/extract **case id** from the command and either find a clerk that is currently working on this case or (if there is no such clerk) create new clerk and assign him the case (this translates to creating an child actor with name equal to case id). The problem is that generic office needs to resolve case identifier from command that can be of any type. To make this possible first we need to make `Office` class parameterized (`Office[T <: AggregateRoot]`) and then apply **type class pattern** to inject function `Command => AggregateId` (`AggregateIdResolver`) via implicit constructor parameter into concrete `Office` instance. In other words, creation of office for any class of Aggregate is possible assuming there is implicitly available implementation of `AggregateIdResolver` for that class.

With the following declaration, `AggregateIdResolver` for Reservation becomes available:

{% highlight scala %}
object Reservation {

  implicit val reservationIdResolution = new ReservationIdResolution

  class ReservationIdResolution extends ddd.support.domain.AggregateIdResolution[Reservation] {
    override def aggregateIdResolver = {
      case cmd: Reservation.Command => cmd.reservationId
    }
  }
}
{% endhighlight %}

### Recipe for actor

Lets talk about actor creation in details. Actors in Akka are created from recipes (`Props` class). Recipes can be created in different ways, for example by providing class of an actor to be created and its constructor parameters (if any). This way generic office actor can construct recipe of the actor to be created if it knows its class and constructor parameters.

Now we can complete implementation of office actor. After obtaining reference to clerk actor, office actor must just forward the command to the clerk. Please see code of the `Office` class below:

{% highlight scala %}
class Office[T <: AggregateRoot(implicit classTag: ClassTag[T], caseIdResolution: AggregateIdResolution[T])
  extends ActorContextCreationSupport with Actor with ActorLogging {

  def receive: Receive = {
    case msg =>
      val caseProps = Props(classTag.runtimeClass.asInstanceOf[Class[T]])
      val clerk = assignClerk(caseProps, resolveCaseId(msg))
      clerk forward msg
  }

  def resolveCaseId(msg: Any) = caseIdResolution.aggregateIdResolver(msg)

  def assignClerk(caseProps: Props, caseId: String): ActorRef = getOrCreateChild(caseProps, caseId)
  
}
{% endhighlight %}

We need yet helper function that creates office as top-level actor:

{% highlight scala %}
def office[T <: AggregateRoot[_]](implicit classTag: ClassTag[T], system: ActorRefFactory): ActorRef = {
  system.actorOf(Props(new Office[T]), name = officeName(classTag))
}
{% endhighlight %}

Finally the client can send reservation commands to reservation office instead of individual clerk:

{% highlight scala %}
  val reservationOffice = office[Reservation]

	reservationOffice ! CreateReservation("reservation1", "client1")
  reservationOffice ! ReserveProduct("reservation1", "product1", 1)
{% endhighlight %}

### Firing of clerks 

The question arises what happens to clerk actors after they finish processing the command(s) and become idle. Well, nothing, they live (in memory) until they are stopped. Thus, we should take care of dismissing clerks that are idle. This can be easily achieved by defining inactivity timeout after which the clerk is notified with `ReceiveTimeout` message. Being notified, clerk should dismiss (stop) himself or, to avoid dropping commands just enqueued in his inbox, ask office to dismiss him gracefully. This pattern/protocol is called graceful passivation. Because all Aggregate Roots should support this pattern, `AggregateRoot` class has been enriched with [GracefulPassivation](https://github.com/pawelkaczor/ddd-leaven-akka/blob/Lesson2/src/main/scala/infrastructure/actor/GracefulPassivation.scala) trait. Currently [Office](https://github.com/pawelkaczor/ddd-leaven-akka/blob/Lesson2/src/main/scala/ddd/support/domain/Office.scala) class does not fully implement graceful passivation of clerks (clerks are stopped, but enqueued messages might be lost) but don't worry, Akka provides much more robust implementation of office pattern: akka-sharding. Akka-sharding does not only supports graceful passivation, but first of all allows office to work in distributed environment.

## Global office

Single office is limited by available resources (cpu, memory) so it can handle limited number of requests concurrently. Logical global office consisting of branch offices distributed among different locations will perform much better under high workload. Each branch office should be delegated to work on subset of cases. This is the idea of sharding where branch office is a shard. Akka-sharding takes care of distributing shards among available nodes in the cluster according to given **shard allocation strategy**. Default strategy allocates new shard to node with least number of allocated shards. The intention is to make workload distributed **evenly** across all nodes in the cluster. If new nodes are added to the cluster, shards are being rebalanced. Because shards are not tied to single machine, state of the actors needs to be distributed as well. This means akka-persistence must be configured with a **distributed journal**.

Let's see how global reservation office can be created in Akka using akka-sharding.

### Testing global reservation office

Thanks to **sbt-multi-jvm** plug-in and `MultiNodoSpec` writing cluster-aware tests in Akka is surprisingly easy. We will not dive into details of cluster configuration but concentrate on sharding. [ReservationGlobalOfficeSpec](https://github.com/pawelkaczor/ddd-leaven-akka/blob/Lesson2/src/multi-jvm/scala/ecommerce/sales/domain/reservation/ReservationGlobalOfficeSpec.scala) is the test we are going to discuss now. As you can see, at startup, shared journal is configured and cluster is started (consisting of two nodes). Please note that sbt-multi-jvm plug-in will automatically execute the same test on each node concurrently.

The following method is executed on each node to start sharding:

{% highlight scala %}
  startSharding[Reservation](new Reservation.ReservationShardResolution {
    //take last char of reservationId as shard id
    override def shardResolutionStrategy: ShardResolutionStrategy =
      addressResolver => {
        case msg: Msg => addressResolver(msg).last.toString
      }
  })
{% endhighlight %}

`startSharding` is a method that actually starts sharding by invoking 

{% highlight scala %}
ClusterSharding(system).start(
  typeName = arClass.getSimpleName,
  entryProps = Some(arProps),
  idExtractor = shardResolution.idExtractor,
  shardResolver = shardResolution.shardResolver
)
{% endhighlight %}

Akka-sharding requires `IdExtractor` and `ShardResolver` to be defined for AR that is going to be shared. Logic of `IdExtractor` we have already encapsulated in `AggregateIdResolution`. Now we will introduce abstract class `ShardResolution` that extends `AggregateIdResolution` and defines `shardResolver` that extracts **shard id** from the command. This logic is implemented as composition of `shardResolutionStrategy` and `aggregateIdResolver`:

{% highlight scala %}
abstract class ShardResolution[T] extends AggregateIdResolution[T] {
  type ShardResolutionStrategy = AggregateIdResolver => ShardResolver
 
  def shardResolutionStrategy = defaultShardResolutionStrategy
  val shardResolver: ShardResolver = shardResolutionStrategy(aggregateIdResolver)
  val idExtractor: IdExtractor = {
    case msg: Msg => (aggregateIdResolver(msg), msg)
  }
}
{% endhighlight %}

Default shard resolution strategy (available in `ShardResolution` companion object) returns first char from hexadecimal hashcode generated from aggregateId. This means up to 16 shards can be created (0-9 and A-F) (see [http://guide.couchdb.org/draft/clustering.html#hashing](http://guide.couchdb.org/draft/clustering.html#hashing) to learn more about **consistent hashing** in context of sharding).

Shard resolution strategy in the test however (see code above) is different. It takes just last character from aggregateId. Thus in the first test we expect two reservations "reservation-1" and "reservation-2" being assigned to clerks working on different nodes:

{% highlight scala %}
  "distribute work evenly" in {
    val reservationOffice = globalOffice[Reservation]

    on(node1) {
      expectEventPublished[ReservationCreated] {
          reservationOffice ! CreateReservation("reservation-1", "client1")
          reservationOffice ! CreateReservation("reservation-2", "client2")
      }
    }

    on(node2) {
      expectEventPublished[ReservationCreated]
    }
  }
{% endhighlight %}

The instance of reservation office is not our previously implemented `Office` actor but actor created by akka-sharding (helper method `globalOffice` takes care of that). During the test two requests for creating reservations "reservation-1" and "reservation-2" are sent from node 1. We expect that exactly one request will be processed on both nodes. After both requests are processed, we verify if subsequent requests are correctly processed if sent from a different node than creation requests:

{% highlight scala %}
  "handle subsequent commands from anywhere" in {
    val reservationOffice = globalOffice[Reservation]

    on(node2) {
      expectReply(Acknowledged) {
        reservationOffice ! ReserveProduct("reservation-1", "product1", 1)
      }
      expectReply(Acknowledged) {
        reservationOffice ! ReserveProduct("reservation-2", "product1", 1)
      }
    }
  }
{% endhighlight %}

With this test we complete lesson 2.

In next lesson we will try to build views so that our application can respond to queries.

[http://pkaczor.blogspot.com/2014/04/reactive-ddd-with-akka-lesson-2.html](http://pkaczor.blogspot.com/2014/04/reactive-ddd-with-akka-lesson-2.html)

{% include bio_pawel_kaczor.html %}
