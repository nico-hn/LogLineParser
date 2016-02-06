#!/usr/bin/env ruby

require "log_line_parser/version"
require "strscan"

module LogLineParser
  class Tokenizer

    class << self
      attr_reader :special_token_re, :non_special_token_re

      def tokenize(str)
        @scanner.string = str
        tokens = []
        token = true # to start looping, you should assign a truthy value
        while token
          tokens.push token if token = scan_token
        end

        tokens.push @scanner.rest unless @scanner.eos?
        tokens
      end

      def setup(special_tokens, unescaped_special_tokens=[])
        @special_tokens = special_tokens
        @unescaped_special_tokens = unescaped_special_tokens
        @scanner = StringScanner.new("".freeze)
        @special_token_re, @non_special_token_re = compose_re(@special_tokens)
      end

      private

      def scan_token
        @scanner.scan(@special_token_re) ||
          @scanner.scan_until(@non_special_token_re)
      end

      def compose_special_tokens_str(special_tokens)
        sorted = special_tokens.sort {|x, y| y.length <=> x.length }
        escaped = sorted.map {|token| Regexp.escape(token) }
        escaped.concat @unescaped_special_tokens if @unescaped_special_tokens
        escaped.join('|')
      end

      def compose_re(special_tokens)
        tokens_str = compose_special_tokens_str(special_tokens)
        return Regexp.compile(tokens_str), Regexp.compile("(?=#{tokens_str})")
      end
    end

    setup(%w([ ] - \\ "), ['\s+']) #"
  end

  class NodeStack
    attr_reader :current_node

    def initialize
      @stack = []
    end

    def push(node)
      @current_node = node
      @stack.push node
    end

    def pop
      popped = @stack.pop
      @current_node = @stack[-1]
      popped
    end

    def push_token(token)
      @current_node.push token
    end

    def root
      @stack[0]
    end
  end

  class Node
    @start_tag_to_subnode = {}
    @tokens_to_be_ignored = []

    class << self
      attr_reader :start_tag, :end_tag, :subnode_classes

      def register_subnode_classes(*subnode_classes)
        @subnode_classes = subnode_classes
        subnode_classes.each do |subnode|
          @start_tag_to_subnode[subnode.start_tag] = subnode
        end
      end

      def setup(start_tag, end_tag, to_be_ignored=[], *subnode_classes)
        @start_tag = start_tag
        @end_tag = end_tag
        @tokens_to_be_ignored.concat(to_be_ignored) if to_be_ignored
        register_subnode_classes(*subnode_classes)
      end
    end

    def initialize
      @subnodes = []
    end

    def to_s
      @subnodes.join
    end

    def subnode_class(token)
      self.class.start_tag_to_subnode[token]
    end

    def end_tag?(token)
      self.class.end_tag == token
    end

    def can_ignore?(token)
      @tokens_to_be_ignored.include?(token)
    end

    def push(token)
      @subnodes.push token
    end
  end
end
