---
layout: post
title: Android authentication against Google App Engine
categories: [google-app-engine, android]
---
Android is experiencing a rapid growth. From the device that handled emails, texts and calls it expanded to a device that can do almost all work that computers did.
Our everyday work now can be done on almost every portable device - however many of us experienced problems with web application UX on mobile devices.
That obviously lead to native ports of web clients.

But what if we are developing a web application along with a mobile client?

One of the best tandems for such work is combining <a href="https://developers.google.com/appengine/docs/whatisgoogleappengine">Google App Engine</a> as our target platform and Android as client.
Knowing that almost every Android user has Google Account and having SSO for free seems like a big advantage.

This article covers how to configure, authenticate and perform authorized requests to Google App Engine application from Android application using Google Accounts API.

## Overview

Authentication against Google App Engine using Google Accounts API is done by accessing Google Account (which was added in Android) and use it's token to get authentication cookie.

Authentication is one done in the following steps:

- Obtain authentication token from the Google Account,
- Use that token to retrieve authentication cookie from Google App Engine,
- Use authentication cookie in every request made further.

Tokens by default expire after 24 hours. On expiration you should invalidate token, obtain new one and request new authentication cookie for further requests.


Invalidating token is done in the following steps:

- Obtain authentication token from the Google Account,
- Invalidate that token,
- Obtain newly generated authentication token from the Google Account,
- Use that token to retrieve authentication cookie from Google App Engine.

## Android Manifest

Accessing accounts in the Android requires security permissions in the Android manifest.

{% highlight xml %}
<uses-permission android:name="android.permission.GET_ACCOUNTS"></uses-permission>
<uses-permission android:name="android.permission.USE_CREDENTIALS"></uses-permission>
<uses-permission android:name="android.permission.INTERNET"></uses-permission>
{% endhighlight %}

For more information about the permissions visit <a href="http://developer.android.com/reference/android/Manifest.permission.html">documentation</a>.

### Retrieving Google account

First step during authentication is to retrieve account's token.
Accessing accounts is done via <a href="http://developer.android.com/reference/android/accounts/AccountManager.html">AccountManager</a>, which can be instantianed by passing Android context to the <a href="http://developer.android.com/reference/android/accounts/AccountManager.html#get(android.content.Context)">get</a> method. Then we retrieve accounts for our domain using <a href="http://developer.android.com/reference/android/accounts/AccountManager.html#getAccountsByType(java.lang.String)">getAccountsByType</a>.

We want to retrieve account for the given username (for this example email is in format username@gmail.com).
{% highlight java %}
private Account getAccountForName(Context context, String username) {
  AccountManager manager = AccountManager.get(context);
  Account[] accounts = manager.getAccountsByType("com.google"); // gmail.com is within google.com type
  if (accounts != null) {
    for (Account account : accounts) {
      if (account.name.equals(username)) {
        return account;
      }
    }
  }
  return null;
}
{% endhighlight %}

When we have the account we are able to get security token from it.
During that process error can occur, asking user for permission to access accounts. This will be passed as the `AccountManager.KEY_INTENT` paramter in the bundle.

{% highlight java %}
private String getAuthToken(Account account) throws AccountsException, IOException {
    AccountManagerFuture<Bundle> future = account.getAuthToken(account, "ah", false, null, null);
    Bundle bundle = future.getResult();
    Intent intent = (Intent) bundle.get(AccountManager.KEY_INTENT);
    if (intent != null) {
        //Here you should start intent or throw your own exception that takes the intent and passes it to the other (preferably view) class.
        //This intent is a popup saying that your application want to access accounts. It appears once per installation.
    }
    return bundle.getString(AccountManager.KEY_AUTHTOKEN);
}
{% endhighlight %}

### Refreshing Auth token
By default after 24 hours our auth token expires, and requests made with expired token will result with an unathorized status code (401).

Following snippet allows you to get refreshed for the given account.

{% highlight java %}
public String getRefreshedAuthToken(String accountName) throws AccountsException, IOException {
    Account account = getAccountForName(accountName);
    if (account != null) {
        String token = getTokenFromAccount(account);
        manager.invalidateAuthToken("com.google", token);
        future = manager.getAuthToken(account, "ah", false, null, null);
        return getTokenFromAccountManagerFuture(future);
    }
    return null;
}
{% endhighlight %}

## Making requests with token
This part requires an application to be hosted on AppSpot.

AppSpot is Google platform for hosting Google App Engine apps.
For more information visit <a href="https://appengine.google.com/start">AppSpot website</a>.

Let's say that your application is simply named 'test', so it's address is:
{% highlight html %}
"http://test.appspot.com"
{% endhighlight %}

### Authentication
Google App Engine provides a special path for authentication using token.
The path we will use contains a redirect to localhost:
{% highlight html %}
"/_ah/login?continue=http://localhost/&auth="
{% endhighlight %}


The whole URL should look like this:
{% highlight html %}
"http://test.appspot.com/_ah/login?continue=http://localhost/&auth="
{% endhighlight %}
As you can see we have to append our token at the end.
Then we send a GET request to the mentioned URL and we are almost done.

{% highlight java %}
public HttpGet getAuthenticateRequest(String token) {
    return new HttpGet("http://test/appspot.com/_ah/login?continue=http://localhost&auth=" + token);
}
{% endhighlight %}

### Google App Engine token cookie
We have to use the same HttpContext, that we used for authentication, for every request in the application.<br>
For the authentication request the HTTP status code 302 (`HttpStatus.SC_MOVED_TEMPORARILY`) is OK - we just don't want to follow any HTTP redirects, because we will move to another screen in our application.

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

From now on we can send authenticated requests using our HttpContext and enjoy SSO for the Google App Engine and Android apps along with other goodies that those technologies gives us.

{% include bio_tomasz_wojcik.html %}
