#!/usr/bin/env ruby

require "log_line_parser/version"
require "log_line_parser/line_parser"
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
      :size_of_response,
    ].freeze

    # LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" combined
    COMBINED = (COMMON + [:referer, :user_agent]).freeze
  end

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

  RootNode.register_subnode_classes(TimeNode, StringNode)
  StringNode.register_subnode_classes(StringEscapeNode)

  class LogLineNodeStack < NodeStack
    setup(RootNode, BasicFieldNode)

    def to_a
      root.subnodes.map {|node| node.to_s }
    end

    def to_record(record_type=CombinedLogRecord)
      record_type.create(to_a)
    end
  end

  module ClassMethods
    DATE_TIME_SEP = /:/

    attr_accessor :parse_time_value

    def setup(field_names)
      @field_names = field_names
      @number_of_fields = field_names.length
      @referer_defined = field_names.include?(:referer)
      @parse_time_value = true
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
        rec.size_of_response = response_size(rec)
        rec.time = parse_time(rec.time) if @parse_time_value
        rec.parse_request
        rec.parse_referer if @referer_defined
      end
    end

    private

    def response_size(rec)
      size_str = rec.size_of_response
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

    attr_reader :method, :protocol, :resource, :referer_host, :referer_resource

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
      return if self.referer == "-"
      parts = self.referer.split(SLASH_RE, 4)
      if SCHEMES.include? parts[0]
        @referer_host = parts.shift(3).join(SLASH).concat(SLASH)
        @referer_resource = parts.empty? ? SLASH : SLASH + parts.shift
      else
        @referer_host = "".freeze
        @referer_resource = self.referer
      end
    end
  end

  def self.create_record_type(field_names)
    record_type = Struct.new(*field_names)
    record_type.extend(ClassMethods)
    record_type.include(InstanceMethods)
    record_type.setup(field_names)
    record_type
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

  CommonLogRecord = create_record_type(Fields::COMMON)
  CombinedLogRecord = create_record_type(Fields::COMBINED)

  def self.each_record(record_type=CommonLogRecord, input=ARGF, error_output=STDERR)
    input.each_line do |line|
      begin
        yield record_type.parse(line)
      rescue MalFormedRecordError => e
        error_output.print e.message
      end
    end
  end
end
