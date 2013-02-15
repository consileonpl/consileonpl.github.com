---
layout: post
title: Breaking the Spring by example
categories: [spring, framework]
---
First of all, I'm not against Spring, IoC frameworks or frameworks in general. Quite the contrary, I'm big fun of many different frameworks. Said that I must admit that sometimes when a framework hides too much magic you risk loosing control of your application. Once you realize that you've just created zombie app you are afraid of, it may be too late ;) So be careful with framework selection even if you think of commonly used framework like Spring...


## Spring - ultimate IoC container
Spring Framework is one of the most popular IoC frameworks and probably the richest in terms of provided features. With every new release number of capabilities, supported technologies increases making the Spring attractive candidate for wide range of Java projects.

One would expect that using such matured, popular, battle-proofed framework should be easy and straightforward at least when it comes to its core functionality. You just annotate your beans, create configuration bean and everything should work as expected. But sometimes it doesn't... As it turns out, having large number of capabilities doesn't mean you can freely play with them, mix them and expect that Spring handles all cases seamlessly.

While working recently with Spring I've found several cases when mixing some features resulted in unexpected or undocumented behavior. I was also surprised to find out
that some features were missing and to solve the problem I had to find a workaround.

Don't have to say, the often you are being surprised by the framework, the often you are wondering if the decision of using it was correct... After all, the time you lost on learning nuances, limitations and bugs of the framework you could better spend on implementing your own infrastructure, especially if all that you need is just a small subset of what the framework provides.

Let's go to the examples.
I will show you how to make Spring surprise you (well, at least it surprised me).

## Let's break the Spring

### 1) Lazy secondary beans (using @Primary and @Lazy annotations)
Spring provides ``@Primary`` annotation that should be used to indicate `"that a bean should be given preference when multiple candidates are qualified to autowire"`. Great, that could be useful for tests. By configuring primary beans inside test configuration we could easily replace default beans from main configuration.

Main configuration:

{% highlight java %}
    @Bean
    @Lazy(true)
    public MyService myService() {
        return ... // create default service...
    }
{% endhighlight %}

Additional test configuration:

{% highlight java %}
    @Bean
    @Primary
    public MyService myTestService() {
        return ... // create service applicable in test environment
    }
{% endhighlight %}

When starting test, the test service will be instantiated. Since default service bean is configured as **lazily instantiated**, it should not be instantiated by Spring because it is not used at all, right? Well, unfortunately Spring ignores ``@Lazy`` annotation in this case. So you can be surprised if you put some heavy initialization logic inside your default service and expect that it will not be executed during the tests...

### 2) @Primary annotation and service locator
Sometimes when working with prototype scoped beans it is necessary to ask Spring for specific bean using service locator pattern. Please see example below that complements the code from example 1:

{% highlight java %}
@Component
class MyServiceFacade {
    @Autowired
    ApplicationContext context;

    public void executeMyService() {
        context.getBean(MyService.class).execute()
    }
}
{% endhighlight %}
Surprisingly Spring will throw exception when trying to run the code above complaining that two candidates of type ``MyService`` are available... This is just a bug, nothing more.

### 3) Events and prototype listeners
Spring provides support for event base communication. You can easily publish application event from one corner of your system and handle the event on the other corner by registering appropriate event listener. It works until you need your listener to be prototype scoped bean.
The Spring will notify only one instance of listener about the event, the instance that has been created during Spring initialization (when ``ContextRefreshedEvent`` is published by Spring). There is no way to inform all instantiated prototypes about the event.

### 4) Custom qualifiers and annotation-based configuration
Using annotations like ``@Qualifier`` you can control the selection of candidates among multiple matches. But default usage of ``@Qualifier`` allows only bean names (Strings) as identifiers that is error-prone and refactoring-unfriendly.

Fortunately there is another solution. You can define your own annotation that can be used as classifier. Just use ``@Qualifier`` as meta-annotation! Example of such custom qualifier you can find below:

{% highlight java %}
    @Target({ElementType.FIELD, ElementType.PARAMETER})
    @Retention(RetentionPolicy.RUNTIME)
    @Qualifier
    public @interface Genre {
      String value();
    }
{% endhighlight %}
You can than define several beans of the same type but with different qualifier type.

{% highlight xml %}
<beans>
  <bean class="example.SimpleMovieCatalog">
      <qualifier type="Genre" value="Action"/>
  </bean>
  <bean class="example.SimpleMovieCatalog">
      <qualifier type="example.Genre" value="Comedy"/>
  </bean>
</beans>
{% endhighlight %}
..and inject independently beans with different qualifiers:

{% highlight java %}
@Component
public class MovieRecommender {
  @Autowired
  @Genre("Action")
  private MovieCatalog actionCatalog;

  @Autowired
  @Genre("Comedy")
  private MovieCatalog comedyCatalog;
}
{% endhighlight %}
So far so good. Now, where is the surprise you may ask... As you probably noticed, we used xml configuration to define beans with different qualifiers. Nobody uses xml nowadays ;) so there must be a good reason to use it... The reason is that (surprise!) you can't define several beans of the same type with different custom qualifier using annotation-based configuration because it is not possible to annotate factory method with custom qualifier:
**! The code below does not compile !**
{% highlight java %}
@Configuration
public class MyConfiguration {
  @Qualifier(type="example.Genre" value="Action") // won't work, type attribute does not exist
  public MovieCatalog actionCatalog() {
    return ...// create action movies catalog
  }

  @Genre("Comedy") // won't work, you can't annotate factory method with custom qualifier
  public MovieCatalog comedyCatalog() {
      return ...// create comedy movies catalog
  }
}
{% endhighlight %}
You can only annotate the type with custom qualifier:
{% highlight java %} 
    @Component
    @Genre("Action")
    class SimpleMovieCatalog {}
{% endhighlight %}
but this approach requires new class for each qualifier type.

I don't know why Spring does not support annotating factory method inside configuration as described above. You will find only the following explanation In Spring documentation:

`"As with most annotation-based alternatives, keep in mind that the annotation metadata is bound to the class definition itself, while the use of XML allows for multiple beans of the same type to provide variations in their qualifier metadata, because that metadata is provided per-instance rather than per-class."`

### 5) Properties and annotation parameters

What's strange about the following code?

{% highlight java %} 
@Component
class MyService {
    @Scheduled(cron = "${replication.cron}")
    public void doTask1() { ... }

    @Scheduled(fixedRate = 5000)
    public void doTask2() { ... }
}
{% endhighlight %}
Configuration for scheduler 1 is read from  Properties while for scheduler 2 it is hardcoded. Why? Because you can assign property expression (which is String) only to parameters of type String. Unfortunately fixedRate parameter is of type long... The solution would be to switch to xml configuration (again? oh no..) or implement some workaround: [http://stackoverflow.com/questions/11608531/injecting-externalized-value-into-spring-annotation](http://stackoverflow.com/questions/11608531/injecting-externalized-value-into-spring-annotation).

### 6) ...

I guess if you worked with Spring you could put another case here.
Feel free to drop a comment on your biggest surprise from Spring.

[http://pkaczor.blogspot.com/2013/02/breaking-spring-by-example.html](http://pkaczor.blogspot.com/2013/02/breaking-spring-by-example.html)

{% include bio_pawel_kaczor.html %}
