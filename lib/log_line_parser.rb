#!/usr/bin/env ruby

require "log_line_parser/version"
require "log_line_parser/line_parser"
require "log_line_parser/apache"
require "log_line_parser/ltsv"
require "strscan"
require "time"
require "date"

module LogLineParser
  include LineParser
  extend LineParser::Helpers

  class MalFormedRecordError < StandardError; end

  module Fields
    # LogFormat "%h %l %u %t \"%r\" %>s %b" common
    COMMON = [
      :remote_host,
      :remote_logname,
      :remote_user,
      :time,
      :first_line_of_request,
      :last_request_status,
      :response_bytes,
    ].freeze

    # LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" combined
    COMBINED = (COMMON + [:referer, :user_agent]).freeze
  end

  PREDEFINED_FORMATS = {}

  class LogLineTokenizer < Tokenizer
    setup(%w([ ] - \\ "), ['\s+']) #"
  end

  define_nodes(RootNode: [nil, nil, [" "]],
               BasicFieldNode: [nil, " ", []],
               TimeNode: ["[", "]", []],
               StringNode: ['"', '"', []])

  class StringEscapeNode < EscapeNode
    setup('\\', nil, [], ['\\', '"', 't', 'n', 'r'])
    ESCAPED = {
      '\\' => '\\',
      '"' => '"',
      't' => "\t",
      'n' => "\n",
      'r' => "\r",
    }

    def to_s
      ESCAPED[@subnodes[0]] || ''.freeze
    end
  end

  define_node_nesting(RootNode => [TimeNode, StringNode],
                      StringNode => [StringEscapeNode])

  class LogLineNodeStack < NodeStack
    setup(RootNode, BasicFieldNode)

    def to_a
      root.subnodes.map {|node| node.to_s }
    end

    def to_hash(parser=CombinedLogParser)
      parser.to_hash(to_a)
    end

    def to_record(parser=CombinedLogParser)
      parser.create(to_a)
    end
  end

  module ClassMethods
    DATE_TIME_SEP = /:/

    attr_accessor :parse_time_value, :format_strings

    def setup(field_names, format_strings=nil)
      @field_names = field_names
      @format_strings = format_strings
      @ltsv_labels = Ltsv.format_strings_to_labels(format_strings)
      @number_of_fields = field_names.length
      @referer_defined = field_names.include?(:referer)
      @parse_time_value = false
    end

    def parse(line)
      fields = LogLineParser.parse(line).to_a
      unless fields.length == @number_of_fields
        raise MalFormedRecordError, line
      end
      create(fields)
    end

    def create(log_fields)
      new(*log_fields).tap do |rec|
        rec.last_request_status = rec.last_request_status.to_i
        rec.response_bytes = response_size(rec)
        rec.time = parse_time(rec.time) if @parse_time_value
        rec.parse_request
        rec.parse_referer if @referer_defined
      end
    end

    def to_hash(line)
      values = line.kind_of?(Array) ? line : LogLineParser.parse(line).to_a
      h = {}
      @format_strings.each_with_index do |key, i|
        h[key] = values[i]
      end
      parse_request(h)
      h
    end

    def to_ltsv(line)
      values = line.kind_of?(Array) ? line : LogLineParser.parse(line).to_a
      Ltsv.to_ltsv(@ltsv_labels, values)
    end

    private

    def parse_request(h)
      if first_line_of_request = h["%r".freeze]
        request = first_line_of_request.split(/ /)
        h["%m"] ||= request.shift
        h["%H"] ||= request.pop
        h["%U%q"] ||= request.size == 1 ? request[0] : request.join(" ".freeze)
      end
    end

    def response_size(rec)
      size_str = rec.response_bytes
      size_str == "-".freeze ? 0 : size_str.to_i
    end

    def parse_time(time_str)
      Time.parse(time_str.sub(DATE_TIME_SEP, " ".freeze))
    end
  end

  module InstanceMethods
    SPACE_RE = / /
    SLASH_RE = /\//
    SLASH = '/'.freeze
    SCHEMES =%w(http: https:)

    attr_reader :method, :protocol, :resource
    attr_reader :referer_scheme, :referer_host, :referer_resource

    def date(offset=0)
      DateTime.parse((self.time + offset * 86400).to_s)
    end

    def parse_request
      request = self.first_line_of_request.split(SPACE_RE)
      @method = request.shift
      @protocol = request.pop
      @resource = request.size == 1 ? request[0] : request.join(" ".freeze)
    end

    def parse_referer
      return if self.referer == "-".freeze
      parts = self.referer.split(SLASH_RE, 4)
      if SCHEMES.include? parts[0]
        @referer_scheme = parts[0]
        @referer_host = parts[2]
        @referer_resource = parts[3] ? SLASH + parts[3] : SLASH
      else
        @referer_scheme = "".freeze
        @referer_host = "".freeze
        @referer_resource = self.referer
      end
    end

    def referred_from_host?(host_name)
      @referer_host == host_name
    end
  end

  def self.create_record_type(field_names, format_strings)
    record_type = Struct.new(*field_names)
    record_type.extend(ClassMethods)
    record_type.include(InstanceMethods)
    record_type.setup(field_names, format_strings)
    record_type
  end

  private_class_method :create_record_type

  ##
  # Creates a parser from a LogFormat.
  #
  # For example,
  #
  #    parser = LogLineParser.parser("%h %l %u %t \"%r\" %>s %b")
  #
  # creates the parser of Common Log Format.

  def self.parser(log_format)
    if log_format.kind_of? String
      format_strings = Apache.parse_log_format(log_format)
      field_names = Apache.format_strings_to_symbols(format_strings)
    else
      format_strings = nil
      field_names = log_format
    end

    create_record_type(field_names, format_strings)
  end

  def self.parse(line)
    stack = LogLineNodeStack.new
    tokens = LogLineTokenizer.tokenize(line.chomp)
    tokens.each {|token| stack.push token }
    stack
    # I'm not checking the reason yet, but the following way of pushing
    # tokens directly into the stack is very slow.
    #
    # LogLineTokenizer.tokenize(line.chomp, stack)
  end

  ##
  # Turns a line of Apache access logs into an array of field values.
  #
  # Escaped characters such as "\\t" or "\\"" will be unescaped.

  def self.to_array(line)
    parse(line).to_a
  end

  ##
  # Parser of Common Log Format (CLF)
  #
  # ref: https://www.w3.org/Daemon/User/Config/Logging.html#common-logfile-format

  CommonLogParser = parser(Apache::LogFormat::COMMON)

  ##
  # Parser of Common Log Format with Virtual Host

  CommonLogWithVHParser = parser(Apache::LogFormat::COMMON_WITH_VH)

  ##
  # Parser of NCSA extended/combined log format

  CombinedLogParser = parser(Apache::LogFormat::COMBINED)

  PREDEFINED_FORMATS['common'] = CommonLogParser
  PREDEFINED_FORMATS['common_with_vh'] = CommonLogWithVHParser
  PREDEFINED_FORMATS['combined'] = CombinedLogParser

  ##
  # Reads each line from +input+ (Apache access log files are expected) and
  # parses it, then yields the line and the parsed result (+record+) to the
  # associated block.
  #
  # When it fails to parse a line, the line will be printed to +error_output+

  def self.each_record(parser: CombinedLogParser,
                       input: ARGF,
                       error_output: STDERR) # :yields: line, record
    input.each_line do |line|
      begin
        yield line, parser.parse(line)
      rescue MalFormedRecordError => e
        error_output.print e.message
      end
    end
  end
end
