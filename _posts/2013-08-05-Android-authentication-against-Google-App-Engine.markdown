---
layout: post
title: Android authentication against Google App Engine
categories: [google-app-engine, android]
---
Recently I was a part of project consisting of Google App Engine server side and Android mobile client.
Our main goal was to provide as much SSO as possible so we decided to use same Google accounts both on the server and the client.

This post covers the whole client side authentication - retrieving Google account, invalidating and refreshing the token, receiving cookies from the server and using it for accessing server resources via HttpClient.

## Retrieving Google account and authentication token

For accessing accounts in the Android you must add security permissions in the Android manifest.

### Retrieving Google account
Following snippet allows you to retrieve <accountName\>@gmail.com.

{% highlight java %}
import android.accounts.Account;
import android.accounts.AccountManager;
import android.content.Context;
{% endhighlight %}

{% highlight java %}
private Account getAccountForName(Context context, String accountName) {
    AccountManager manager = AccountManager.get(context);
    Account[] accounts = manager.getAccountsByType("com.google");
    if (accounts == null) {
        return null;
    }
    for (Account account : accounts) {
        if (account.name.equals(accountName)) {
            return account;
        }
    }
    return null;
}
{% endhighlight %}

### Retrieving Auth token from AccountManagerFuture
If we have an account we can get auth token from it.
For more detail about possible exceptions read the <a href="http://developer.android.com/reference/android/accounts/AccountsException.html">official documentation</a>.

{% highlight java %}
import android.accounts.AccountManager;
import android.accounts.AccountManagerFuture;
import android.accounts.AccountsException;
import android.content.Intent;
import android.os.Bundle;
{% endhighlight %}

{% highlight java %}
private String getTokenFromAccountManagerFuture(AccountManagerFuture<Bundle> future) throws AccountsException, IOException {
    Bundle bundle = future.getResult();
    Intent intent = (Intent) bundle.get(AccountManager.KEY_INTENT);
    if (intent != null) {
        //Here you should start intent or throw your own exception that takes the intent and passes it to the other (preferably view) class.
        //This intent is a popup saying that your application want to access accounts. It appears one per installation.
    }
    return bundle.getString(AccountManager.KEY_AUTHTOKEN);
}
{% endhighlight %}

### Retrieving refreshed Auth token
Now we can write a public method to get the refreshed token. For that we will use mentioned methods.
Keep in mind that you have to handle the intent if you passed it somehow.

{% highlight java %}
public String getAuthToken(String accountName) throws AccountsException, IOException {
    Account account = getAccountForName(accountName);
    if (account != null) {
        //Get the current token
        AccountManagerFuture<Bundle> future = manager.getAuthToken(account, "ah", false, null, null);
        String token = getTokenFromAccountManagerFuture(future);
        //We want to invalidate token every time just to be sure our new token is valid.
        //By default tokens expire every 24h.
        manager.invalidateAuthToken("com.google", token);
        //Get the new token
        future = manager.getAuthToken(account, "ah", false, null, null);
        return getTokenFromAccountManagerFuture(future);
    }
    return null;
}
{% endhighlight %}

## Making requests with token
For this part you will need an application to be hosted on AppSpot.
Let's say that your application is simply named 'test', so it's address is:
{% highlight java %}
"http://test.appspot.com"
{% endhighlight %}

### Authentication
Google App Engine provides a special path for authentication using token.
The path we will use is with a redirect to localhost:
{% highlight java %}
"/_ah/login?continue=http://localhost/&auth="
{% endhighlight %}


And the whole URL looks like this:
{% highlight java %}
"http://test.appspot.com/_ah/login?continue=http://localhost/&auth="
{% endhighlight %}
As you can see we have to append our token at the end.
Then we issue a GET request to that URL and we are almost done.

{% highlight java %}
public HttpGet getAuthenticateRequest(String token) {
    return new HttpGet("http://test/appspot.com/_ah/login?continue=http://localhost/&auth=" + token);
}
{% endhighlight %}

### Google App Engine token cookie
We have to use the same HttpContext, that we used for authentication, for every request in the application.
Remember to implement error handling in this method. Http status code 302 (`HttpStatus.SC_MOVED_TEMPORARILY`) is ok for authentication request.

{% highlight java %}
//Get token using our method
public HttpContext getAuthenticatedHttpContext(String account) {
    String token = getAuthToken(account);
    HttpGet getRequest = getAuthenticateRequest(token);
    HttpContext httpContext = new HttpContext();
    HttpResponse response = httpClient.execute(getRequest, httpContext);
    return httpContext;
}
{% endhighlight %}
From now we can make authenticated requests using our httpContext;
## Troubleshooting
There can be a case that you will not get the cookie used for authentication in the requested httpContext.
For that you should use extend HttpContext and check if there is a cookie:
{% highlight java %}
import org.apache.http.client.CookieStore;
import org.apache.http.client.protocol.ClientContext;
import org.apache.http.cookie.Cookie;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.http.protocol.HttpContext;
{% endhighlight %}

{% highlight java %}
public class AuthenticatedHttpContext implements HttpContext {

    //There are 2 keys for cookie:
    public static final String AUTH_COOKIE = "ACSID";
    public static final String AUTH_COOKIE2 = "SACSID";

    private HttpContext httpContextDelegate = new BasicHttpContext();
    private CookieStore cookieStore = new BasicCookieStore();

    public AuthenticatedHttpContext() {
        setAttribute(ClientContext.COOKIE_STORE, cookieStore);
    }

    @Override
        public Object getAttribute(String id) {
            return httpContextDelegate.getAttribute(id);
        }

    @Override
        public void setAttribute(String id, Object obj) {
            httpContextDelegate.setAttribute(id, obj);
        }

    @Override
        public Object removeAttribute(String id) {
            return httpContextDelegate.removeAttribute(id);
        }

    public boolean containsAuthCookie() {
        for (Cookie cookie : cookieStore.getCookies()) {
            if (cookie.getName().equals(AUTH_COOKIE)
                    || cookie.getName().equals(AUTH_COOKIE2)) {
                return true;
            }
        }
        return false;
    }
}
{% endhighlight %}



{% include bio_tomasz_wojcik.html %}
