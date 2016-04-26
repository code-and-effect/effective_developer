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

## gem_release

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

## .csv importer

Extend a class from `Effective::CSVImporter` to quickly build a csv importer.

Put your importer in `lib/csv_importers/users_importer.rb` and the data in `lib/csv_importers/data/users.csv`.  Both filenames should be pluralized.

A rake command will be dynamically created `rake import:users`.

### Required Methods

The importer requires two instance methods be defined:

- `def columns` a hash of names to columns.  The constants `A` == 0, `B` == 1, upto `AT` == 45 are defined to work better with spreadsheets.
- `def process_row` will be run for each row of data.  Any exceptions will be caught and logged as errors.

Inside the script, there are a few helpful functions:

- `col(:email)` will return the normalized value in that column.
- `last_row_col(:email)` will return the normalized value for this column in the previous row.
- `raw_col(:email)` will return the raw value in that column

```ruby
module CsvImporters
  class UsersImporter < Effective::CSVImporter
    def columns
      {
        email: A,
        first_name: B,
        last_name: C,
        admin?: D
      }
    end

    def process_row
      User.new(email: col(:email), first_name: col(:first_name), last_name: col(:last_name), admin: col(:admin?)).save!
    end

  end
end
```

When using `col()` or `last_row_col()` helpers, the value is normalized.

- Any column that ends with a `?` will be converted into a boolean.
- Any column that ends with `_at` will be converted into a DateTime.
- Any column that ends with `_on` will be converted into a Date.
- Override `def normalize` to add your own.

```ruby
def normalize(column, value)
  if column == :first_name
    value.upcase
  else
    super
  end
end
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
