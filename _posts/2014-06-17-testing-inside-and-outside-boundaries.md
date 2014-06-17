---
layout: post
categories: [tdd, ruby, rubyonrails, architecture]
---
This post is a continuation of my [previous post][1] about integration
and unit testing practices. I encourage to read previous post first.

## Web Application Architecture

Traditionally we were using [MVC][2] frameworks to implement our web applications.
While this pattern worked great in a past it is not a case anymore. The problem is
that our applications are fairly complex nowadays. We expose features via the HTTP,
via REST/Json API's, we are communicating with external API's, sometimes we have more
than one storage. **The problem of MVC is that it was not designed to tackle growing
application complexity**.

In traditional MVC approach your business logic is implemented in models. However
while the application is growing models are growing as well. If you won't tackle
the growth of an application you'll end up with 6000-lines long models with
hundreds of callbacks.

Concerns that were introduced to Rails do not solve the problem. They do
not deal with complexity. Instead they just move complexity aside so that we do not
see it when we open a model class. But issues remains the same as without using concerns.

For applications that require tackling growing complexity, we need something
more than plain old MVC.

### The Hexagonal Architecture aka Ports and Adapters

[Hexagonal Architecture][3] may help us to tackle growing application complexity.
The basic architecture in Rails application context is depicted in a following
figure:

![Rails Hexagonal Architecture](/images/rails-hexagonal-architecture.png)

We see that we have 2 boundaries in this architecture. The core is where all
domain logic lives. Outside the core, but still within application boundaries, lives all
code related to the framework (Rails) and everything that wraps calls to IO, file system,
external services even libraries. Everything else is external to the application.

It is important to note that through each component (port) dependencies goes in
a same direction. Controllers depends on the core, but core is not depending
on controllers. Core depends on models, but models are not dependent on core,
and so on.

## Testing the core

As said core is all your business logic. I've intentionally left that as a
placeholder instead of describing what components should core consist of. It
is really dependent on the application specific requirements and your fluency
in Object Oriented Design. You can apply [Domain Driven Design][4] principles,
you can create simple service objects. Whatever works given the application
domain and requirements.

Note that things like DDD were designed to tackle growing complexity. If your
application is not fairly complex and level of complexity is not rising using
DDD is overkill. Do a good judge picking the right tools!

Because you don't know the exact architecture of an application core it is perfect
place to drive its design by tests. You can easily replace components that do
not belong to the core with test doubles and test core independently from framework.

You may ask **how isolation helps testing core logic?**. Isolation comes with
a burden of mocks and stubs, is it worth the price? I strongly believe that isolation
helps significantly (and not just because tests are running faster, that is for
free!).

Firstly if you are isolated from framework you deal only with complexity
of a problem that you are solving (we call that [essential complexity][5]). You
don't need to deal with additional complexity inherited from the framework
(that's [accidental complexity][6]). Well at least other than framework/s used
for testing.

Secondly mocks and stubs gives you greater control over the different circumstances
that may happen. It is especially helpful if you want to test different scenarios
including connection timeouts, etc. It is much easier to tell a mock to throw
an exception instead of trying to simulate similar behavior on a real object.
Sometimes you don't even have access to test or sandbox environments.

It is quite safe to use mocks and stubs when testing core. Everything that surrounds
core belongs to the application, **so you are mocking only components that you
own**. That is very important.

Those are two great benefits of testing in isolation. And I believe they are
worth the price.

## Testing the boundaries

All that belongs to the application but is not a core I classify as a boundary.
Those components are much different than core components therefore they should
be designed and tested differently.

There is no point in driving design of boundaries from tests. The design is already
enforced by the framework, API's, libraries (even standard). There is not much
benefit that you can get from test driving that part of an application.

Also the complexity of those components is not changing. The wrapper for an HTTP
client will remain the same no matter which library you will use under the hood
(whether it be Faraday, RestClient, or Net::HTTP). If the complexity is not
growing and is predictable you will gain no benefit in tackling it.

There is no point in testing boundaries in isolation. Boundaries
are thin components that delegates messages either outside the application
or into a core. They unwrap data from structures and wrap to another structures. Not
much of a logic to test here. We won't limit accidental complexity by isolating
boundaries. In fact it will amplify its impact as mocking components that you
don't own leads to a very fragile tests. Also frameworks are designed to provide
nice DSL's or API's which are not grateful when mocking (like ActiveRecord call chains).

Despite if you will test boundaries in isolation you will need to test it
also in integration/acceptance/system tests. You must ensure that not only boundary
components are doing what they should, but they are integrating well with outside
world and a core. Integration tests will cover everything that you might test
in isolation (given the fact that boundaries are simple classes without much
logic inside). There is no point in testing same piece of functionality twice.

Also you can be less restrictive when testing boundaries. While testing core you
will check each possible condition that you can imagine and simulate, when testing
boundaries you don't need to remove every possible mandatory parameter from a request
to ensure that it will respond with bad request each time. You don't need to test
functionality that is provided by framework. You just need to ensure that it
integrates correctly.

## Recap

When dealing with application that is fairly complex and you predict that the complexity
will grow you need something more than plain old MVC. Wrap your core logic and surround
it with a shell of components isolating it from outside world. Let those isolating
components be logic-less, simple delegators that transforms data structures. Test drive
your core design and test it in isolation, you will deal only with essential complexity
and will have greater control over different scenarios and conditions. Do not test drive
code that does not belong to the core. Its design is driven by frameworks, libraries or
protocols and it is not a complexity that you want to deal with. Make your ports simple
so that their complexity is at low, stable and predictable level.

[http://michalorman.com/2014/06/testing-inside-and-outside-boundaries/](http://michalorman.com/2014/06/testing-inside-and-outside-boundaries/)

{% include bio_michal_orman.html %}

[1]: http://michalorman.com/2014/05/unit-or-integration-testing/
[2]: http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller
[3]: http://alistair.cockburn.us/Hexagonal+architecture
[4]: http://en.wikipedia.org/wiki/Domain-driven_design
[5]: http://en.wikipedia.org/wiki/Essential_complexity
[6]: http://en.wikipedia.org/wiki/Accidental_complexity
