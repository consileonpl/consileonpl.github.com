---
layout: post
categories: [tdd, ruby]
title: Unit or integration testing?
---
Lately we are experiencing a holy war between [TDD followers][1] and those
that stands [against it][2]. As a strong believer in OOP principles I should
consider myself a TDD follower. However I think that the truth, as always,
lies somewhere in between. I practice TDD only in a parts of an application, that
I think makes sense to drive its design from tests. I'm not trying obsessively
write tests first, because sometimes I simply can't. Also I'm not trying to
unit test everything. I believe there are parts that can and should be unit
tested and some not. I'm trying to get best from both worlds.

So I've decided to describe my understanding on how and what to test and when to TDD.

## Application borders

The key to understanding what to test as an unit and what requires integration
testing is knowing that each application has its borders. What lies inside the
borders you can call a core of an application and what lies outside the borders you
can call... well it doesn't matter how you call it. The point is that the majority
of your testing and design efforts should focus on the core of the application.
Also it is very important to ensure that all dependencies cross borders in same
direction. Dependencies should go from your core to whatever lies beyond application
borders.

The core of an application is all the services, interactors, business objects,
however you call it, that implements your domain, business logic. All other stuff
like framework, routing, database, external API's, file system, external libraries, presentation
layer are just supporting your core.

Given that what you should TDD and unit test is all your core logic. And the reason
behind that is not tests speed. The tests speed is a benefit that
we gain for free when we unit test in isolation. The reason is that when you
unit test in isolation you have greater control over all the conditions that
may happen on the borders of a system that you mock. It is much easier to simulate certain
situations. It is easier to instruct a mock object to return certain response
than to instruct external API. Sometimes you don't even have
any sandbox/test environment which you can call in your tests.

TDD works well in designing your core application logic. Classes are small,
decoupled and easy to test. Tests speed is for free.

In contrast everything that lies on and outside borders should be tested in integration.
There is no point to unit test Rails controllers or views. Similarly there is
no point to unit test ActiveRecord stuff like scopes. It really doesn't matter that
a scope creates a query that you've expected, by calling appropriate ActiveRecord methods,
unless you execute that query against the real database and ensure it is valid
and returns proper records.

The point is that you must ensure that your core application logic integrates
well with the outside world. You really don't need to test every single
case that may happen, leave that for unit tests if possible. Ensure that
everything together works fine and you've done with integration tests.

## When application borders blur

I think this is the cause of all misunderstanding in the whole against TDD story.
The problem is that Rails blurred application borders. In fact core logic lies
either in controllers or in models. We can say that the framework drives our
design.

It is fine for simple, small to medium sized applications and whenever you need
fast prototype. If you are in this situation do not fight against the framework
design instead embrace it. However if your business logic is complex and you
expect that size of your application will be from medium to large driving
application design by the framework is not a good idea. You will die somewhere
between 2000 and 6000 line of code of `User` class with hundred callbacks.

When application borders are not clearly defined you shouldn't unit test. Its
pointless as mocking all the details will kill you (have you ever mocked chain of
ActiveRecord calls?). Driving design by tests
is also pointless as framework already drives your design and they will conflict.

However if your application logic is fairly complex you will need something that
wraps the core logic and clearly defines borders. Concerns that were introduced
to Rails are not a good answer to that problem in my opinion. Concerns, which
are nothing else but mixins, are form of inheritance and you really want to
avoid inheritance if possible (and use aggregation instead). Here driving core
logic design with TDD is perfectly fine. Everything else doesn't need TDD-ing.

Driving design by integration/system tests is pointless. They are too general.
Too abstract.

## Where are my borders?

In typical Rails application controllers are your borders. ActiveRecord models are
borders. Everything that calls external API's and filestem are borders. Calling
a class from a gem may be considered as a border, but it is not always a case, so
you need good judge in this regard.

None of the above is particularly good to unit test. And also you cannot drive
the design as the framework or the API's already picked design for you.

Models should be tested against the database, to ensure that queries works well.
Routing and views are best tested via the tools like Capybara. There is no point to
mock out HTTP protocol.

If you call gem's like Faraday or RestClient, even standard Net::HTTP you really want to
wrap those with your own object like HttpClient. The reasoning is that **you want
to mock (in your core) only classes that you own**. If you mock things from the
libraries (even standard) you may fall into a situation that all tests are passing,
but the actual application doesn't work. Also your tests will be more fragile
to gem/API's changes.

In some future posts I'll describe some techniques that I'm mentioning here.

## Conclusion

As in every conflict there is no single truth and holy grail. Application core,
encapsulated and with clearly defined borders is where you should focus your
testing efforts and TDD. Design of code that lies on and beyond the borders doesn't need
to be driven by tests. It is already driven by framework, libraries, API's etc.

Don't be obsessively to not write a single line of production code before
the test. From the other hand it is much easier to do with integration/system tests as
you write general test scenarios that covers more parts of an application and on
a higher lever not caring about the implementation details.
**General tests do not drive application design though**.

Not all application needs to encapsulate core logic. However it helps significantly
in complex applications and when you'll need to maintain application for a long time.
Decision is yours and judge well.

Do not be afraid of indirections (despite what DHH says). **Indirection doesn't destroy
your design**. With proper naming. simple, clean classes design is even easier to
understand as you don't need to care about the implementation details. You can even
say what the system is doing by scanning the names of modules and classes in your
core logic.

Focus your efforts on things that matters - application core logic. Test and design
it well. Ensure that you cross the application borders in a correct way, you
don't need to test every single case for code that is not core for your application.
Tests for core already are doing that so don't repeat yourself.

[http://michalorman.com/2014/05/unit-or-integration-testing/](http://michalorman.com/2014/05/unit-or-integration-testing/)

{% include bio_michal_orman.html %}

[1]: http://rubylove.io/2014/04/25/why-i-can-tdd-and-why-dhh-cant/
[2]: http://david.heinemeierhansson.com/2014/test-induced-design-damage.html
