# LogLineParser

LogLineParser is a simple parser of Apache access logs. It parses a line of Apache access log and turns it into an array of strings or a Hash object.

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

### As a converter


```ruby
require 'log_line_parser'

line = '192.168.3.4 - - [07/Feb/2016: ... ] ...'
LogLineParser.parse(line).to_a
# => ["192.168.3.4", "-", "-", "07/Feb/2016: ... ", ... ]
```

Or in limited cases, parsers corresponding to  certain LogFormats are available:

```ruby
require 'log_line_parser'

line = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/start.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
LogLineParser::CombinedLogParser.to_hash(line)
# => {
#   "%h" => "192.168.3.4",
#   "%l" => "-",
#   "%u" => "quidam",
#   "%t" => "07/Feb/2016:07:39:42 +0900",
#   "%r" => "GET /index.html HTTP/1.1",
#   "%>s" => "200",
#   "%b" => "432",
#   "%{Referer}i" => "http://www.example.org/start.html",
#   "%{User-agent}i" => "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0",
#   "%m" => "GET",
#   "%H" => "HTTP/1.1",
#   "%U%q" => "/index.html"
# }
```

Three parsers are predefined for such cases:

<dl>
<dt>CommonLogParser</dt>
<dd>For Common Log Format (CLF)</dd>
<dt>CommonLogWithVHParser</dt>
<dd>For Common Log Format with Virtual Host</dd>
<dt>CombinedLogParser</dt>
<dd>NCSA extended/combined log format</dd>
</dl>

#### Defining a parser

You can define your own parser as in the following example:

```ruby
require 'log_line_parser'

RefererLogParser = LogLineParser.parser('"%r" %>s %b %{Referer}i -> %U')

line = '"GET /index.html HTTP/1.1" 200 432 http://www.example.org/start.html -> /index.html'

RefererLogParser.to_hash(line)
# => {
#   "%r" => "GET /index.html HTTP/1.1",
#   "%>s" => "200", "%b" => "432",
#   "%{Referer}i" => "http://www.example.org/start.html",
#   "->" => "->",
#   "%U" => "/index.html",
#   "%m" => "GET",
#   "%H" => "HTTP/1.1",
#   "%U%q" => "/index.html"
# }
```

#### Limitations

* Currently, you should include at least `%r`, `%>s` and `%b` in the format strings passed to `LogLineParser.parser`.
* If the value of a field is expected to contain a space, you should enclose that field in double quotes.

### As a command-line application

The command line tool `log_line_parser` can be used for two purposes:

1. For converting file formats
2. For picking up log records that satisfy certain criteria

For the first purpose, the tool support conversion from an Apache log format to CSV or TSV format.
And for the second purpose, criteria such as :not_found?(= :status_code_404?) or access_by_bots? are defined, and you can combine them writing a configuration file.

#### For converting file formats

Suppose you have an Apache log file [example_combined_log.log](./test/data/example_combined_log.log), and the following command in your terminal:

    $ log_line_parser example_combined_log.log > expected_combined_log.csv

Then you will get [expected_combined_log.csv](./test/data/expected_combined_log.csv).

To convert into TSV format:

    $ log_line_parser --to=tsv example_combined_log.log > expected_combined_log.tsv

And you will get [expected_combined_log.tsv](./test/data/expected_combined_log.tsv).

#### For picking up log records

First, you have to prepare a configuration file in YAML format. [samples/sample_config.yml](./samples/sample_config.yml) is an example.

And if you want to pick up from [samples/sample_combined_log.log](./samples/sample_combined_log.log) the records that match the definintions in the configuration file, run the following command:

    $ log_line_parser --filter-mode --log-format combined --config=samples/sample_config.yml --output-dir=samples/output samples/sample_combined_log.log

The results are in [samples/output](https://github.com/nico-hn/LogLineParser/tree/master/samples/output/) directory.



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec log_line_parser` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/nico-hn/LogLineParser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
