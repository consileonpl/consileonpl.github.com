---
layout: post
categories: [middleware, jboss]
title: JBoss EAP 6 Overview
---
When in June 2012 [Red Hat][redhat] finally released [JBoss EAP 6][eap6] he marketed it as a high-performance, low-footprint and easy-to-manage cloud-centric solution. Solution that is able to decrease time-to-market for application delivery and reduce corresponding operational costs. Solution capable of bringing deployed applications into the cloud without the need to re-skill or diverge from open industry standards.

After working for almost 3 years on a commercial project with JBoss AS 6, AS 7 and finally EAP 6, I can safely say Red Hat was not exaggerating. Closed-source application server vendors, the competition, have a strong rival which will be difficult to beat.

In this post I will try to describe what [JBoss EAP 6][eap6] is, what is new and special about it, how it relates to [JBoss AS 7][as7] and finally if and when should you use it.

## What is it ?

For those, who do not know it yet, here is a quick refresher. JBoss EAP 6 is an example of middleware generally and application server specifically. Based on [Java][java] technology, it is an implementation of a well known [Java EE 6 specification or JSR-316][jsr316] devised initially by [Sun][sun] but now in the hands of [Oracle][oracle]. It is an open-source product, but like many proprietary application servers, it is also Java EE 6 web profile and full platform compliant, meaning, it has passed appropriate Java EE 6 CTS. It provides developers with a well defined set of services and APIs that when used properly can increase the quality and efficiency of enterprise application development. At least that's the theory.

## What is new ?

As the name suggests, JBoss EAP 6 is the 6th iteration of the product and, apparently, a lot have been changed or replaced in order to assure its success. Externally, the server looks like a complete rewrite, although the list of components used to construct it, at least when compared to JBoss AS 6 or later versions of JBoss EAP 5, might say otherwise. However, instead of trying to convince you let us simply go through some of the most important differences. We will try to briefly cover: class loading, directory structure, subsystem and profiles, startup and boot-up process, server operation modes, clustering and mod-cluster, management interfaces and other details.

#### Class loading

The class loading in [JBoss EAP 6][eap6] is now based on the concept of modules, meaning it is no longer hierarchical. A module is a simple abstraction over a deployment or a set of libraries that basically defines a static or dynamic dependency. Dependencies as well as classes themselves can be resolved in parallel using host specific or user defined number of threads, making resolution faster on a multi-core machine.

Server provided libraries, generally, have no impact on running applications. Your top-level deployments like WARs, EARs, and so on are by default isolated from other top-level deployments and classes which are specific to application server itself. The Java EE specific classes like EJB, JPA, CDI and so on are automatically and implicitly added as dependencies when needed. The modules with non-Java EE specific classes have to be explicitly declared in your deployments to be properly resolved. Although, with global modules that behavior can be overridden.

Additionally, a finer level of control over class loading mechanism is possible with the help of *jboss-deployment-structure.xml* file. When placed under *META-INF* or *WEB-INF* directory, depending on deployment artefact kind, it can: prevent addition of automatic dependencies, add or remove certain dependencies, define additional modules and resource-roots as well as specify EAR sub-deployments isolation.

Unfortunately I do not have the space here to describe all class loading related details. I can only say, the whole idea of modules is flexible and somewhat refreshing. After seeing it at work I can definitely confirm that it works very nicely. You have control over which version of a library and even class a particular application is using and what's more important you do not have to put everything in your deployments if you choose so. However that approach has its implications and you should think about them ahead of time.

#### Directory structure

The directory structure of JBoss EAP 6 no longer includes the *lib* and *server* folders. We can roughly say that *lib* directory has been replaced by *bundles* and *modules* directories, which now basically contain server specific component libraries. However *modules* directory may also be used to store libraries that are shared between many applications like common utility libraries, database drivers or resource adapters and so on. Similarly, instead of *servers* directory we now have two replacement folders: *domain* and *standalone*. They contain files and directories specific to *domain* and *standalone* operating modes respectively, that means: configuration and subsystem specific files, including: deployments, server logs, transaction logs, passivation stores and so on.

#### Subsystems and profiles

Architecturally JBoss EAP 6 is now a small service container running a number of *extensions* integrated with the server through *subsystems* and configured through *profiles*.

Explaining it a little more, an *extension* is a module, a set of classes, extending core server with additional functionality, stored in *modules* directory. In turn, a *subsystem* defines which capabilities provided by a particular *extension* will be used at runtime based on configuration. Configuration is necessary to properly integrate, initialize and utilize corresponding functionalities of a particular subsystem. Finally, a *profile* is basically a named set of subsystem configurations defined within server specific configuration file. It seems to be an especially important layer of abstraction because it allows definition of an additional set of servers using the same set of subsystems by referencing only a single *profile* instead of all subsystems.

As a side note be aware that the more subsystems a given *profile* has, the larger is the memory footprint of a server started with such a *profile*. It may be therefore prudent to make *profiles* as slim as possible, not only because of memory usage but also because of possibly improved stability and performance.

#### Startup & boot-up process

Startup of a server is now initialized by using *standalone.sh* or *domain.sh* depending on the desired operating mode instead of *run.sh* script. However on boot-up JBoss EAP 6 loads all the subsystems lazily, which means they are loaded only when some deployed application actually needs them. That approach allows the server to start very quickly and use the available heap very efficiently. Unfortunately this also means that applications themselves are loaded a little longer when required subsystems have not been loaded yet. Personally I haven't noticed substantial slowdowns in such case but if you have large deployments you should be aware of that possibility.

#### Server operating modes

JBoss EAP 6 can run in two operating modes: *standalone* mode and *domain* mode. The *standalone* mode is basically the same operating mode which was used by JBoss EAP 5 to start a single application server. The *domain* mode, however, is a new concept for JBoss EAP 6. With its help a number of servers can be centrally managed through the so called *domain controller* process, which supplies appropriate configuration to the relevant servers.

This approach however is by no means revolutionary. [Oracle WebLogic Server][wls] and [IBM WebSphere Application Server][was] provided similar capability through *server domains* and *cells* or *administrative domains*, respectively, for a long time. The important thing here is that now JBoss EAP 6 provides similar management capabilities like its two greatest rivals.

Additionally, server configuration is no longer distributed among a large number of files, like it was in JBoss EAP 5 and previous versions. In JBoss EAP 6 configuration is integrated into a single file, *standalone.xml*, in case of *standalone* operating mode and two files, *domain.xml* and *host.xml*, in case of *domain* operating mode. Furthermore, configuration of subsystems have been somewhat simplified, making its management more straightforward.

#### Clustering &amp; mod-cluster

Clustering in JBoss EAP 6 has been largely improved. JBoss Cache based implementation has been replaced by Infinispan and JGroups combination responsible for distributed caching and cluster communication, respectively. Cluster communication can use either UDP or TCP protocol stack, which may be helpful in case local network security policies or performance requirements forces us to choose one over the other. Out of the box JBoss EAP 6 comes with four (4) preconfigured cache containers allowing replication among cluster nodes: web, sfsb, hibernate and cluster. An interesting detail about Infinispan caching here is that it should be used by server subsystems only which means application use is prohibited. So do not be tempted and use [JBoss Data Grid][jdg] instead.

To provide software-based load balancing capabilities JBoss EAP 6, just like it was the case with JBoss EAP 5, integrates with Apache HTTPd through *mod-cluster* subsystem. Using *mod-cluster* it is possible to load balance the incoming traffic based on server-side load metrics from JBoss EAP workers themselves. The load metrics can be static or dynamic, generated using: cpu load, memory usage, request count, traffic size, sessions count and so on. That means easy and dynamic horizontal scaling of your applications combined with automatic discovery and configuration of application contexts. Assuming UDP multicasting is allowed and any external services like databases, directory servers and so on can handle increased workload.

Clearly Apache HTTPd with *mod-cluster* may be a tempting alternative to quite expensive hardware load-balancing appliances. However, I would advice to always test *mod-cluster* configurations, particularly when using unsupported OS platform like Fedora 20. I have seen *mod-cluster* versions which could not handle AJP communication but worked flawlessly with HTTP. Only after compiling a later version of Apache HTTPd modules from source AJP started to function, so keep that in mind or use [Red Hat Enterprise Linux][rhel].

#### Management interfaces

From the administrator's perspective there are two (2) most important management interfaces in [JBoss EAP 6][eap6], namely: web-based *management console* and command line interface. The web-based *management console* contains similar functionality that was previously available through *admin console*, *web console* and *jmx-console* of JBoss EAP 5. It is by default available at *http://localhost:8080/console*.

The command line interface can be started through the *jboss-cli.sh* script and allows control of almost any aspect of [JBoss EAP 6][eap6] configuration. So whenever you think some parameter is not available in *management console* or cannot be changed there, try command line interface. The most important thing to note here is that you can now finally automate practically any administrative task through scripting. That means finally [JBoss EAP 6][eap6] provides similar management functionalities as [Oracle WebLogic Server][wls] or [IBM WebSphere Application Server][was] have provided for a long time.

#### Other noteworthy changes

By implementing [Java EE 6 specification][jsr316] [JBoss EAP 6][eap6] makes use of standardized naming environment to reference entries within JNDI naming context. More specifically an application component naming environment is now comprised of four (4) logical namespaces, each with a different scope.

The *java:comp* namespace is component specific, meaning it contains entries intended for a particular EJB. The *java:module* namespace is module specific, meaning it contains entries shared by all components of a particular application module, e.g. JAR or WAR. The *java:app* namespace is application specific, meaning it contains entries shared by all components of a particular deployment unit, e.g. EAR or WAR. The *java:global* namespace is application server specific, meaning it contains entries shared by all deployment units of a particular server instance.

However, in order to preserve compatibility with previous Java EE specifications, for a web module the *java:comp* namespace refers to the same JNDI context as *java:module* namespace. Apart from this small discrepancy, standardization of application component naming context should greatly improve portability of enterprise applications across Java EE 6 compliant application servers. On the other hand however, migration of older applications might require additional time to analyse and eventually update any non-portable JNDI lookups.

## What about JBoss AS 7 ?

JBoss AS 7 is a community project, sponsored by [Red Hat][redhat], to develop a [Java EE 6 compliant][jsr316] application server. For those of you who do not know the relation between AS 7 and EAP 6 yet, that might make no sense. After all, why would Red Hat want two products with same base functionality, right? Well, the answer is quite simple: [JBoss EAP 6][eap6] is an enterprise version of JBoss AS 7, built from the same source code but with proper testing and necessary patches applied. What is important here is the fact that enterprise release (EAP 6) is a supported product of [Red Hat][redhat]. The community release (AS 7) is not. To better understand the differences between the two, below is a brief summary.

#### Community release (JBoss AS 7)

When we talk about the community release, in this post, we mean [JBoss AS 7][as7]. Generally a community release is simply the most innovative product for a given generation of JBoss middleware. In this case there is little thought given to stability of the APIs or backward compatibility and experimental code may be present.

The code base is tested by the community and resolution of any issues may take long. The same can be said about support, which is based on public forums. That means nothing is guaranteed and advice may not be provided for a long time or even not at all. There is no formal quality assurance process, testing covers minimal number of test configurations. Similarly there is no formal training or certification offer, should it be needed.

All of this leads to an unfortunate outcome which is relatively high level of defects within the community release. To better describe it, the release notes for JBoss AS 7.1 mention that since JBoss AS 7.0 almost 1500 issues have been resolved. You can check that and judge yourself if your organisation has the time and resources required to use such a product.

#### Enterprise release (JBoss EAP 6)

When we talk about the enterprise release, in this post, we mean [JBoss EAP 6][eap6]. Generally enterprise release is simply the most stable product for a given generation of Red Hat middleware. At the moment enterprise release is one minor version behind the community release, which is not surprising considering all the testing and patching needed to stabilize it.

Specifically [Red Hat][redhat] provides up to seven (7) years of support and maintenance with backward compatible fixes and patches. Any experimental or unproven code may be withheld. Any unsupported open-source libraries are replaced with supported equivalents. Legal [open-source assurance][assure] is offered to customers with valid Red Hat subscriptions that safeguards them against infringement and copy right risks related to server's open-source components.

Any patches, security updates and hot fixes are certified with appropriate localized documentation included. There is a dedicated support team which monitors, tracks and resolves reported issues based on SLAs for development and production. The product undergoes a formal quality assurance process including scalability, availability and reliability testing for every release. Additionally, compatibility tests on a wide range of JVMs, architectures, DBMS and ISV products are being conducted. Finally Red Hat provides training and certification services to speed up the development or integration of the product.

## Conclusion

[JBoss EAP 6][eap6] is a relatively large step forward for [Red Hat][redhat] since the time of AS 5, EAP 5 and AS 6 releases, available through payed [subscriptions][subs]. It contains many important features and improvements including: full [Java EE 6 compliance][jsr316], improved class loading, extended management interfaces, simplified configuration, domain-based server operation and management. The list price of a 16 core subscription with a premium 24/7 support is 9.000 USD. Similar subscription but with an additional [JBoss Operation Network][jon] management package costs 12.000 USD. Combining the features, stability, flexibility, performance and low-footprint with a relatively low price compared to proprietary products like: [Oracle WebLogic Server][wls] or [IBM WebSphere Application Server][was], [JBoss EAP 6][eap6] is clearly competitive. Otherwise, I cannot see the benefit in [changing WebSphere AS licensing in October 2013][waslic] - is IBM really that altruistic? One socket license and support in case of WebSphere AS (Base) costs around 13.300 USD and this offer is almost convincing. Unfortunately it still lacks some useful features, like distributed server management for example, which JBoss EAP 6 provides. Sure, these are available in WebSphere AS Network Deployment package, but the price is about four (4) times higher. That is why from the feature set perspective JBoss EAP 6 is for me, especially when combined with [JBoss Operation Network][jon], a more attractive and useful package for the price. On the other hand I still think the quality of documentation could be better.

#### What and when use it ?

Concerning the dilemma of choosing between community [JBoss AS 7][as7] and enterprise [JBoss EAP 6][eap6] the answer is relatively simple. Assuming your developers want to integrate some middleware capabilities for testing only or conduct early to advanced prototyping and development work the community release will be sufficient. Although one should accept increased amount of research and testing required to make some defective parts of the community server function as desired.

Assuming that you need to prepare staging or production runtime environment where continuous support is required or your developers are at later stages of product development cycle the enterprise release will be clearly more appropriate. One should also consider development support provided after purchasing a 16 core Red Hat subscription for a middleware product. These developer specific resources may improve the quality of your enterprise applications by allowing development team to better understand and use [JBoss EAP 6][eap6] features.

#### Would we recommend it ?

Based on our practical commercial experience and knowledge with installations spanning 10-20+ servers we can relatively safely recommend using [JBoss EAP 6][eap6]. For staging and production environments and even mission critical applications the product and provided support is sufficient. However, for organizations without previous JBoss experience we would advise taking part in authorized Red Hat trainings, like [JB226][jb226] and [JB248][jb248]. Familiarizing key personnel with important aspects of Java EE development and JBoss EAP 6 administration should help assure development project success.

Overall the price and quality of the product as well as SLA-based support and maintenance policy makes it, in our opinion, for the first time a viable replacement for [Oracle WebLogic][wls] and [IBM WebSphere][was]. Our clients confirm that choosing [JBoss EAP 6][eap6] instead of closed-source solution from IBM eliminated dependency on application server itself and related tools while reducing corresponding capital and operating costs. What is also interesting, [JBoss EAP 6][eap6] not only helped to create a good product, but at the same time functioned as a change catalyst, allowing introduction of new tools, processes and technologies which made development more productive, transparent and controllable.

[redhat]: http://www.redhat.com
[subs]: http://www.redhat.com/about/subscription/
[assure]: http://www.redhat.com/rhel/details/assurance/
[assp]: http://www.idc.com/2010st/assp.html
[eap6]: http://www.redhat.com/products/jbossenterprisemiddleware/application-platform/
[as7]: http://jbossas.jboss.org
[jon]: http://www.redhat.com/products/jbossenterprisemiddleware/operations-network/
[jdg]: http://www.redhat.com/products/jbossenterprisemiddleware/data-grid/
[java]: http://www.oracle.com/technetwork/java/index.html "Java"
[jsr316]: http://jcp.org/aboutJava/communityprocess/final/jsr316/index.html "JSR-316: Java EE specification"
[sun]: http://www.oracle.com/us/sun/index.htm "Sun Microsystems, Inc."
[oracle]: http://www.oracle.com "Oracle Corporation"
[wls]: http://www.oracle.com/technetwork/middleware/weblogic/overview/index.html
[was]: http://www-03.ibm.com/software/products/en/appserv-was
[rhel]: http://www.redhat.com/products/enterprise-linux/
[jb248]: http://www.redhat.com/training/courses/jb248/
[jb226]: http://www.redhat.com/training/courses/jb226/
[jbtco]: http://www.redhat.com/jboss/getunstuck/Virtuant-TCO-Analysis-JBossEAP-vs-Websphere.pdf
[components]: https://access.redhat.com/site/articles/112673 "Component versions of EAP releases"
[waslic]: http://www-01.ibm.com/common/ssi/cgi-bin/ssialias?subtype=ca&infotype=an&appname=iSource&supplier=877&letternum=ENUSZP13-0568

{% include bio_marcin_zajac.html %}
