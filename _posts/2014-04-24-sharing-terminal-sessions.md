---
layout: post
categories: [tmux, tools]
---
In the recent post ([Terminal Unleashed][1]) I introduced a great tool that makes
terminal work easier and faster - tmux. I suggest you to read the previous post
before further reading.

Tmux is based on a client-server architecture - every created session is a
server, to which you can connect as a client using `tmux attach -t <name>` command.

Because of such architecture you can easily share your terminal session with
someone else - for example to go pair programming.

To get this working I will cover in this post the following topics:

* SSH setup
* launching a tmux server and connecting as a client (using ssh key)
* restricting clients to use a specific program (vim)

## Setup

For safety reasons I recommend creating additional user for sharing sessions.
In your OS create an user (`pair` in my case) and enable remote login.

Install the SSH server ([OpenSSH][2]) and edit the configuration file (`/etc/sshd_config`):

{% highlight aconf %}
PasswordAuthentication no
ChallengeResponseAuthentication no
{% endhighlight %}

Add following lines at the end of file:

{% highlight aconf %}
Match User pair
  X11Forwarding no
  AllowTcpForwarding no
  ForceCommand /usr/local/bin/tmux -S /var/tmux/pair attach -t pair
{% endhighlight %}

The last command (`ForceCommand`) will automatically attach our clients to the
designated tmux socket (`/var/tmux/pair`) and session (`-t pair`).

If you want clients to be read-only add the `-r` parameter:
{% highlight aconf %}
  ForceCommand /usr/local/bin/tmux -S /var/tmux/pair attach -t pair -r
{% endhighlight %}

Don't forget to restart your ssh server everytime you save changes to 
`/etc/sshd_config`:
{% highlight bash %}
kill -HUP <server pid>
{% endhighlight %}

Finally add client's key to the `~/.ssh/authorized_keys`:
{% highlight bash %}
cat client_key.pub >> ~/.ssh/authorized_keys
{% endhighlight %}

## Running the server and connecting as a client

Before client can connect we have to start our tmux session.
It's almost the same like starting typical tmux session, but this time we want
to specify a socket for it (and we will call both socket and session `pair`):

{% highlight bash %}
tmux -S /var/tmux/pair new -s pair
{% endhighlight %}

The `-S <path>` option specifies path to a socket.
I suggest you to create an alias for this command.

Now the client is ready to connect:
{% highlight bash %}
ssh pair@your_machine
{% endhighlight %}

## Restricting clients to a specific program

Sometimes you don't want to give shell access to connected users but to a
specific program. This is SSH, not tmux specific feature.

In the `/etc/sshd_config` edit `ForceCommand` to run the desired program, in
this case vim with project directory:
{% highlight aconf %}
  ForceCommand vim ~/path/to/project
{% endhighlight %}

{% include bio_tomasz_wojcik.html %}

[1]:{{ site.url }}/2014/04/17/terminal-unleashed/
[2]:http://www.openssh.com/
