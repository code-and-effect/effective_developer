# Tooling Setup

## Rubocop

### Gems included

The following gems should be installed by effective_developer

- rubocop
- rubocop-performance
- rubocop-rails

### Visual Studio Code extensions for Rubocop

[The Ruby Extension](https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby) and [ruby-rubocop](https://marketplace.visualstudio.com/items?itemName=misogi.ruby-rubocop) are required for Rubocop to run properly.

### Visual Studio Code Settings

Open your `settings.json` through the command palette and use either the defaults given or the custom settings below

```json
  // RUBY SETTINGS
  // I hard coded some paths here that you will need to adjust yourself
  // Basic settings: turn linter(s) on
  "ruby.lint": {
    "reek": true,
    "rubocop": true,
    "ruby": true, //Runs ruby -wc
    "fasterer": true,
    "debride": true,
    "ruby-lint": true
  },
  "[ruby]": {
    // You may need to set this option if Rubocop is not found
    // "rubocop.executePath": "/path/to/your/shims/folder/",
    "editor.tabSize": 2,
    "ruby.codeCompletion": "rcodetools",
    "ruby.format": "rubocop",
    "editor.formatOnSave": false,
    "ruby.intellisense": "rubyLocate",
    "ruby.useLanguageServer": true,
    // You may need to set the following if the linting isn't working
    // "ruby.linter.executablePath": "/path/to/your/ruby/folder/inside/shims/folder/",

    // Time (ms) to wait after keypress before running enabled linters. Ensures
    // linters are only run when typing has finished and not for every keypress
    "ruby.lintDebounceTime": 500,
    "editor.defaultFormatter": "misogi.ruby-rubocop"
  },
  ```
  
## Haml-lint

### Gems included

The following gems should be installed by effective_developer

- haml_lint

### Visual Studio Code extensions for Haml-lint

[Haml Lint](https://marketplace.visualstudio.com/items?itemName=aki77.haml-lint) is required for linting to work properly and [Better Haml](https://marketplace.visualstudio.com/items?itemName=karunamurti.haml) is recommended to be installed as well.

### Visual Studio Code Settings

Open your `settings.json` through the command palette and set your tab size.

```json
  "[haml]": {
    "editor.tabSize": 2,
  },
  ```
  
  ## Sync your settings
  
  Installing [Settings Sync](https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync) is recommended to preserve your settings and extensions across machines and installs.
