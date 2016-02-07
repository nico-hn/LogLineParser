# LogLineParser

LogLineParser is a simple parser of Apache access logs. It parses a line of Apache access log and turns it into an array of strings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'log_line_parser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install log_line_parser

## Usage

    require 'log_line_parser'
    
    line = '192.168.3.4 - - [07/Feb/2016: ... ] ...'
    LogLineParser.parse(line).to_a
    => ["192.168.3.4", "-" "-" "07/Feb/2016: ... ", ... ]

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec log_line_parser` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/nico-hn/LogLineParser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
