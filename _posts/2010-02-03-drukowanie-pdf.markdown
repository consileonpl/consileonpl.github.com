---
layout: post
title: Drukowanie bezposrednio do PDF
categories: [rubyonrails]
---
W aplikacjach webowych format [PDF](http://pl.wikipedia.org/wiki/Pdf) ugruntował już swoją pozycję. W wiekszości przypadków jest formatem
w którym "drukowane" są zarówno faktury jak i wszelkiej maści dokumenty informacyjne. W przypadku frameworka
Ruby on Rails do tej pory korzystałem z biblioteki [Prawn](http://prawn.majesticseacreature.com/).

Niestety możliwości tej biblioteki są dość ubogie jeśli chodzi o tworzenie dokumentów mocno customizowanych.
Wymusząjąc wręcz rysowanie co bardziej skomplikowanych elementów wizualnych. W powiązaniu z wymaganiami klienta
powodowało to ciągłą, syzyfową pracę, by zapewnić poprawne wyświetlanie dokumentów gdzie treść oraz jej rozkład
mogł się zmieniać.

Zrażony tymi problemami postanowiłem znaleść rozwiązanie bazujące na htmlu jako formacie źródłowym dla PDF.
Skierowałem swoje pierwsze kroki w kierunku [GitHuba](http://github.com) i tam też znalazłem gotowe rozwiązanie moich problemów
w postaci plugina.

Plugin nazywa się [Wicket PDF](http://github.com/mileszs/wicked_pdf ) i jest tak naprawde prostym wrapperem dla programu uruchamianego z lini poleceń
[wkhtmltopdf](http://code.google.com/p/wkhtmltopdf/) (bazujący na webkit). 

Instalacja rozwiązania polega na zainstalowaniu wkhtmltopdf (ze źródeł, bądź z prekompilowanych binarek)

w przypadku mojego systemu operacyjnego(Mac OSX) wygląda to następująco:

{% highlight bash %}
$ wget http://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.9.1-OS-X.i368
$ sudo mv wkhtmltopdf-0.9.1-OS-X.i368 /opt/local/bin/wkhtmltopdf
$ sudo chmod +x /opt/local/bin/wkhtmltopdf
{% endhighlight %}
  
możemy oczywiście przetestować funkcjonowanie tego programu:

{% highlight bash %}
$ wkhtmltopdf www.google.pl google.pdf
{% endhighlight %}

lub

{% highlight bash %}
$ wkhtmltopdf file:///Users/andrzejsliwa/Desktop/test.html test.pdf
{% endhighlight %}

następnie instalujemy sam plugin:

{% highlight bash %}
$ script/plugin install git://github.com/mileszs/wicked_pdf.git
{% endhighlight %}
  

tak zainstalowany plugin można bez problemu wykorzystać w następujący sposób:

{% highlight ruby %}
# GET /pages/1
# GET /pages/1.xml
def show
  @page = Page.find(params[:id])

  respond_to do |format|
    format.html # show.html.erb
    format.xml  { render :xml => @page }
    format.pdf do
      render :Pdf => "#{@page.id}",
        :template => 'pages/show.html.erb',
        :wkhtmltopdf => '/opt/local/bin/wkhtmlopdf'
    end
  end
end
{% endhighlight %}

generowanie linków dla dokumentów pdf może wyglądać następująco:

{% highlight html %}
<%= link_to "PDF", page_path(@page, :format => 'pdf'), :target => "_blank"%>
{% endhighlight %}

Lektura obowiązkowa:  
[http://github.com/mileszs/wicked_pdf](http://github.com/mileszs/wicked_pdf)  
[http://code.google.com/p/wkhtmltopdf/](http://code.google.com/p/wkhtmltopdf/)

Autor: [Andrzej Śliwa](http://andrzejsliwa.com)