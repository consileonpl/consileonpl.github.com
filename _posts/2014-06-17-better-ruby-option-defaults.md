---
layout: post
categories: [ruby]
title: Better ruby defaults for hash-based options
---
Almost every ruby, Ruby on Rails project has some kind of a global configuration.
Sometimes it's a YAML file loaded 'as-is', other times it's a model or designated
configuration class.

There are cases when we have to fallback to default values. In a model or
configuration class the easiest way is to use accessor with the `or` operator:

{% highlight ruby %}
class Config
  def initialize
    @hash = ... # empty hash or loaded YAML file
  end

  def option=(value)
    @hash['option'] = value
  end

  def option
    @hash['option'] || "option's default value"
  end
end
{% endhighlight %}

However this approach have a major drawback: what if we wanted a `nil` as the
option value?

{% highlight ruby %}
config.option = nil # => nil
config.option # => "option's default value"
{% endhighlight %}

## `Hash#fetch` to the rescue

There is an elegant solution to the `nil` values: `Hash#fetch`.
This method returns the key value or throws an error (`KeyError`) if they key
wasn't found.

{% highlight ruby %}
def option
  @hash.fetch('option')
end
{% endhighlight %}

{% highlight ruby %}
config.option # => KeyError: key not found: "option"
config.option = nil # => nil
config.option # => nil
{% endhighlight %}

We have several ways for handling default values:

* method with two params: `Hash#fetch(key, default)`
* method with a param and a block: `Hash#fetch(key) { default }`
* method with a param and a block as param: `Hash#fetch(key, &block)`

### The two params version

{% highlight ruby %}
def option
  @hash.fetch('option', "option's default value")
end
{% endhighlight %}

### The block version

{% highlight ruby %}
def option
  @hash.fetch('option') { |key| "#{key}'s default value" }
end
{% endhighlight %}

The double param version with a block as param will be shown in the further
example.

Both versions behave as we expect, returning default value or previously set
value (even if it's `nil`).

{% highlight ruby %}
config.option # => "option's default value"
config.option = nil # => nil
config.option # => nil
{% endhighlight %}

## The Pitfall

There's a little niuance in providing default values via `#fetch` most coders
aren't aware of: __When the default value is evaluated?__

In the two params version (the one without block param) both parameters are
__ALWAYS__ evaluated. That' right: even if there is a value provided, the
default value
will be evaluated.

{% highlight ruby %}
def default
  puts 'default evaluated!'
  'default value'
end

def option
  @hash.fetch('option', default)
end

config.option # prints "default evaluated!", returns "default value"

config.option = 'set option'
config.option # prints "default evaluated!", returns "set option"

{% endhighlight %}

Thankfully the block version evaluates block only if there is no value.

In our simple example returning a string this isn't a big thing.
However imagine a situation when you perform time-consuming operation like
searching through the huge database or retrieving OAuth access token from
the server.

{% highlight ruby %}
def retrieve_oauth2_access_token
  ... # time consuming operation that sends a request for access token
end

def access_token
  @hash.fetch('access_token', retrieve_oauth2_access_token)
end
{% endhighlight %}

Now every call to your config's `#access_token` method will send a request to
the server even if the token was obtained on the first call.

For the sake of time and good practices you don't want to send a request to
remote machine every time you want to use a token.

Good practice is to pass a `lambda` as 2nd parameter instead of defining a block.
That will save you time when you have the same default value in the many places.

{% highlight ruby %}
def retrieve_oauth2_access_token
  ... # time consuming operation that sends a request for access token
end

DEFAULT_OAUTH2 = -> { retrieve_oauth2_access_token }

def access_token
  @hash.fetch('access_token', &DEFAULT_OAUTH2) # still a block version
end
{% endhighlight %}

Being aware of this issue can save you lots of time trying to debug the
performance issues in your application.

## Conclusion

When it comes to manage configuration it's almost always better to use the
`#fetch` method over the `or` operator. Not only because it allows `nil` values.
It also helps you discovering missing configuration parts and handle missing
keys with ease.

{% include bio_tomasz_wojcik.html %}
