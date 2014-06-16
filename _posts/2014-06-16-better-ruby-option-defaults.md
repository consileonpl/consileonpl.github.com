---
title: Better ruby defaults for hash options
categories: [ruby]
---
Almost every ruby / RoR project includes global configuration. Sometimes it is
a YML file loaded 'as-is', sometimes it's a model or designated configuration
class.

There are cases when we have to fallback to default values. In model or
configuration class the easiest way is to use the `or` operator:

{% highlight ruby %}
class Config
  def initialize
    @hash = {}
  end

  def option=(value)
    @hash['option'] = value
  end

  def option
    @hash['option'] || "option's default value"
  end
end
{% endhighlight %}

However this approach have a major drawback: what if we wanted `nil` as the
option value?

{% highlight ruby %}
config.option = nil # => nil
config.option # => "option's default value"
{$ endhighlight %}

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
config.option = nil # => KeyError: key not found: "option"
config.option = nil # => nil
config.option # => nil
{% endhighlight %}

We have 2 ways for handling default values:

* method with 2 params: `Hash#fetch(key, default)`
* method with a block: `Hash#fetch(key) { default }`

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

Both versions result is as we've expected:

{% highlight ruby %}
config.option # => "option's default value"
config.option = nil # => nil
config.option # => nil
{% endhighlight %}

## The Pitfall

There's a little niuance in providing default values via `#fetch` one probably
isn't aware:

_When the default value is evaluated?_

In the two params version both parameters are _ALWAYS_ evaluated. That' right:
even if there is a value provided, the default value will be evaluated.

Thankfully the block version evaluates block only if there is no value.

In our simple example returning a string this isn't a big thing. However imagine
situation when you perform time-consuming database operation or getting OAuth
access token. You don't want to send a request for OAuth token every time you
use a token you've already obtained.

Being aware of this issue can save you lot of time trying to debug the
performance issues in your application.

## Conclusion

When it comes to manage configuration it's almost always better to use the
`#fetch` method than the `or` operator. Not only because it allows `nil` values.
It also helps you discovering missing configuration parts and handle missing
keys with ease.

{% include bio_tomasz_wojcik.html %}
