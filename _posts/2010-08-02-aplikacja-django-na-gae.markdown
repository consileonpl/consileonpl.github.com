---
layout: post
title: Aplikacja Django na Google App Engine - Część I (konfiguracja aplikacji i pierwsze wdrożenie)
categories: [django, gae, python]
---
Platforma [SaaS](http://en.wikipedia.org/wiki/Software_as_a_service) o nazwie [Google App Engine](http://code.google.com/appengine/) (w skrócie **GAE**) jest wspaniałą alternatywą dla kosztownych opcji hostowania aplikacji opartych o serwery dedykowane czy konta współdzielone. Udostępnia ona całą infrastrukturę tworzenia aplikacji z wykorzystaniem języka [Python](http://www.python.org/) lub języków opartych o [JVM](http://en.wikipedia.org/wiki/Java_Virtual_Machine). Oczywiście istnieją ograniczenia związane z architekturą **GAE**, wymuszając pewne sposoby pracy z platformą (niejako wymuszając właściwe rozwiązania, również ze względu na optymalizacje kosztów)

**GAE** udostępnia tak naprawdę standardową infrastrukturę aplikacji opartą o sprawdzone rozwiązania firmy Google. Od jakiegoś czasu istnieje również możliwość uzyskania komercyjnego wsparcia.

Wykorzystując **GAE** mamy możliwość skorzystania z darmowych limitów przysługujących na każdą aplikacje by wraz ze wzrostem popularności naszej aplikacji przesiąść się na komercyjne konto. Takie podejście pozwala nam również na całkowite zrzucenie odpowiedzialności i zadań związanych ze skalowaniem naszej aplikacji co jest największą zaletą tej platformy.

W dzisiejszym wpisie chciałbym "pokrótce" przeprowadzić czytelnika przez proces uruchomienia przykładowej aplikacji bazującej na **GAE** używając zmodyfikowanej wersji Django (popularnego frameworka bazującego na pythonie).

Standardowa wersja [Django](http://www.djangoproject.com) (obecna wersja **1.2**) nie posiada jeszcze wsparcia dla nierelacyjnych baz danych takich jak [BigTable](http://en.wikipedia.org/wiki/BigTable) czy [MongoDB](http://www.mongodb.org/). Na szczęście dzięki pracy panów z [All Buttons Pressed](http://www.allbuttonspressed.com/projects/django-nonrel) mamy możliwość wykorzystania zmodyfikowanej wersji **Django**, która zawiera odpowiednie backendy wspierające w/w bazy danych.

Pierwszą czynnością którą, musimy wykonać ([zaraz po zainstalowaniu GAE na swoim systemie](http://code.google.com/appengine/downloads.html)) celem stworzenia aplikacji bazującej na **GAE**,
jest zalogowanie się na stronie [Google App Engine](http://code.google.com/appengine/):

<img class="full" src="/images/gae-registration.png"></img>

Podstawową zaletą korzystania z usług Google jest użycie tego samego konta do wielu usług
w tym również do **GAE**. W tym celu wprowadzamy nazwę użytkownika i logujemy się:

<img class="full" src="/images/gae-signup.png"></img>

Zaraz po zalogowaniu widzimy zaproszenie do rejestracji nowej aplikacji (w przypadku późniejszego logowania w tym miejscu pojawi się również list naszych aplikacji). Obecnie limit własnych aplikacji wynosi 10 i nie obejmuje aplikacji udostępnionych nam przez inne osoby.

<img class="full" src="/images/gae-new-app.png"></img>

W przypadku pierwszej rejestracji aplikacji wymagana jest aktywacja poprzez SMS:

<img class="full" src="/images/gae-activation.png"></img>

której dokonujemy wprowadzając kod aktywacyjny przesłany na naszą komórkę:

<img class="full" src="/images/gae-activation-2.png"></img>

Po poprawnej aktywacji przechodzimy do rejestracji aplikacji wpisując unikalną nazwę naszej aplikacji, dokonując dodatkowych ustawień oraz akceptując regulamin usługi.

Jak widać na obrazku rejestrowana aplikacja będzie dostępna pod adresem [officeshoppinglist.appspot.com](http://officeshoppinglist.appspot.com) zaraz po wgraniu pierwszej wersji kodu.
Istnieje możliwość podpięcia naszej aplikacji pod własny adres URL lecz istnieje ograniczenie pozwalające na podpięcie tylko jako poddomeny np.:

**http://www.mojadomena.pl**  (zamiast **http://mojadomena.pl**)

<img class="full" src="/images/gae-creating-app.png"></img>
<img class="full" src="/images/gae-creating-app-2.png"></img>

Następnie powinniśmy zobaczyć informacje o prawidłowo zarejestrowanej aplikacji:

<img class="full" src="/images/gae-creating-app-3.png"></img>

Po przejściu na dashboard powinniśmy uzyskać dostęp do podstawowych opcji konfiguracyjnych naszej aplikacji jak również zarządzania i podglądu stanu:

<img class="full" src="/images/gae-dashboard.png"></img>

Kolejnym krokiem po zarejestrowaniu naszej aplikacji będzie stworzenie repozytorium (w tym przypadku repozytorium **GIT**, na [github.com](http://github.com))

<img class="full" src="/images/gae-new-github-repo.png"></img>

Zgodnie z tymi instrukcjami przygotujemy nasz pusty projekt:
<img class="full" src="/images/gae-new-github-repo-2.png"></img>
<img class="full" src="/images/gae-new-github-repo-3.png"></img>

A więc...

tworzymy katalog:
{% highlight bash %}
~/gae$ mkdir officeshoppinglist
{% endhighlight %}

tworzymy pusty plik:
{% highlight bash %}
~/gae$ cd officeshoppinglist
~/gae/officeshoppinglist$ touch .gitignore
{% endhighlight %}

inicjujemy repozytorium GIT'a:
{% highlight bash %}
~/gae/officeshoppinglist$ git init
Initialized empty Git repository in /Users/andrzejsliwa/gae/officeshoppinglist/.git/
{% endhighlight %}

dodajemy nasz pusty plik:
{% highlight bash %}
~/gae/officeshoppinglist$ git add .
~/gae/officeshoppinglist$ git commit -m "initial commit."
[master (root-commit) d142cc5] initial commit.
 0 files changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 .gitignore
{% endhighlight %}

podpinamy zdalne repozytorium oraz wysyłamy je w obecnym stanie na serwer:
{% highlight bash %}
~/gae/officeshoppinglist[master]$ git remote add origin git@github.com:andrzejsliwa/officeshoppinglist.git
~/gae/officeshoppinglist[master]$ git push origin master
Counting objects: 3, done.
Writing objects: 100% (3/3), 219 bytes, done.
Total 3 (delta 0), reused 0 (delta 0)
To git@github.com:andrzejsliwa/officeshoppinglist.git
 * [new branch]      master -> master
{% endhighlight %}

Wynikiem naszych działań powinno być dostępne repozytorium:

<img class="full" src="/images/gae-new-github-repo-4.png"></img>

W tym momencie możemy przystąpić do konfigurowania naszego projektu. W tym celu pobieramy niezbędne zależności w formie repozytoriów mercuriala.

Pobieramy zmodyfikowaną wersję Django 1.2 która wspiera nierelacyjne bazy danych (w tym przypadku BigTable):
{% highlight bash %}
~/gae/officeshoppinglist[master]$ cd ..
~/gae$ hg clone http://bitbucket.org/wkornewald/django-nonrel
destination directory: django-nonrel
requesting all changes
adding changesets
adding manifests
adding file changes
added 8537 changesets with 21389 changes to 2919 files
updating to branch default
2266 files updated, 0 files merged, 0 files removed, 0 files unresolved
{% endhighlight %}

oraz dodatkowe wymagane repozytoria:
{% highlight bash %}
~/gae$ hg clone http://bitbucket.org/wkornewald/djangoappengine
destination directory: djangoappengine
requesting all changes
adding changesets
adding manifests
adding file changes
added 98 changesets with 194 changes to 47 files
updating to branch default
34 files updated, 0 files merged, 0 files removed, 0 files unresolved

~/gae$ hg clone http://bitbucket.org/wkornewald/djangotoolbox
destination directory: djangotoolbox
requesting all changes
adding changesets
adding manifests
adding file changes
added 40 changesets with 86 changes to 46 files
updating to branch default
23 files updated, 0 files merged, 0 files removed, 0 files unresolved
{% endhighlight %}

W tym momencie możemy podlinkować nasze zależności do projektu za pomocą linków symbolicznych:

{% highlight bash %}
ln -s ~/gae/django-nonrel/django officeshoppinglist/django
ln -s ~/gae/djangoappengine/ officeshoppinglist/djangoappengine
ln -s ~/gae/djangotoolbox/djangotoolbox officeshoppinglist/djangotoolbox
{% endhighlight %}

Następnie wracamy do naszego projektu i dodajemy reguły ignorowania do naszego pliku .gitignore:

{% highlight bash %}
~/gae$ cd officeshoppinglist
{% endhighlight %}

{% highlight bash %}
.DS_Store
*.pyc
*.swp
djangoappengine
djangotoolbox
django
{% endhighlight %}

Tworzymy plik **app.yml**, gdzie wpis application musi się zgadzać z nazwą zarejestrowanej aplikacji:

{% highlight yaml %}
application: officeshoppinglist
version: 1
runtime: python
api_version: 1

default_expiration: '365d'

handlers:
- url: /remote_api
  script: $PYTHON_LIB/google/appengine/ext/remote_api/handler.py
  login: admin

- url: /_ah/queue/deferred
  script: djangoappengine/deferred/handler.py
  login: admin

- url: /media/admin
  static_dir: django/contrib/admin/media

- url: /media
  static_dir: media

- url: /robots.txt
  static_files: robots.txt
  upload: robots.txt
  secure: optional

- url: /.*
  script: djangoappengine/main/main.py
{% endhighlight %}

Kolejno tworzymy: plik **cron.yml**:

{% highlight yaml %}
cron:
- description: keep alive
  url: /
  schedule: every 2 minutes
{% endhighlight %}

plik **index.yaml**:

{% highlight yaml %}
indexes:

- kind: django_admin_log
  properties:
  - name: user_id
  - name: action_time
    direction: desc

- kind: django_content_type
  properties:
  - name: app_label
  - name: name

# AUTOGENERATED

# This index.yaml is automatically updated whenever the dev_appserver
# detects that a new type of query is run.  If you want to manage the
# index.yaml file manually, remove the above marker line (the line
# saying "# AUTOGENERATED").  If you want to manage some indexes
# manually, move them above the marker line.  The index.yaml file is
# automatically uploaded to the admin console when you next deploy
# your application using appcfg.py.
{% endhighlight %}

plik **robots.txt**:

{% highlight yaml %}
User-agent: * Disallow: /
{% endhighlight %}

plik **manage.py** (oraz dodajemy mu prawa do wykonania):

{% highlight python %}
#!/usr/bin/env python

# Add "common-apps" folder to sys.path if it exists
import os, sys
common_dir = os.path.join(os.path.dirname(__file__), 'common-apps')
if os.path.exists(common_dir):
    sys.path.append(common_dir)

# Initialize App Engine SDK if djangoappengine backend is installed
try:
    from djangoappengine.boot import setup_env
except ImportError:
    pass
else:
    setup_env()

from django.core.management import execute_manager
try:
    import settings # Assumed to be in the same directory.
except ImportError:
    import sys
    sys.stderr.write("Error: Can't find the file 'settings.py' in the directory containing %r. It appears you've customi
    sys.exit(1)

if __name__ == "__main__":
    execute_manager(settings)
{% endhighlight %}

{% highlight bash %}
chmod +x manage.py
{% endhighlight %}

plik **urls.py**:

{% highlight python %}
from django.conf.urls.defaults import *
# Uncomment the next two lines to enable the admin
from django.contrib import admin

urlpatterns = patterns('',
    # Uncomment the next line to enable the admin:
    url(r'^admin/', include(admin.site.urls)),
)
{% endhighlight %}

plik **settings.py**:

{% highlight python %}
try:
    from djangoappengine.settings_base import *
    has_djangoappengine = True
except ImportError:
    has_djangoappengine = False
    DEBUG = True
    TEMPLATE_DEBUG = DEBUG

import os

SECRET_KEY = '!6r1e$z801cxu#d#rcgsnpvw0g#bn62nqz10#-ci+qlvalaf&1'

INSTALLED_APPS = (
    'djangotoolbox',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.sessions',
    'django.contrib.contenttypes',
)

if has_djangoappengine:
    INSTALLED_APPS = ('djangoappengine',) + INSTALLED_APPS

ADMIN_MEDIA_PREFIX = '/media/admin/'
MEDIA_ROOT = os.path.join(os.path.dirname(__file__), 'media')
TEMPLATE_DIRS = (os.path.join(os.path.dirname(__file__), 'templates'),)

ROOT_URLCONF = 'urls'
{% endhighlight %}

oraz bardzo ważny pusty plik __init__.py:
{% highlight bash %}
~/gae/officeshoppinglist[master]$ touch __init__.py
{% endhighlight %}

Tworzymy pliki szablonów i standardowych błędów zgodne z systemem django [http://github.com/andrzejsliwa/officeshoppinglist/tree/master/templates/](http://github.com/andrzejsliwa/officeshoppinglist/tree/master/templates/).
Wynikiem naszych działań powinna być taka oto struktura projektu:

{% highlight bash %}
~/gae/officeshoppinglist[master*]$ tree
.
|-- __init__.py
|-- __init__.pyc
|-- app.yaml
|-- cron.yaml
|-- django -> /Users/andrzejsliwa/gae/django-nonrel/django
|-- djangoappengine -> /Users/andrzejsliwa/gae/djangoappengine/
|-- djangotoolbox -> /Users/andrzejsliwa/gae/djangotoolbox/djangotoolbox
|-- index.yaml
|-- manage.py
|-- robots.txt
|-- settings.py
|-- settings.pyc
|-- templates
|   |-- 404.html
|   |-- 500.html
|   `-- base.html
|-- urls.py
`-- urls.pyc

4 directories, 14 files
{% endhighlight %}

W tym momencie jesteśmy gotowi do testowego uruchomienia naszej aplikacji za pomocą polecenia:

{% highlight bash %}
~/gae/officeshoppinglist[master]$ ./manage.py runserver
{% endhighlight %}

Po otwarciu aplikacji pod adresem http://localhost:8000 powinniśmy zobaczyć:
<img class="full" src="/images/gae-firstrun.png"></img>

oraz taki output w konsoli:
<img class="full" src="/images/gae-terminal-first-run.png"></img>

W tym momencie możemy uruchomić wdrożenie naszej aplikacji na serwer produkcyjny:

{% highlight bash %}
./manage.py deploy
{% endhighlight %}

Wynikiem tego polecenia (które pyta o dane logowania by nas uwierzytelnić) jest:
{% highlight bash %}
./manage.py deploy
Application: officeshoppinglist; version: 1.
Server: appengine.google.com.
Scanning files on local disk.
Scanned 500 files.
Scanned 1000 files.
Initiating update.
Email: sliwa.andrzej@gmail.com
Password for sliwa.andrzej@gmail.com:
Cloning 79 static files.
Cloning 1266 application files.
Cloned 100 files.
Cloned 200 files.
Cloned 300 files.
Cloned 400 files.
Cloned 500 files.
Cloned 600 files.
Cloned 700 files.
Cloned 800 files.
Cloned 900 files.
Cloned 1000 files.
Cloned 1100 files.
Cloned 1200 files.
Deploying new version.
Checking if new version is ready to serve.
Will check again in 1 seconds.
Checking if new version is ready to serve.
Will check again in 2 seconds.
Checking if new version is ready to serve.
Will check again in 4 seconds.
Checking if new version is ready to serve.
Will check again in 8 seconds.
Checking if new version is ready to serve.
Will check again in 16 seconds.
Checking if new version is ready to serve.
Closing update: new version is ready to start serving.
Uploading index definitions.
Uploading cron entries.
Running syncdb.
Login via Google Account:sliwa.andrzej@gmail.com
Password:
Traceback (most recent call last):
  File "./manage.py", line 26, in <module>
    execute_manager(settings)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/core/management/__init__.py", line 438, in execute_manager
    utility.execute()
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/core/management/__init__.py", line 379, in execute
    self.fetch_command(subcommand).run_from_argv(self.argv)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/djangoappengine/management/commands/deploy.py", line 72, in run_from_argv
    run_appcfg(argv)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/djangoappengine/management/commands/deploy.py", line 53, in run_appcfg
    call_command('syncdb', remote=True, interactive=True)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/core/management/__init__.py", line 166, in call_command
    return klass.execute(*args, **defaults)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/core/management/base.py", line 218, in execute
    output = self.handle(*args, **options)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/core/management/base.py", line 347, in handle
    return self.handle_noargs(**options)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/core/management/commands/syncdb.py", line 103, in handle_noargs
    emit_post_sync_signal(created_models, verbosity, interactive, db)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/core/management/sql.py", line 185, in emit_post_sync_signal
    interactive=interactive, db=db)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/dispatch/dispatcher.py", line 162, in send
    response = receiver(signal=self, sender=sender, **named)
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/contrib/contenttypes/management.py", line 11, in update_contenttypes
    content_types = list(ContentType.objects.filter(app_label=app.__name__.split('.')[-2]))
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/db/models/query.py", line 83, in __len__
    self._result_cache.extend(list(self._iter))
  File "/Users/andrzejsliwa/gae/officeshoppinglist/django/db/models/query.py", line 269, in iterator
    for row in compiler.results_iter():
  File "/Users/andrzejsliwa/gae/officeshoppinglist/djangotoolbox/db/basecompiler.py", line 219, in results_iter
    for entity in self.build_query(fields).fetch(low_mark, high_mark):
  File "/Users/andrzejsliwa/gae/officeshoppinglist/djangoappengine/db/compiler.py", line 95, in fetch
    results = query.Run(**kw)
  File "/Applications/GoogleAppEngineLauncher.app/Contents/Resources/GoogleAppEngine-default.bundle/Contents/Resources/google_appengine/google/appengine/api/datastore.py", line 1148, in Run
    return self._Run(**kwargs)
  File "/Applications/GoogleAppEngineLauncher.app/Contents/Resources/GoogleAppEngine-default.bundle/Contents/Resources/google_appengine/google/appengine/api/datastore.py", line 1185, in _Run
    str(exc) + '\nThis query needs this index:\n' + yaml)
google.appengine.api.datastore_errors.NeedIndexError: The index for this query is not ready to serve. See the Datastore Indexes page in the Admin Console.
This query needs this index:
- kind: django_content_type
  properties:
  - name: app_label
  - name: name
{% endhighlight %}

Wyjątek w tym miejscu jest czymś normalnym ze względu na to że indeksy potrzebują czasu na zbudowanie co
możemy potwierdzić obserwując nasz [dashboard](https://appengine.google.com/) w sekcji Datastore Indexes:

<img class="full" src="/images/gae-indexes.png"></img>

Po poprawnym wdrożeniu powinniśmy zobaczyć taki oto wynik (wprowadzenia adresu: [http://officeshoppinglist.appspot.com/admin/](http://officeshoppinglist.appspot.com/admin/)):

<img class="full" src="/images/gae-remote-admin.png"></img>

oraz taki wynik (wprowadzenia adresu: [http://officeshoppinglist.appspot.com/](http://officeshoppinglist.appspot.com/)):

<img class="full" src="/images/gae-remote.png"></img>

Po zbudowaniu indeksów kolejne wdrożenie odbędzie się już bez błędów:

{% highlight bash %}
~/gae/officeshoppinglist[master*]$ ./manage.py deploy
Application: officeshoppinglist; version: 1.
Server: appengine.google.com.
Scanning files on local disk.
Scanned 500 files.
Scanned 1000 files.
Initiating update.
Email: sliwa.andrzej@gmail.com
Password for sliwa.andrzej@gmail.com:
Cloning 79 static files.
Cloning 1266 application files.
Cloned 100 files.
Cloned 200 files.
Cloned 300 files.
Cloned 400 files.
Cloned 500 files.
Cloned 600 files.
Cloned 700 files.
Cloned 800 files.
Cloned 900 files.
Cloned 1000 files.
Cloned 1100 files.
Cloned 1200 files.
Uploading 1 files and blobs.
Uploaded 1 files and blobs
Deploying new version.
Checking if new version is ready to serve.
Will check again in 1 seconds.
Checking if new version is ready to serve.
Will check again in 2 seconds.
Checking if new version is ready to serve.
Will check again in 4 seconds.
Checking if new version is ready to serve.
Will check again in 8 seconds.
Checking if new version is ready to serve.
Will check again in 16 seconds.
Checking if new version is ready to serve.
Will check again in 32 seconds.
Checking if new version is ready to serve.
Closing update: new version is ready to start serving.
Uploading index definitions.
Uploading cron entries.
Running syncdb.
Login via Google Account:sliwa.andrzej@gmail.com
Password:
No fixtures found.
{% endhighlight %}

Polecam również przyjrzeć się bliżej dostępnym poleceniom **manage.py**:

{% highlight bash %}
~/gae/officeshoppinglist[master*]$ ./manage.py
Usage: manage.py subcommand [options] [args]

Options:
  -v VERBOSITY, --verbosity=VERBOSITY
                        Verbosity level; 0=minimal output, 1=normal output,
                        2=all output
  --settings=SETTINGS   The Python path to a settings module, e.g.
                        "myproject.settings.main". If this isn't provided, the
                        DJANGO_SETTINGS_MODULE environment variable will be
                        used.
  --pythonpath=PYTHONPATH
                        A directory to add to the Python path, e.g.
                        "/home/djangoprojects/myproject".
  --traceback           Print traceback on exception
  --version             show program's version number and exit
  -h, --help            show this help message and exit

Type 'manage.py help <subcommand>' for help on a specific subcommand.

Available subcommands:
  changepassword
  cleanup
  compilemessages
  createcachetable
  createsuperuser
  dbshell
  deploy
  diffsettings
  dumpdata
  flush
  inspectdb
  loaddata
  makemessages
  remote
  reset
  runfcgi
  runserver
  shell
  sql
  sqlall
  sqlclear
  sqlcustom
  sqlflush
  sqlindexes
  sqlinitialdata
  sqlreset
  sqlsequencereset
  startapp
  syncdb
  test
  testserver
  validate
{% endhighlight %}

Szczególnie poleceniu **remote**, które pozwala nam na wykonywanie pozostałych poleceń na zdalnym wdrożonym systemie:

{% highlight bash %}
~/gae/officeshoppinglist[master*]$ ./manage.py remote syncdb
INFO     2010-08-02 07:44:17,050 base.py:154] Setting up remote_api for "officeshoppinglist" at http://officeshoppinglist.appspot.com/remote_api
INFO     2010-08-02 07:44:17,061 appengine_rpc.py:159] Server: officeshoppinglist.appspot.com
INFO     2010-08-02 07:44:17,061 base.py:162] Now using the remote datastore for "officeshoppinglist" at http://officeshoppinglist.appspot.com/remote_api
Login via Google Account:sliwa.andrzej@gmail.com
Password:
No fixtures found.
{% endhighlight %}

{% highlight bash %}
~/gae/officeshoppinglist[master*]$ ./manage.py remote shell
INFO     2010-08-02 07:45:52,392 base.py:154] Setting up remote_api for "officeshoppinglist" at http://officeshoppinglist.appspot.com/remote_api
INFO     2010-08-02 07:45:52,405 appengine_rpc.py:159] Server: officeshoppinglist.appspot.com
INFO     2010-08-02 07:45:52,407 base.py:162] Now using the remote datastore for "officeshoppinglist" at http://officeshoppinglist.appspot.com/remote_api
Python 2.5.5 (r255:77872, Jun 12 2010, 00:13:50)
[GCC 4.2.1 (Apple Inc. build 5659)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
(InteractiveConsole)
>>>
{% endhighlight %}

Na koniec dodajemy wszystkie pliki do repozytorium i wypycham je na zdalny serwer **GIT'a**:
{% highlight bash %}
~/gae/officeshoppinglist[master*]$ git add .
~/gae/officeshoppinglist[master*]$ git commit -m "initial import."
[master c6b310e] initial import.
 11 files changed, 186 insertions(+), 0 deletions(-)
 create mode 100644 __init__.py
 create mode 100644 app.yaml
 create mode 100644 cron.yaml
 create mode 100644 index.yaml
 create mode 100755 manage.py
 create mode 100644 robots.txt
 create mode 100644 settings.py
 create mode 100644 templates/404.html
 create mode 100644 templates/500.html
 create mode 100644 templates/base.html
 create mode 100644 urls.py

~/gae/officeshoppinglist[master]$ git push
Counting objects: 16, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (13/13), done.
Writing objects: 100% (14/14), 3.16 KiB, done.
Total 14 (delta 0), reused 0 (delta 0)
To git@github.com:andrzejsliwa/officeshoppinglist.git
   d142cc5..c6b310e  master -> master

{% endhighlight %}

Aktualny kod:
[http://github.com/andrzejsliwa/officeshoppinglist](http://github.com/andrzejsliwa/officeshoppinglist)

Lektura obowiązkowa:
[http://www.allbuttonspressed.com/projects/django-nonrel](http://www.allbuttonspressed.com/projects/django-nonrel)
[http://www.allbuttonspressed.com/blog/django/2010/01/Native-Django-on-App-Engine](http://www.allbuttonspressed.com/blog/django/2010/01/Native-Django-on-App-Engine)
[http://arrogantprogrammer.blogspot.com/2010/03/django-nonrel-and-google-app-engine.html](http://arrogantprogrammer.blogspot.com/2010/03/django-nonrel-and-google-app-engine.html)
[http://css.dzone.com/articles/django-nonrel-picking-momentum](http://css.dzone.com/articles/django-nonrel-picking-momentum)
[http://docs.djangoproject.com/en/1.2/](http://docs.djangoproject.com/en/1.2/)
[http://code.google.com/appengine/docs/python/overview.html](http://code.google.com/appengine/docs/python/overview.html)


[http://andrzejsliwa.com/2010/08/02/aplikacja-django-na-gae/](http://andrzejsliwa.com/2010/08/02/aplikacja-django-na-gae/)

{% include bio_andrzej_sliwa.html %}