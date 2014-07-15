---
layout: post
categories: [terminal, tools]
title: Fast terminal file system navigation
---

When it comes to file system navigation in terminal, default solutions often are
too clumsy. In `bash` autocompletion is annoying because of case-sensitivity.
On the other hand `zsh` can autocomplete case insensitively and with fuzzy
string searching but it matches only names in the working directory.

Thankfully there is a tool for the most popular shells that greatly improves
navigation speed: [autojump][1]. Bascially it remembers (in own database) every
directory you've visited and allows you to easily jump to them via `autojump`
or more convenient `j` command.

## Installation

Autojump can be easily installed via following package tools: `yum`, `apt-get`,
`brew`, `ports`. For this post I'm using `Mac OS X` with `zsh` and `brew`.

{% highlight bash %}
brew install autojump
{% endhighlight %}

After installation completes one last thing must be done: `autojump.sh` must be
added to the terminal rc file (`.zshrc` in my case, lines suggested by the `brew`):

{% highlight bash %}
[[ -s `brew --prefix`/etc/autojump.sh ]] && . `brew --prefix`/etc/autojump.sh
{% endhighlight %}

## Usage

The key to successful autojumping is to get rid of habit of `cd` usage. Instead
of typing few `cd ..` and then `cd <tab>` just use `j` alias.

This post is based on the following example: we have a `projects` directory which
contains exact client names, which further contain exact project names.

{% highlight bash %}
projects
├── Bathing Company Inc
│   └── bath-shop
├── Cinnamon Cafe
│   └── gadget's-shop
└── The Washers
    └── shop
{% endhighlight %}

First things first: create `projects` with `Bathing Company Inc`, then visit it
and navigate somewhere else (home should be fine).
To get back to that nested, annoying space-named directory simply enter `j bath`.

### Matching multiple directories

When navigating through the file system for a while you will visit directories
with the same name or same name parts. This is easily handled by the autojump.

For this example every directory in the projects tree must be visited.

Let's try to enter Cinnamon Cafe's shop (`j shop<tab>`).
It expands to something like this:

{% highlight bash %}
j shop__
{% endhighlight %}

Hit `tab` again and you will get prompt like this:

{% highlight bash %}
shop__1__/Users/username/projects/Bathing\ Company\ Inc/bath-shop
shop__2__/Users/username/projects/Cinnamon\ Cafe/gadget\'s-shop
shop__3__/Users/username/projects/The\ Washers/shop
{% endhighlight %}

At the first glance it's ugly and messy. Nothing further from the truth.
Just look at ending of the prompt, then look at the number. It is indexed
for the convenience! Instead of typing Cinnamon Cafe's in our case we just add
`2` to our `j shop__` and hit enter.

{% highlight bash %}
j shop__2
{% endhighlight %}

Then we navigate to the Bathing Company's shop.

{% highlight bash %}
j shop__1
{% endhighlight %}

Fast and simple. But there is more goodness in the autojump.
It reorders indexes based on the usage. So after we've jumped few more times
to the Cinnamon's Cafe, we will get the folowing prompt:

{% highlight bash %}
shop__1__/Users/username/projects/Cinnamon\ Cafe/gadget\'s-shop
shop__2__/Users/username/projects/Bathing\ Company\ Inc/bath-shop
shop__3__/Users/username/projects/The\ Washers/shop
{% endhighlight %}

Notice that `1` is now Cinnamon Cafe and `2` is Bathing Company.

### Deleting directories

Removing directories in the file system is also supported by the autojump.
Deleting whole `The Washers` directory and trying to jump to the `shop` will
give us prompt without deleted directory:

{% highlight bash %}
shop__1__/Users/username/projects/Cinnamon\ Cafe/gadget\'s-shop
shop__2__/Users/username/projects/Bathing\ Company\ Inc/bath-shop
{% endhighlight %}

## Known bugs

As stated on the [project's page][1]:

* autojump does not support directories that begin with `-`.
* For bash users, autojump keeps track of directories by modifying `$PROMPT_COMMAND`. Do not overwrite `$PROMPT_COMMAND`

{% include bio_tomasz_wojcik.html %}

[1]: https://github.com/joelthelion/autojump
