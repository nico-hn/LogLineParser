#!/usr/bin/env ruby

require 'log_line_parser/bots'

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
      :options_method?,
      :get_method?,
      :head_method?,
      :post_method?,
      :put_method?,
      :delete_method?,
      :trace_method?,
      :connect_method?,
      :patch_method?,
    ]

    module ConfigFields
      HOST_NAME = "host_name"
      RESOURCES = "resources"
      MATCH = "match"
      IGNORE_MATCH = "ignore_match"
      OUTPUT_LOG_NAME = "output_log_name"
      MATCH_TYPE = "match_type" # The value should be "all" or "any".
    end

    def self.access_by_bots?(record, bots_re=Bots::DEFAULT_RE)
      bots_re =~ record.user_agent
    end

    ##
    # Returns true if the path+query part of the value of %{Referer}i
    # matchs one of resources.

    def self.referred_from_resources?(record, resources=[])
      resources.include?(record.referer_resource)
    end

    def self.referred_from_under?(record, path)
        record.referer_resource.start_with?(path)
    end

    def self.access_to_resources?(record, resources=[])
      resources.include?(record.resource)
    end

    def self.access_to_under?(record, path)
      record.resource.start_with?(path)
    end

    def self.referred_from_host?(record, host_name)
      record.referer_host == host_name
    end

    class << self
      def register_query_to_log(option, logs, bots_re=Bots::DEFAULT_RE)
        query = Query.new(domain: option[ConfigFields::HOST_NAME],
                          resources: option[ConfigFields::RESOURCES],
                          bots_re: bots_re)
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

    def initialize(domain: nil, resources: [], bots_re: Bots::DEFAULT_RE)
      @domain = domain
      @resources = normalize_resources(resources)
      @bots_re = bots_re
      @normalized_resources = normalize_resources(resources)
      @normalized_dirs = @normalized_resources - @resources
    end

    def access_by_bots?(record)
      @bots_re =~ record.user_agent
    end

    ##
    # Returns true if the path+query part of the value of %{Referer}i
    # matches one of the resources that are passed as the second
    # argument when you create an instance of Query.
    #
    # When a given resource is a directory, you should append a "/" at the
    # end of it, otherwise you would get a wrong result. For example,
    # suppose you define the following queries:
    #
    #    correct_query = Query.new("www.example.org", ["/dir/subdir/"])
    #    wrong_query = Query.new("www.example.org", ["/dir/subdir"])
    #
    # <tt>correct_query.referred_from_resources?(record)</tt> returns true
    # when the value of %{Referer}i is "http://www.example.org/subdir"
    # or "http://www.example.org/subdir/",
    # but <tt>wrong_query.referred_from_resources?(record)</tt> returns
    # false for "http://www.example.org/subdir/"

    def referred_from_resources?(record)
      if_matching_domain(record) and
        @normalized_resources.include?(record.referer_resource)
    end

    ##
    # Returns true if the path+query part of the value of %{Referer}i
    # begins with one of the resources that are passed as the second
    # argument when you create an instance of Query.
    #
    # When a given resource is a directory, you should append a "/" at the
    # end of it, otherwise you would get a wrong result. For example,
    # suppose you define the following queries:
    #
    #    correct_query = Query.new("www.example.org", ["/dir/subdir/"])
    #    wrong_query = Query.new("www.example.org", ["/dir/subdir"])
    #
    # <tt>wrong_query.referred_from_under_resources?(record)</tt>
    # returns true even when the value of %{Referer}i in record is
    # "http://www.example.org/subdir_for_images/a_file_name",
    # while <tt>correct_query.referred_from_under_resources?(record)</tt>
    # returns true when the value of %{Referer}i is
    # "http://www.example.org/subdir/a_filename" or
    # "http://www.example.org/subdir",
    # and returns false for "http://www.example.org/subdir_for_images".

    def referred_from_under_resources?(record)
      referer_resource = record.referer_resource
      if_matching_domain(record) and
        @normalized_dirs.include?(referer_resource) or
        @resources.any?{|target| referer_resource.start_with?(target) }
    end

    ##
    # Returns true if the value of %U%q in +record+ matches one of the
    # resources that are passed as the second argument when you create
    # an instance of Query.
    #
    # When you give a directory as one of resources, you should append
    # a "/" at the end of the directory, otherwise records whose %U%q
    # value points to the same directory but without trailing "/"
    # will return false.
    #
    # For example, when you create queries as follows,
    #
    #    query_with_slash = Query.new("www.example.org", ["/dir/subdir/"])
    #    query_without_slash = Query.new("www.example.org", ["/dir/subdir"])
    #
    # <tt>query_with_slash.access_to_resources?(record)</tt> returns true for
    # both of records whose %U%q value is "/dir/subdir/" and "/dir/subdir"
    # respectively.
    #
    # But <tt>query_without_slash.access_to_resources?(record)</tt> returns
    # false for a record whose %U%q value is "/dir/subdir/"

    def access_to_resources?(record)
      @normalized_resources.include?(record.resource)
    end

    ##
    # Returns true if the value of %U%q in +record+ begins with one
    # of the resources that are passed as the second argument when
    # you create an instance of Query.
    #
    # When a given resource is a directory, you should append a "/" at the
    # end of it, otherwise you would get a wrong result. For example,
    # suppose you define the following queries:
    #
    #    correct_query = Query.new("www.example.org", ["/dir/subdir/"])
    #    wrong_query = Query.new("www.example.org", ["/dir/subdir"])
    #
    # <tt>wrong_query.access_to_under_resources?(record)</tt>
    # returns true even when the value of %U%q in record is
    # "/subdir_for_images/a_file_name", while
    # <tt>correct_query.access_to_under_resources?(record)</tt>
    # returns true when the value of %U%q is "/subdir/a_filename" or
    # "/subdir", and returns false for "/subdir_for_images".

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
