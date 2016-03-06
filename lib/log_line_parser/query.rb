#!/usr/bin/env ruby

module LogLineParser
  class Query
    class NotAllowableMethodError < StandardError; end

    module HttpMethods
      OPTIONS = "OPTIONS"
      GET = "GET"
      HEAD = "HEAD"
      POST = "POST"
      PUT = "PUT"
      DELETE = "DELETE"
      TRACE = "TRACE"
      CONNECT = "CONNECT"
      PATCH = "PATCH"
    end

    TAIL_SLASH_RE = /\/$/
    SLASH = '/'
    DEFAULT_BOTS = %w(
Googlebot
Googlebot-Mobile
Mediapartners-Google
Bingbot
Slurp
Baiduspider
BaiduImagespider
BaiduMobaider
YetiBot
)

    ALLOWABLE_METHODS = [
      :access_by_bots?,
      :referred_from_resources?,
      :referred_from_under_resources?,
      :access_to_resources?,
      :access_to_under_resources?,
      :status_code_206?,
      :status_code_301?,
      :status_code_304?,
      :status_code_404?,
      :partial_content?,
      :moved_permanently?,
      :not_modified?,
      :not_found?,
    ]

    module ConfigFields
      HOST_NAME = "host_name"
      RESOURCES = "resources"
      MATCH = "match"
      IGNORE_MATCH = "ignore_match"
      OUTPUT_LOG_NAME = "output_log_name"
      MATCH_TYPE = "match_type" # The value should be "all" or "any".
    end

    def self.compile_bots_re(bot_names=DEFAULT_BOTS)
      bots_str = bot_names.map {|name| Regexp.escape(name) }.join("|")
      Regexp.compile(bots_str, Regexp::IGNORECASE)
    end

    DEFAULT_BOTS_RE = compile_bots_re

    def self.access_by_bots?(record, bots_re=DEFAULT_BOTS_RE)
      bots_re =~ record.user_agent
    end

    def self.referred_from?(record, resources=[])
      resources.include?(record.referer_resource)
    end

    def self.referred_from_under?(record, path)
        record.referer_resource.start_with?(path)
    end

    def self.access_to_resources?(record, resources=[])
      resources.include?(record.resource)
    end

    def self.access_to_resources_under?(record, path)
      record.resource.start_with?(path)
    end

    class << self
      def register_query_to_log(option, logs)
        query = Query.new(domain: option[ConfigFields::HOST_NAME],
                          resources: option[ConfigFields::RESOURCES])
        queries = option[ConfigFields::MATCH]
        reject_unacceptable_queries(queries)
        log = logs[option[ConfigFields::OUTPUT_LOG_NAME]]
        match_type = option[ConfigFields::MATCH_TYPE]
        ignore_match = option[ConfigFields::IGNORE_MATCH]
        reject_unacceptable_queries(ignore_match) if ignore_match
        compile_query(match_type, log, query, queries, ignore_match)
      end

      private

      def reject_unacceptable_queries(queries)
        unacceptable_queries = queries - ALLOWABLE_METHODS
        unless unacceptable_queries.empty?
          message = error_message_for_unacceptable_queries(unacceptable_queries)
          raise NotAllowableMethodError.new(message)
        end
      end

      def error_message_for_unacceptable_queries(unacceptable_queries)
        query_names = unacceptable_queries.join(", ")
        if unacceptable_queries.length == 1
          "An unacceptable query is set: #{query_names}"
        else
          "Unacceptable queries are set: #{query_names}"
        end
      end

      def log_if_all_match(log, query, queries)
        proc do |line, record|
          if queries.all? {|method| query.send(method, record) }
            log.print line
          end
        end
      end

      def log_if_any_match(log, query, queries)
        proc do |line, record|
          if queries.any? {|method| query.send(method, record) }
            log.print line
          end
        end
      end

      def log_if_all_match_but(log, query, queries, ignore_match)
        proc do |line, record|
          if queries.all? {|method| query.send(method, record) } and
              not ignore_match.any? {|method| query.send(method, record) }
            log.print line
          end
        end
      end

      def log_if_any_match_but(log, query, queries, ignore_match)
        proc do |line, record|
          if queries.any? {|method| query.send(method, record) } and
              not ignore_match.any? {|method| query.send(method, record) }
            log.print line
          end
        end
      end

      def compile_query(match_type, log, query, queries, ignore_match)
        if match_type == "all".freeze
          if ignore_match
            return log_if_all_match_but(log, query, queries, ignore_match)
          end
          log_if_all_match(log, query, queries)
        else
          if ignore_match
            return log_if_any_match_but(log, query, queries, ignore_match)
          end
          log_if_any_match(log, query, queries)
        end
      end
    end

    def initialize(domain: nil, resources: [])
      @domain = domain
      @resources = normalize_resources(resources)
      @normalized_resources = normalize_resources(resources)
      @normalized_dirs = @normalized_resources - @resources
    end

    def access_by_bots?(record, bots_re=DEFAULT_BOTS_RE)
      bots_re =~ record.user_agent
    end

    def referred_from_resources?(record)
      if_matching_domain(record) and
        @normalized_resources.include?(record.referer_resource)
    end

    def referred_from_under_resources?(record)
      referer_resource = record.referer_resource
      if_matching_domain(record) and
        @normalized_dirs.include?(referer_resource) or
        @resources.any?{|target| referer_resource.start_with?(target) }
    end

    def access_to_resources?(record)
      @normalized_resources.include?(record.resource)
    end

    def access_to_under_resources?(record)
      resource = record.resource
      @normalized_dirs.include?(resource) or
        @resources.any? {|target| resource.start_with?(target) }
    end

    def status_code_206?(record)
      record.last_request_status == 206
    end

    def status_code_301?(record)
      record.last_request_status == 301
    end

    def status_code_304?(record)
      record.last_request_status == 304
    end

    def status_code_404?(record)
      record.last_request_status == 404
    end

    alias :partial_content? :status_code_206?
    alias :moved_permanently? :status_code_301?
    alias :not_modified? :status_code_304?
    alias :not_found? :status_code_404?

    def options_method?(record)
      record.method == HttpMethods::OPTIONS
    end

    def get_method?(record)
      record.method == HttpMethods::GET
    end

    def head_method?(record)
      record.method == HttpMethods::HEAD
    end

    def post_method?(record)
      record.method == HttpMethods::POST
    end

    def put_method?(record)
      record.method == HttpMethods::PUT
    end

    def delete_method?(record)
      record.method == HttpMethods::DELETE
    end

    def trace_method?(record)
      record.method == HttpMethods::TRACE
    end

    def connect_method?(record)
      record.method == HttpMethods::CONNECT
    end

    def patch_method?(record)
      record.method == HttpMethods::PATCH
    end

    private

    def if_matching_domain(record)
      # When @domain is not set, it should be ignored.
      not @domain or @domain == record.referer_host
    end

    def normalize_resources(resources)
      [].tap do |normalized|
        resources.each do |resource|
          # record.referer_resource is expected to return '/'
          # even when the value of record.referer doesn't end
          # with a slash (e.g. 'http://www.example.org').
          # So in the normalized result, you don't have to include
          # an empty string that corresponds to the root of a given
          # domain.
          if TAIL_SLASH_RE =~ resource and SLASH != resource
            normalized.push resource.sub(TAIL_SLASH_RE, "".freeze)
          end

          normalized.push resource
        end
      end
    end
  end
end
