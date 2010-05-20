---
layout: post
title: Eake ... narzędzie budowania dla Erlanga
categories: [ruby, erlang]
---
Eake to proste Erlang'owe narzędzie do budowania wzorowane na [Rake](http://rake.rubyforge.org/) (Ruby), które storzyłem po to aby zastąpić w moich projektach Erlang'owych make'a i rake'a. W internecie jest mnóstwo przykładów bazujących na make, którego nie lubię, jest równie wiele przykładów użycia Rake'a do budowania projektów opartych o Erlang'a. Eake powstał właśnie dlatego że lubię "natywne" rozwiązania, czyli pisanie skryptów buildowania w natywnym języku projektu.

Eake nie jest jeszcze w pełni funkcjonalny, ale stanowi podstawę do dalszej dyskusji i pomysłów, bardzo oczekuję na wszelkie uwagi i komentarze związane Eake'iem. Proszę również o propozycje licencji dla w/w projektu.

Eake'a znajdziemy na GitHub :  [http://github.com/andrzejsliwa/eake/tree/master](http://github.com/andrzejsliwa/eake/tree/master)

Przykładowe użycie (plik eakefile):

{% highlight erlang %}
-module(eakefile).
-compile([export_all]).
-import(eake, [task/3, namespace/3, run_target/2, run/1]).

execute() -> [

  namespace(db, "test", [
    task(migrate, "That is migration", fun(Params) ->
      io:format("in migration params: ~w", [Params]),
      run_target('db:rollback', [])
    end),

    task(rollback, "That is rollback", fun(_) ->
      io:format("in rollback"),
      run("ls")
    end)
  ])
].
{% endhighlight %}

Przykładowe polecenia:

{% highlight bash %}
$ eake db:migrate
$ eake db:migrate db:rollback
$ eake db:migrate=[1,atom]
$ eake db:migrate=name
{% endhighlight %}

Eake jest moim pierwszym programem napisanym w Erlangu, proszę więc o wszelkie rady i uwagi co do stylu jak i użytych konstrukcji.


[http://andrzejsliwa.com/2009/05/28/eake-narzedzie-budowania-dla-erlanga-bazujace-na-rake/](http://andrzejsliwa.com/2009/05/28/eake-narzedzie-budowania-dla-erlanga-bazujace-na-rake/)

{% include bio_andrzej_sliwa.html %}
