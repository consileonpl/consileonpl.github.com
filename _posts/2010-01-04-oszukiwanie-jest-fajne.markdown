---
layout: post
title: Oszukiwanie jest fajne
categories: [rubyonrails]
---
W codziennej pracy często zdarza się sytuacja kiedy potrzebujemy informacji odnośnie jakiegoś narzędzia, biblioteki itp. Wtedy ruszamy często do [Googla](http://google.pl). Lecz można również... oszukiwać (**cheat** - oszustwo) instalując taki oto przydatny wynalazek ułatwiający nam życie:

{% highlight bash %}
$ gem install cheat
{% endhighlight %}

i od razu możemy z niego korzystać, powiedzmy że potrzebuję informacji jak używać git'a:

{% highlight bash %}
$ cheat git
{% endhighlight %}

I dostaniemy taki oto **cheatsheet**:
{% highlight bash %}
git:
  Setup
  -----

  git clone <repo>
    clone the repository specified by <repo>; this is similar to "checkout" in
    some other version control systems such as Subversion and CVS

  Add colors to your ~/.gitconfig file:

    [color]
      ui = auto
    [color "branch"]
      current = yellow reverse
      local = yellow
      remote = green
    [color "diff"]
      meta = yellow bold
      frag = magenta bold
      old = red bold
      new = green bold
    [color "status"]
      added = yellow
      changed = green
      untracked = cyan

  Highlight whitespace in diffs

    [color]
      ui = true
    [color "diff"]
      whitespace = red reverse
    [core]
      whitespace=fix,-indent-with-non-tab,trailing-space,cr-at-eol

  Add aliases to your ~/.gitconfig file:

    [alias]
      st = status
      ci = commit
      br = branch
      co = checkout
      df = diff
      lg = log -p


  Configuration
  -------------

  git config -e [--global]
    edit the .git/config [or ~/.gitconfig] file in your $EDITOR

  git config --global user.name 'John Doe'
  git config --global user.email johndoe@example.com
    sets your name and email for commit messages

  ...

{% endhighlight %}

Albo informacji odnośnie np. rspec'a:

{% highlight ruby %}
$ cheat rspec
{% endhighlight %}

I dostaniemy taki oto **cheatsheet**:
{% highlight ruby %}
rspec:
  INSTALL
  =======
    INSTALL rspec
    =============
  $ sudo gem install rspec
    OR
  $ ./script/plugin install git://github.com/dchelimsky/rspec.git

    INSTALL rspec_on_rails plugin
    =============================
  $ ./script/plugin install git://github.com/dchelimsky/rspec-rails.git


  BOOTSTRAP THE APP
  =================
  $ ./script/generate rspec
        create  spec
        create  spec/spec_helper.rb
        create  spec/spec.opts
        create  previous_failures.txt
        create  script/spec_server
        create  script/spec



  HOW TO USE
  ==========

    COMMAND LINE
    =============
  spec --color --format specdoc user.rspec

    RAILS
    =============
  ./script/generate rspec_model User
  rake doc:plugins # generates local docs for your app's plugins
  rake -T spec # lists all rspec rake tasks
  rake spec # run all specs
  rake spec SPEC=spec/models/mymodel_spec.rb SPEC_OPTS="-e \"should do
  something\"" #run a single spec




  module UserSpecHelper
    def valid_user_attributes
      { :email => "joe@bloggs.com",
        :username => "joebloggs",
        :password => "abcdefg"}
    end
  end


  describe "A User (in general)" do
    include UserSpecHelper

    before(:each) do
      @user = User.new
    end

    it "should be invalid without a username" do
      pending "some other thing we depend on"
      @user.attributes = valid_user_attributes.except(:username)
      @user.should_not be_valid
      @user.should have(1).error_on(:username)
      @user.errors.on(:username).should == "is required"
      @user.username = "someusername"
      @user.should be_valid
    end
  end

  SHOULDA COULDA WOULDA
  =====================
  target.should satisfy {|arg| ...}
  target.should_not satisfy {|arg| ...}

  target.should equal <value>
  target.should not_equal <value>

  target.should be_close <value>, <tolerance>
  target.should_not be_close <value>, <tolerance>

  target.should be <value>
  target.should_not be <value>

  target.should predicate [optional args]
  target.should be_predicate [optional args]
  target.should_not predicate [optional args]
  target.should_not be_predicate [optional args]

  target.should be < 6
  target.should == 5
  target.should_not == 'Samantha'

  target.should match <regex>
  target.should_not match <regex>

  target.should be_an_instance_of <class>
  target.should_not be_an_instance_of <class>

  target.should be_a_kind_of <class>
  target.should_not be_a_kind_of <class>

  target.should respond_to <symbol>
  target.should_not respond_to <symbol>

  *OLD:*
  proc.should raise <exception>
  proc.should_not raise <exception>
  proc.should_raise <exception> # not available anymore
  *NEW:*
  lambda {a_call}.should raise_error
  lambda {a_call}.should raise_error(<exception> [, message])
  lambda {a_call}.should_not raise_error
  lambda {a_call}.should_not raise_error(<exception> [, message])

  proc.should throw <symbol>
  proc.should_not throw <symbol>

  target.should include <object>
  target.should_not include <object>

  target.should have(<number>).things
  target.should have_at_least(<number>).things
  target.should have_at_most(<number>).things

  target.should have(<number>).errors_on(:field)

  proc { thing.approve! }.should change(thing, :status).
      from(Status::AWAITING_APPROVAL).
      to(Status::APPROVED)

  proc { thing.destroy }.should change(Thing, :count).by(-1)

  Mocks and Stubs
  ===============

  user_mock = mock "User"
  user_mock.should_receive(:authenticate).with("password").and_return(true)
  user_mock.should_receive(:coffee).exactly(3).times.and_return(:americano)

  user_mock.should_receive(:coffee).exactly(5).times.and_raise(NotEnoughCoffeeExc
  ption)

  people_stub = mock "people"
  people_stub.stub!(:each).and_yield(mock_user)
  people_stub.stub!(:bad_method).and_raise(RuntimeError)

  user_stub = mock_model("User", :id => 23, :username => "pat", :email =>
  "pat@example.com")

{% endhighlight %}

Prawda że fajnie jest oszukiwać ! ;)

Lektura obowiązkowa:
[http://cheat.errtheblog.com/](http://cheat.errtheblog.com/)


[http://andrzejsliwa.com/2010/01/04/oszukiwanie-jest-fajne/](http://andrzejsliwa.com/2010/01/04/oszukiwanie-jest-fajne/)

{% include bio_andrzej_sliwa.html %}