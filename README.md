# teeceepee

This is a tiny TCP stack implemented in pure Ruby, for fun and learning, inspired by [@jvns][jvns-github].

Julia wrote a blog called: [What happens if you write a TCP stack in Python?][jvns-article], and I saved it to my Pocket and then moved it to Chrome bookmark folder called "Call me maybe", but never touched it ever since.

Recently, I decided to give it a try and implement a tiny tcp stack in Ruby language.

There is an example in `examples/get_page.rb`, you could open it and update the `FAKE_IP_ADDRESS` and the webpage you would like to get. Then, just run it in your terminal:

``` bash
bundle install
sudo ruby examples/get_page.rb
```

![Example](https://raw.githubusercontent.com/larrylv/teeceepee/master/assets/get_groupon_com.png)

I run it with Ruby 2.2.2 on Linux. There is an issue of `PacketFu` gem to get it working on Mac OS X.

I wrote a blog about some details of this fun project, go check it out [Write a TCP Stack in Ruby][larry-article].

[jvns-github]: https://github.com/jvns
[jvns-article]: http://jvns.ca/blog/2014/08/12/what-happens-if-you-write-a-tcp-stack-in-python/
[larry-article]: http://blog.larrylv.com/write-a-tcp-stack-in-ruby/

