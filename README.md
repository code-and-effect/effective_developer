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

To use the included git hooks for all git repos, run the following:

```
git config --global core.hooksPath ~/effective_developer/githooks
```

# Shell scripts

To use the included command line shell scripts:

```console
export PATH="$PATH:$HOME/effective_developer/bin"
```

## gem_develop

A command line shell script to update a `Gemfile` and use any provided gems locally.

This makes it very quick to swich to developing a gem locally.

`gem_develop` should be run from the root directory of any rails app.

```console
> gem_develop effective_datatables effective_resources
```

to change:

```ruby
gem 'effective_datatables'
gem 'effective_resources'
```

into:

```ruby
gem 'effective_datatables', path: '~/Sites/effective_datatables'
gem 'effective_resources', path: '~/Sites/effective_resources'
```

and execute `bundle`.

You can override the `~/Sites/` directory by setting `ENV['GEM_DEVELOP_PATH']`.

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

## gem_reset

A command line shell script to update a `Gemfile` to find any locally developed gems, and update them to the most current released version.

`gem_reset` should be run from the root directory of any rails app.

Just run with no arguments:

```console
> gem_reset
```

to change:

```ruby
gem 'effective_datatables', path: '~/Sites/effective_datatables'
gem 'effective_resources', path: '~/Sites/effective_resources'
```

into:

```ruby
gem 'effective_datatables'
gem 'effective_resources'
```

and execute `bundle update effective_datatables effective_resources`.


## gitreset

Careful, this command will delete all your un committed changes.

A command line script to call `git reset --hard` and also delete any newly created files.

It truly resets you back to a fresh working copy.  Perfect for tweaking scaffold and code generation tools.

```console
> gitreset
```

## gitsweep

A command line script to delete any git branch that has already been merged into master & develop

```console
> gitsweep
```

## killpuma

`kill -9` the first running puma process. Bails out of SystemStackError (stack level too deep).

```console
> killpuma
```

# Git hooks

To use the included git hooks for all git repos, run the following:

```
git config --global core.hooksPath ~/effective_developer/githooks
```

## pre-push

Prevents pushing git commits that have the following bad patterns:

- Gemfile includes 'path: ' gems
- binding.pry

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
rake csv:scaffold
```

or

```ruby
rake csv:scaffold[users]
```

## rename_class

Quickly rename a rails class throughout the entire app.

The script considers the `.classify`, `.pluralize` and `.singularize` common usage patterns.

Then performs a global search and replace, and renames files and directories.

```ruby
rake rename_class[account,team]
```

or

```ruby
rake rename_class[account,team,skipdb]
```

to skip any changes to database migrations.


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

## validate

Loads every ActiveRecord object and calls `.valid?` on it.

```ruby
rake validate
rake validate[post]
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

# Code Generation

The goal of the `effective_developer` code generation project is to minimize the amount of hand coding required to build a rails website.

Only the rails model file should be written by a human.

All database migrations, controllers, forms and views should be generated.

Creating a new working in-place CRUD feature should be a 1-liner.

A huge head start to the interesting part of the code.

## effective scaffolds

Scaffolding is the fastest way to build a CRUD rails app.

The effective scaffolds generally follow the same pattern as the (rails generate)[http://guides.rubyonrails.org/command_line.html#rails-generate] commands.

To create an entire CRUD resource from the command line:

```ruby
rails generate effective:scaffold thing name:string description:text
rails generate effective:scaffold thing name:string description:text --actions index show mark_as_paid
rails generate effective:scaffold admin/thing name:string description:text
rails generate effective:scaffold admin/thing name:string description:text --actions crud-show

```

Or to skip the model & migration:

```ruby
rails generate effective:scaffold_controller thing
rails generate effective:scaffold_controller thing index show
rails generate effective:scaffold_controller thing index show --attributes name description
rails generate effective:scaffold_controller admin/thing crud mark_as_paid
rails generate effective:scaffold_controller admin/thing crud-show
```

### model file

If there is a regular rails model file present, all attributes, belong_tos, scopes and has_many accepts_nested_attributes
will be considered when generating the scaffold.

Make a model file like this (or generate it with `rails generate effective:model post name:string body:text` and tweak from there):

```ruby
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category

  # Attributes
  # title        :string
  # body         :text
  # published_at :datetime

  validates :title, presence: true
  validates :description, presence: true

  has_many :comments
  accepts_nested_attributes_for :comments

  scope :published, -> { where.not(published_at: nil) }

  def to_s
    title || 'New Post'
  end
end
```

and then run
```console
rails generate effective:scaffold post
rails generate effective:scaffold_controller admin/post
```

Tweak from here

### all scaffolds

You can call scaffolds one at a time:

```ruby
# These two accept attributes on the command line. like effective:scaffold
rails generate effective:model thing name:string description:text
rails generate effective:migration thing name:string description:text

# Thes accept actions on the command line. Pass --attributes as an option. like effective:scaffold_controller
rails generate effective:controller thing  # /admin/thing
rails generate effective:route thing
rails generate effective:ability thing # CanCanCan
rails generate effective:menu thing  # If app/views/*namespaces/_navbar.html.haml is present
rails generate effective:datatable thing
rails generate effective:views thing
rails generate effective:form thing
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
