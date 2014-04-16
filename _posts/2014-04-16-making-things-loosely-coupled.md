---
layout: post
categories: [wzorce, ruby]
---
Every developer has heard terms like **loose** or **tight coupling** yet still
a lot have problems maintaining coupling in their codebase. Let's take a look into
some code and try to identify where it is tightly coupled and refactor making it
more maintainable and testable.

## Facing a code

So here is a class:

{% highlight ruby %}
class ListsUsbSupportedFiles
  def list_absolute_paths
    Dir.glob(pattern)
  end

  def list_relative_paths
    Dir.glob(pattern).map { |path| path.gsub(usb_path, '') }
  end

  private

  def pattern
    "#{usb_path}/**/**#{supported_file_types}"
  end

  def supported_file_types
    @file_types ||= "{#{Document::SUPPORTED_FILE_TYPES.join(',')}}"
  end

  def usb_path
    @usb_path ||= UsbKey.new.path
  end
end
{% endhighlight %}

A purpose of this class is simple - it should be able to list relative or
absolute paths to all files that are stored in a USB drive and are of
appropriate, supported file type. Now pause for a moment and take a look
onto that class and try to identify all places where it is tightly
coupled.

### Problems are rising

The easiest way to identify coupling is finding all references to other
classes. Each time you've encounter reference to other class you should
ask yourself: *is this class really needs to know all that about that
other class?*.

Our example references following classes: `Dir`, `Document` and `UsbKey`.
Let's try answering above question for each of them:

* `Dir` - it is a class from a Ruby's standard library. There is in fact
nothing wrong referencing classes from the std-lib and this kind of coupling
can be safely left and refactored only if there is a good reason behind
that.
* `Document` - that class provides us a list of supported files. But do
we really need to know that this list is in a `Document` class?
* `UsbKey` - this class is used to get a path to a directory where
USB is mounted. But do we really need to instantiate that class to just
invoke one method on it?

So we can say that coupling to classes `Document` and `UsbKey` is tight.
But there is one more subtle kind of coupling in this class.

### Huston now we have a real problem

You can argue that referencing to `Document` and `UsbKey` classes is
a big problem. Maybe, but let me ask you something. How you would
write a test for that class? Think about it for a while. How you would
test if this class correctly lists file paths?

Current implementation is not only tightly coupled with `UsbKey` class.
It is tightly coupled with a USB itself. You will need to have an USB
stick plugged into your machine to make tests passing! Of course you
could try mocking and it will work but let's check how it might look:

{% highlight ruby %}
UsbKey = double unless defined?(UsbKey)

allow(UsbKey).to receive(:new).and_return(usb_key)
allow(usb_key).to receive(:path).and_return(path)
{% endhighlight %}

It will work. But just because it works it doesn't mean it is good.
Firstly this amount of mocking for such a simple class should be already
suspicious. Secondly what this code is really doing is **mocking
class internals** and you shouldn't care about class internals.
Burn it into your head: **never, ever mock object internals**. Never.
Just don't do it. Everybody will be more happy. By internals you should
consider all private methods, state and all collaborators which are not
injected into that class. If you ever need to mock one of these in order
to make code testable it means that your design is wrong.

If you are more interested in why you shouldn't mock object's internal state
(also called implementation detail) check [Ian Cooper's great presentation][1].

## Decoupling for the win

So lets try to refactor that class this time doing it right. Let's
start with writing some tests:

{% highlight ruby %}
describe File::FileList do
  describe '#absolute_paths' do
    it 'returns absolute paths to files'
  end

  describe '#relative_paths' do
    it "returns paths realtively to list's root path"
  end
end
{% endhighlight %}

We are expecting a class `File::FileList` to provide 2 methods
one to return absolute second to return relative paths. Both should
include only paths to supported files however I've skipped that
for simplicity and in fact current specs will cover that. In production we
could add appropriate examples for documentation purposes.

We need to setup some directory and files structure as a fixture:

    spec/fixtures/lib/file/file_list_spec/
      subdir/
        file2.rb
        file3.py
        ignore2.exe
      file1.rb
      ignore1.exe

Now we can imlement example for `#absolute_paths` method:

{% highlight ruby %}
ROOT_PATH = File.join('spec', 'fixtures', 'lib', 'file', 'file_list_spec')
ABSOLUTE_ROOT_PATH = File.expand_path(ROOT_PATH)

subject { File::FileList.new(ABSOLUTE_ROOT_PATH, includes: %w(rb py)) }

describe '#absolute_paths' do
  let(:absolute_paths) do
    [
      File.join(ABSOLUTE_ROOT_PATH, 'file1.rb'),
      File.join(ABSOLUTE_ROOT_PATH, 'subdir', 'file2.rb'),
      File.join(ABSOLUTE_ROOT_PATH, 'subdir', 'file3.py'),
    ]
  end

  it 'returns absolute paths to files' do
    expect(subject.absolute_paths).to match_array absolute_paths
  end
end
{% endhighlight %}

Time to move some code to our new class:

{% highlight ruby %}
class File::FileList
  def initialize(root_path, opts = {})
    @root_path = root_path
    @includes  = opts[:includes].join(',') if opts[:includes]
  end

  def absolute_paths
    Dir.glob(pattern)
  end

  private

  attr_reader :root_path, :includes

  def pattern
    "#{root_path}/**/**#{supported_files}"
  end

  def supported_files
    "{#{includes}}"
  end
end
{% endhighlight %}

I've introduced a list of supported files via optional hash parameter
(in ruby 2.x we would use keyword arguments) that should be tested in
separate context, but I'm not gonna to do that in this post.

Given code passes the specs so we can implement example for `#relative_paths`:

{% highlight ruby %}
describe '#relative_paths' do
  let(:relative_paths) do
    [
      File.join('file1.rb'),
      File.join('subdir', 'file2.rb'),
      File.join('subdir', 'file3.py'),
    ]
  end

  it "returns paths realtively to list's root path" do
    expect(subject.relative_paths).to match_array relative_paths
  end
end
{% endhighlight %}

Now we can move remaining code to a new class:

{% highlight ruby %}
class File::FileList

  # ...

  def relative_paths
    Dir.glob(pattern).map do |path|
      path.gsub("#{root_path}/", '')
    end
  end

  # ...

end
{% endhighlight %}

And we're done!

## Conclusion

Let's summarize work we've done in the refactoring:

* We've removed coupling to `Document` class by providing a list
of supported files in a constructor.
* We've removed coupling to `UsbKey` class by providing a path
in a constructor.
* We've removed coupling to USB mount location making a new class
more generic and potentially useful in other cases.

But most importantly by making a class decoupled we made it perfectly
testable without a need to mock any of its internals. Not only the
class is more useful but the code is more maintainable now. And thats the
real profit of making objects loosely coupled.

Each time you are instantiating a class within some other class think
do you really need to know that object. If there is only one particular
information you need from it or you want to call some method but
you are not interested on object's state, probably you can achieve the
same by injecting that object and decoupling things. This way you could
test classes with ease. Limiting collaborators is a great and simple
technique to achieve testable and maintainable code without much hussle.

{% include bio_michal_orman.html %}

[1]: http://vimeo.com/68375232
