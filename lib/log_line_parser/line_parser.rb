#!/usr/bin/env ruby

module LineParser
  class Tokenizer
    class << self
      attr_reader :special_token_re, :non_special_token_re

      def tokenize(str, tokens=[])
        @scanner.string = str
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
  end

  class NodeStack
    attr_reader :current_node, :root

    class << self
      attr_reader :root_node_class, :default_node_class

      def setup(root_node_class, default_node_class)
        @root_node_class = root_node_class
        @default_node_class = default_node_class
      end
    end

    def initialize
      @root = self.class.root_node_class.new
      @default_node_class = self.class.default_node_class
      @current_node = @root
    end

    def push_node(node)
      @current_node.push node
      node.node_below = @current_node
      @current_node = node
    end

    def pop
      popped = @current_node
      @current_node = @current_node.node_below
      popped.node_below = nil
      popped
    end

    def push_token(token)
      @current_node.push token
    end

    def push(token)
      if @current_node.kind_of? EscapeNode
        push_escaped_token(token)
      elsif @current_node.end_tag?(token)
        pop
      elsif subnode_class = @current_node.subnode_class(token)
        push_node(subnode_class.new)
      elsif @current_node.can_ignore?(token)
        nil
      else
        push_node(@default_node_class.new) if @current_node == @root
        push_token(token)
      end
    end

    def push_escaped_token(token)
      part_to_be_escaped = @current_node.part_to_be_escaped(token)
      remaining_part = nil
      if part_to_be_escaped
        remaining_part = @current_node.remove_escaped_part(token)
        push_token(part_to_be_escaped)
      end
      pop
      push_token(remaining_part) if remaining_part
    end
  end

  class Node
    attr_accessor :node_below

    class << self
      attr_reader :start_tag, :end_tag, :subnode_classes
      attr_reader :start_tag_to_subnode, :tokens_to_be_ignored

      def register_subnode_classes(*subnode_classes)
        @subnode_classes = subnode_classes
        subnode_classes.each do |subnode|
          @start_tag_to_subnode[subnode.start_tag] = subnode
        end
      end

      def setup(start_tag, end_tag, to_be_ignored=[])
        @start_tag_to_subnode = {}
        @tokens_to_be_ignored = []
        @start_tag = start_tag
        @end_tag = end_tag
        @tokens_to_be_ignored.concat(to_be_ignored) if to_be_ignored
      end
    end

    attr_reader :subnodes

    def initialize
      @subnodes = []
      @self_class = self.class
      @cannot_ignore = @self_class.tokens_to_be_ignored.empty?
    end

    def accept(visitor, memo=nil)
      visitor.visit(self, memo)
    end

    def to_s
      @subnodes.join
    end

    def subnode_class(token)
      @self_class.start_tag_to_subnode[token]
    end

    def end_tag?(token)
      @self_class.end_tag == token
    end

    def can_ignore?(token)
      if @cannot_ignore
        false
      else
        @self_class.tokens_to_be_ignored.include?(token)
      end
    end

    def push(token)
      @subnodes.push token
    end
  end

  class EscapeNode < Node
    class << self
      attr_reader :to_be_escaped, :to_be_escaped_re

      def setup(start_tag, end_tag, to_be_ignored=[], to_be_escaped=[])
        super(start_tag, end_tag, to_be_ignored)
        @to_be_escaped = to_be_escaped
        @to_be_escaped_re = compile_to_be_escaped_re(to_be_escaped)
      end

      def compile_to_be_escaped_re(to_be_escaped)
        re_str = to_be_escaped.map {|e| Regexp.escape(e) }.join("|")
        /\A(?:#{re_str})/
      end
    end

    def remove_escaped_part(token)
      token.sub(@self_class.to_be_escaped_re, ''.freeze)
    end

    def part_to_be_escaped(token)
      @self_class.to_be_escaped.each do |e|
        return e if token.start_with?(e)
      end
      nil
    end
  end

  module Helpers
    def define_nodes(class_name_and_setup_values)
      class_name_and_setup_values.each do |name, setup_values|
        new_node_class = const_set(name, Class.new(Node))
        new_node_class.setup(*setup_values)
      end
    end
  end
end
