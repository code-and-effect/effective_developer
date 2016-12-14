# Effective Developer

This gem contains some developer quality of life scripts and rails helpers.

## Getting Started

To use the included rails helpers and rake tasks in your current rails project, add to the Gemfile:

```ruby
group :development
  gem 'effective_developer'
end
```

Run the bundle command to install it:

```console
bundle install
```

To use the included command line shell scripts in any directory, clone this repo:

```console
git clone git@github.com:code-and-effect/effective_developer.git
```

and add the following to your `PATH` (edit your ~/.bashrc or ~/.profile):

```console
export PATH="$PATH:$HOME/effective_developer/bin"
```

# Shell scripts

## gem_release

A command line shell script that quickly bumps the version of any ruby gem.

It checks for any uncommitted files, updates the gem's `version.rb` with the given version, makes a single file `git commit` with a tag and message, then runs `git push origin master`, `gem build` and `gem push` to rubygems.

`gem_release` should be run from the root directory of any ruby gem.

To print the current gem version:

```console
> gem_release
```

To release a new gem version:

```console
> gem_release 1.0.0
```

## gitsweep

A command line script to delete any git branch that has already been merged into master & develop

```console
> gitsweep
```

## BFG Repo-Cleaner

A command line script that calls [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) to remove sensitive data from the git repository history.

```console
> bfg --delete-files id_rsa.pub
```

# Rake scripts

## csv:export

Exports all database tables to individual .csv files.

```ruby
rake export:csv
```

## csv:import::foos

Where table is the name of a model.  Dynamically created rake task when a `/lib/csv_importers/foos.rb` file is present.

```ruby
rake csv:import:foos
```

## csv:import::scaffold

Scaffolds an `Effective::CSVImporter` file for each .csv file in `/lib/csv_importers/data/*.csv`

```ruby
rake csv:import:scaffold
```

or

```ruby
rake csv:import:scaffold[users]
```

## reset_pk_sequence

If you ever run into the error `duplicate key violates unique constraint (id) error`, run this script:

```ruby
rake reset_pk_sequence
```

This makes sure that the autoincremented (postgresql) Pk sequence matches the correct `id` value.

## pg:pull

Creates a new backup on heroku, downloads that backup to latest.dump, and then calls pg:load

```ruby
rake pg:pull
rake pg:pull[staging]
```

## pg:load

Drops and re-creates the local database then initializes database with the contents of latest.dump

```ruby
rake pg:load
rake pg:load[something.dump]
```

## pg:save

Saves the development database to a postgresql .dump file (latest.dump by default)

```ruby
rake pg:save
rake pg:save[something.dump]
```

## pg:clone

Clones the production (--remote heroku by default) database to staging (--remote staging by default)

```ruby
rake pg:clone
rake pg:clone[origin,staging]
```

# Rails Helpers

## CSV Importer

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

Override `before_import()` or `after_import()` to run code before or after the import.

# Scaffolding

Scaffolding is the fastest way to build a rails app.  Take advantage of scaffolding.


```ruby
rails generate scaffold product name:string  # active_record, test_unit, resource_route, scaffold_controller, haml, test_unit, helper, assets
rails generate scaffold_controller product  # haml, test_unit, helper,
rails generate model product  # active_record, test_unit
rails generate active_record:model product   # test_unit
rails generate resource_route product
rails generate test_unit:model product
rails generate mailer product
rails generate job product


rails generate effective:controller Thing --attributes name:string description:text one:string two:string three:string four:string five:string six:string seven:string eight:string nine:string ten:string roles:string

rails generate effective:scaffold Thing name:string description:text one:string two:string three:string four:string five:string six:string seven:string eight:string nine:string ten:string roles:string --actions index show edit

rails generate effective:controller Thing

```



## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
