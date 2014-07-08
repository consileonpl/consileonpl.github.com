---
layout: post
categories: [terminal, tmux, tools]
---
In the recent post ([Terminal Unleashed][1]) I've introduced a great tool that makes
terminal work easier and faster - tmux. I suggest you to read the previous post
before further reading.

## Architecture & reminder

Tmux is based on a client-server architecture - running `tmux` for the first time
will start a server with one session and automatically attach to that session.

To detach from the current session use the command shortcut (default `ctrl+b`)
followed by `d` or followed by `:` and type `detach`.

To attach to a session there are several aliases at your disposal:

* `tmux attach-session -t <session>`
* `tmux attach -t <session>`
* `tmux at -t <session>`

Thanks to the tmux architecture sessions are persistent: any accidential
disconnection or detaching won't destroy the session (and save your work).

Moreover several tmux terminals can join the same session, so you can easily
share your work over multiple clients (for example: pair programming sessions).

Lastly tmux exits when the last window of the last session is closed.

## First contact via SSH

So far we have only attached tmux to the local sessions, to see it's full potential
lets connect from a different machine to our local session.

To do that we will need an SSH server running ([OpenSSH][2]) and an user.
For safety reasons (limited privileges) I suggest adding another user in your OS,
in this tutorial we will call him `pair`. Also create a group (we will name it `tmux_group`).

Don't forget to add both your and `pair` accounts to the group `tmux_group`.

Add your client's public key to the authorized keys file (`~/.ssh/authorized_keys`).

Then test the connection from a remote machine:
{% highlight bash %}
ssh pair@your_machine
{% endhighlight %}

## Sharing tmux

As you may noticed you have connected to your machine, but it is not the tmux
session. Shared tmux session requires a designated socket.

{% highlight bash %}
tmux -S <socket_name> new -s <session_name>
{% endhighlight %}

Lets start the tmux session named "shared" with socket named "pair_sock".
For our convenience create the `/var/tmux` dir which will store the tmux sockets.
Change dir's group to the `tmux_group` and set permissions to 770 (`drwxrwx---`),
otherwise neither you or remote users won't be able to connect.

{% highlight bash %}
tmux -S /var/tmux/pair_sock new -s shared
{% endhighlight %}

Now you are (locally) connected to the session with designated socket
(check `/var/tmux` dir contents for the socket file).

To allow other users to join the specific tmux session we have to add `ForceCommand`
to the `sshd_config`.

`ForceCommand` executues given command after user joins our server.

We also want that command to be invoked only for the `pair` user.

Append the following lines to the `sshd_config`:
{% highlight aconf %}
Match User pair
  ForceCommand /usr/local/bin/tmux -S /var/tmux/pair_sock attach -t shared
{% endhighlight %}

## Restricting users

In previous cases the user `pair` can freely navigate through your system.

To prevent that you can set `read-only` parameter so users will be able only
to watch instead of interacting - just append `-r` to the previous command:

{% highlight aconf %}
Match User pair
  ForceCommand /usr/local/bin/tmux -S /var/tmux/pair_sock attach -t shared -r
{% endhighlight %}

Another solution is to restrict user to a specific program using the `ForceCommand`.
Assume that you want to open an editor when user connects.

The flow is following:

* User connects
* Editor is launched
* When editor is closed the user disconnects automatically

For this example the editor is [Vim][3].

{% highlight aconf %}
Match User pair
  ForceCommand vim /my_project
{% endhighlight %}

## Summary

Session sharing is a great thing, however it is one of the 'two-edged' features.
Incorrectly configured can give too permissive access to your machine which can
lead to bitter consequences.

However this is still a great tool for cooperation, remote machine management
and as stated in the previous post - organising your work.

{% include bio_tomasz_wojcik.html %}

[1]:{{ site.url }}/2014/04/17/terminal-unleashed/
[2]:http://www.openssh.com/
[3]:http://www.vim.org/
