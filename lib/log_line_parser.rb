#!/usr/bin/env ruby

require "log_line_parser/version"
require "log_line_parser/line_parser"
require "strscan"
require "time"
require "date"

module LogLineParser
  include LineParser
  extend LineParser::Helpers

  class LogLineTokenizer < Tokenizer
    setup(%w([ ] - \\ "), ['\s+']) #"
  end

  define_nodes(RootNode: [nil, nil, [" "]],
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
    setup(RootNode)

    def to_a
      root.subnodes.map {|node| node.to_s }
    end

    def to_record
      CombinedLogRecord.create(to_a)
    end
  end

  module ClassMethods
    DATE_TIME_SEP = /:/

    attr_accessor :parse_time_value

    def create(log_fields)
      new(*log_fields).tap do |rec|
        rec.last_request_status = rec.last_request_status.to_i
        rec.size_of_response = response_size(rec)
        rec.time = parse_time(rec.time) if @parse_time_value
        rec.parse_request
        rec.parse_referer
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
    SLASH = '/'
    SCHEMES =%w(http: https:)

    attr_reader :method, :protocol, :resource, :referer_url, :referer_resource

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
        @referer_url = parts.shift(3).join(SLASH).concat(SLASH)
        @referer_resource = SLASH + parts.shift unless parts.empty?
      else
        @referer_resource = self.referer
      end
    end
  end

  # LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" combined

  CombinedLogRecord = Struct.new(:remote_host,
                                 :remote_logname,
                                 :remote_user,
                                 :time,
                                 :first_line_of_request,
                                 :last_request_status,
                                 :size_of_response,
                                 :referer,
                                 :user_agent)

  class CombinedLogRecord
    extend ClassMethods
    include InstanceMethods

    @parse_time_value = true
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
end
