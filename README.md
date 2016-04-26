# Effective Developer

This is a small gem with some developer quality of life scripts.

## Getting Started

Add to your Gemfile:

```ruby
group :development
  gem 'effective_developer'
end
```

Run the bundle command to install it:

```console
bundle install
```

## Developer tools

### gem_release

A command line shell script that quickly bumps the version of any ruby gem.

It checks for any uncommitted files, updates the gem's `version.rb` with the given version, makes a single file `git commit` with a tag and message, then runs `git push origin master`, `gem build` and `gem push` to rubygems.

To use with any gem, add the following folder to your `PATH` (~/.bashrc or ~/.profile):

```console
export PATH="$PATH:$HOME/effective_developer/bin"
```

Once included in your `PATH`, `gem_release` should be run from the root directory of any ruby gem.

To print the current gem version:

```console
> gem_release
```

To release a new gem version:

```console
> gem_release 1.0.0
```

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

Code and Effect is the product arm of [AgileStyle](http://www.agilestyle.com/), an Edmonton-based shop that specializes in building custom web applications with Ruby on Rails.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
