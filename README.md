# Loose ERBs

A tool to help find Loose ERBs in your app!

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add loose_erbs

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install loose_erbs

## Usage

```shell
$ loose_erbs
/home/hartley/test/dm/app/views/layouts/application.html.erb
/home/hartley/test/dm/app/views/posts/_form.html.erb
/home/hartley/test/dm/app/views/posts/_post.html.erb
/home/hartley/test/dm/app/views/posts/edit.html.erb
└── /home/hartley/test/dm/app/views/posts/form
/home/hartley/test/dm/app/views/posts/index.html.erb
└── posts/post
/home/hartley/test/dm/app/views/posts/new.html.erb
└── /home/hartley/test/dm/app/views/posts/form
/home/hartley/test/dm/app/views/posts/show.html.erb
└── posts/post
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/skipkayhil/loose_erbs.

## License

The gem is available as open source under the terms of the [MIT License][].

[MIT License]: https://opensource.org/licenses/MIT
