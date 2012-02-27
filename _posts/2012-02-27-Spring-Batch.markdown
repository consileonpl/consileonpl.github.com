---
layout: post
title: Saga vs Batch Processing (Spring Batch introduction)  
categories: [spring, ddd]
---

When dealing with business process often some state transitions are not immediately executed as result of 
human interaction but rather being scheduled for future execution. One example could be expiration of Payment Period (see [previous blog](http://devblog.consileon.pl/2011/08/02/Axon-Framework-DDD-EDA-meet-together/) for domain description).

Modelling such process execution flow explicitly in the code is the right thing to do if we want to keep process logic maintainable and self describing. 
That's why we should apply bpm tools or Saga pattern (if we prefer simple and light-weight solution) to do the job.

## Scheduling activity within Saga
The following code shows how to schedule activity within Saga ([Axon](http://www.axonframework.org/) implementation):

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
When (current) Payment Period is created, ``RenewPaymentPeriodCommand`` is scheduled for execution on time when the period expires (after validation interval passes). This approach is clean, easy to implement and test but...requires (mind) shifting from procedural way of modelling business logic (see transaction script) towards event driven architecture (EDA). For those who are not yet ready to enter EDA and bpm, there is an old-time heavy-weight, bullet-proof way of executing scheduled tasks on certain time: batch processing. 

## Batch processing
Batch processing is suitable for optimizing execution of high-volume, repetitive tasks in such way that system is under heavy load only within relatively short time window (batch window). (See http://en.wikipedia.org/wiki/Batch_processing)

Our goal will be to execute Payment Period renewal in batch mode. Instead of scheduling each Payment Period renewal explicitly in the business process (saga), batch job (``RenewPaymentPeriodsJob``) scheduled to run repeatedly (every hour or day depending on requirements) will invoke ``RenewPaymentPeriodCommand`` for all expired Payment Periods that it will find in database.
We will only change processing mode but will not touch business logic that will be still encapsulated inside of aggregate roots and event listeners. We will use the same commands dispatching mechanism that is used for online transactions processing avoiding creation of specialized services or using sql statements to implement batch jobs (as one could expect from batch jobs:) ).

Running jobs in batch mode gives more control over system load. It can be controlled how often and when batch jobs should be run. In Saga, execution model is different, operations are executed automatically and there is no control mechanism at runtime. Which way is better..? As always, depends. But it is good to have both alternatives ready to apply when time comes...

Lets see how to use **Spring Batch**, modern batch framework for JVM, to apply batch processing using commands and queries as building blocks.

## Spring Batch processing model

![Batch stereotypes](http://static.springsource.org/spring-batch/reference/html-single/images/spring-batch-reference-model.png)

The diagram above highlights the key concepts that make up the domain language of batch. A Job has one step or combines multiple steps that belong logically together in a flow. Each step has exactly one ``ItemReader``, ``ItemProcessor``, and ``ItemWriter``. A Job needs to be launched (``JobLauncher``), and meta data about the currently running process needs to be stored (``JobRepository``).

Spring Batch uses a "Chunk Oriented" processing style within its most common implementation. Chunk oriented processing refers to reading the data one at a time, and creating 'chunks' that will be written out, within a transaction boundary. Committing a transaction, at each commit interval, commits a 'chunk'.

The data item could be line in a file or record in a database table but Spring Batch integrates modern to-object mapping frameworks so we don't have to dirty our hands by manipulating low-level data.

![Chunk oriented processing](http://static.springsource.org/spring-batch/reference/html-single/images/chunk-oriented-processing.png)

## Spring Batch application
Our goal is to use Aggregate Roots as processing items. To build batch step we need to implement an ``ItemReader`` that will fetch ARs (entities) from database by executing provided query and an ``ItemProcessor`` that will build a command based on AR data and dispatch command to the system. Since batch processing is performed transactionally (chunks are automatically committed by Spring Batch with use of provided transaction manager) commands need to to be dispatched synchronously. This logic of batch step may be shared across different jobs as long as the concept of ``ItemReader`` responsible of fetching ARs using provided query and ``ItemProcessor`` responsible for dispatching command is preserved. What will distinguish different steps from each other is query specification and command to be executed.

So lets define interface that will describe these responsibilities of batch step:

{% highlight java %}
public interface BatchStepSpecification <C extends Command, R> {

	C getCommand(R queryResultItem);
	
	QuerySpecification<R> getQuerySpecification();
}
{% endhighlight %}
``BatchStepSpecification`` object should be able to provide query specification (executable by ``ItemReader``, more on query specifications in a moment) and build ``Command`` (for each AR to be processed) executable by ``ItemProcessor``.

Now we need to implement ``ItemReader`` and ``ItemWriter`` that will use step specification to do their job.

## ItemReader

To avoid keeping all entities to be processed in memory (this could be a large set) Spring Batch offers two solutions: Cursor and Paging database ``ItemReader``s. Let's go with the letter one. For loading entities from database in a paging fashion Spring Batch provides several implementations of ``AbstractPagingItemReader`` one of them being ``JpaPagingItemReader`` for fetching JPA entities. ``JPAPagingItemReader`` allows you to define query by providing JPQL statement. But we want our queries be more maintainable and composable. Therefore I recommend to represent JPA queries as [Specifications](http://domaindrivendesign.org/node/87). This is possible with use of [Spring Data JPA](http://www.springsource.org/spring-data/jpa) module. Specification can be translated into JPA Query in the following way:

{% highlight java %}
public Query createQuery(QuerySpecification<? extends Entity> spec) {
	CriteriaBuilder builder = getEntityManager().getCriteriaBuilder();
	CriteriaQuery criteriaQuery = builder.createQuery(spec.getResultClass());
	Root root = criteriaQuery.from(spec.getResultClass());
	criteriaQuery
                .where(
                    spec.toPredicate(root, criteriaQuery, builder)
                )
                .select(root);
	return getEntityManager().createQuery(criteriaQuery);
}
{% endhighlight %}
More about specifications you can read here: [Advanced Spring Data JPA – Specifications And QueryDSL](http://blog.springsource.org/2011/04/26/advanced-spring-data-jpa-specifications-and-querydsl/).

Implementing ``SpecificationPagingReader`` is straightforward. Main thing to do is to implement ``doReadPage()`` method:

{% highlight java %}
class SpecificationPagingReader extends AbstractPagingItemReader<Entity> {
//[...]
	private Specification querySpecification;

	@Override
	@Transactional(readOnly=true)
	public void doReadPage() {
		//[...]
		Query query = createQuery(querySpecification).setFirstResult(getPage() * getPageSize()).setMaxResults(getPageSize());
		results.addAll(query.getResultList());
	}
}
{% endhighlight %}
Finally, we can define our ``ItemReader`` in Spring context:

{% highlight xml %}
<bean id="reader" scope="step" class="a.b.c.SpecificationPagingReader"
    p:entityManagerFactory-ref="entityManagerFactory"
    p:querySpecification="#{stepSpecification.querySpecification}"
    p:pageSize="2000"
/>
{% endhighlight %}
The instance of ``SpecificationPagingReader`` will be created automatically by Spring whenever batch step is executed. This is the magic of **step** scope provided by Spring Batch. It allows late (dynamic) binding of properties. In our case ``stepSpecification`` is unknown until particular step is executed (more details ahead).

## ItemProcessor

``ItemProcessor`` interface defines just one method. The implementation in our case is simple:

{% highlight java %}
class EntityProcessor implements ItemProcessor<Entity, Entity> {
	private CommandBus commandBus;
	private BatchStepSpecification<Command, Entity> stepSpecification;
	
	@Override
	public Entity process(Entity item) throws Exception {
		Command command = stepSpecification.getCommand(item);
		commandBus.dispatch(command);
		return item;
	}
}
{% endhighlight %}
And Spring bean definition: 
{% highlight xml %}
<bean id="processor" scope="step" class="a.b.c.EntityProcessor"
	p:commandBus-ref="commandBus"
	p:stepSpecification="#{stepSpecification}"
/>
{% endhighlight %}

## ItemWriter

``ItemWriter`` must be provided as well but it can be empty implementation assuming all changes to ARs are flushed to database as a result of command processing within the service.

Finally we are able to build batch step that will be reused by concrete batch jobs.

## Batch Step

{% highlight xml %}
<step id="abstractBatchStep" abstract="true">
    <tasklet>
	<chunk reader="reader" processor="processor" writer="writer" 
	    commit-interval="10" skip-limit="5">
	    <skippable-exception-classes>
	        <include class="java.lang.Exception"/>
	    </skippable-exception-classes>
	</chunk>
    </tasklet>
</step>
{% endhighlight %}
Here, we compose three beans (reader, processor, writer) and additionally provide following parameters:
 - skip-limit - the maximum number of items that will be allowed to be skipped (in case the processing of item ends with exception). Once the skip limit is reached, the next exception found will cause the step to fail.
 - commit-interval - how many items will be processed in one transaction (chunk size), value > 1 might increase performance, but also could result in rollback of successfully processed ARs (if exception skip limit is reached)
 - skippable-exception-classes - exceptions that will result in skipping the processed entity instead of step failure

## Job registry

Now we can define our jobs. The easiest way is to use ``AutomaticJobRegistrar`` class. Registration in this case is performed automatically on application start-up, based on defined path under which spring context files containing jobs definitions are located. By putting each job bean into separate spring context file we are able to provide its ``stepSpecification`` bean that will be created when job's step is executed. If all those files were imported into the same context, the ``stepSpecification`` definitions would clash and override one another, but with the automatic registrar this is avoided.

Please see example definition of batch job:

{% highlight xml %}
<job id="renewPaymentPeriodsBatchJob">
    <step id="renewPaymentPeriodsJob" parent="abstractBatchStep"/>
</job>
<bean id="stepSpecification" class="a.b.c.RenewPaymentPeriodsBatchStepSpecification" />
{% endhighlight %}
As shown above, creating new batch job is just a matter of creating new spring context file containing job id (globally unique), step id and step specification bean. Nothing more is required. The solution is powerful and simple but has one limitation. We can not create jobs with several steps, each one configured with different ``BatchScopeSpecification``. For example:

{% highlight xml %}
<job id="accountsMaintenanceJob" parent="abstractBatchJob">
    <step id="step1">
    	<job ref="endAccountsBatchJob"/>
    	<next on="*" to="step2" />
    </step>
    <step id="step2">
    	<job ref="renewPaymentPeriodsBatchJob"/>
    </step>
</job>
{% endhighlight %}
I found a solution for this problem, in case you are interested, let me know by dropping in a comment. 

## Job execution

To execute a ``Job``, we need to create ``JobParameters`` object and use ``JobLauncher`` to run ``Job`` with created parameters. Please refer to [description of artifacts](http://static.springsource.org/spring-batch/reference/html/domain.html#domainJob) related to batch job execution. It is important to understand differences between ``Job``, ``JobInstance`` and ``JobExecution``.

Things to remember:

 - **JobInstance** = the concept of a logical job run (``Job`` + ``JobParameters``)
 - **JobExecution** = a single attempt to run ``JobInstance``. ``JobInstance`` corresponding to a given execution will not be considered complete unless the execution completes successfully. There can be more than one failed ``JobExecutions`` but only one successful execution of given ``JobInstance``.

## Batch jobs scheduling

Spring Batch is not a scheduling framework. It is entirely up to the scheduler to determine when a Job should be run. There is no requirement that one ``JobInstance`` be kicked off after another, unless there is potential for the two job instances to attempt to access the same data, causing issues with locking at the database level. But attempting to run the same ``JobInstance`` while another is already running will result in a ``JobExecutionAlreadyRunningException`` being thrown.

## Other Spring Batch Goodies

 - **Restartability** - the framework periodically persists the ``ExecutionContext`` at commit points. This allows the ``ItemReader`` to store its state in case a fatal error occurs during the run, or even if the power goes out. ``JpaPagingItemReader`` supports restart by storing item count, therefore requires item ordering to be preserved between runs.
 - **Non Sequential Step Execution** - conditional flow of steps
 - **Partitioning** - ``JobOperator`` interface for common monitoring tasks such as stopping, restarting, or summarizing a Job, as is commonly done by batch operators.


[http://pkaczor.blogspot.com/2012/02/saga-vs-batch-processing-spring-batch.html](http://pkaczor.blogspot.com/2012/02/saga-vs-batch-processing-spring-batch.html)

{% include bio_pawel_kaczor.html %}
