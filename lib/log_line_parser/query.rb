#!/usr/bin/env ruby

#!/usr/bin/env ruby

module LogLineParser
  class Query
    TAIL_SLASH_RE = /\/$/
    SLASH = '/'

    def initialize(domain: nil, resources: [])
      @domain = domain
      @resources = normalize_resources(resources)
      @normalized_resources = normalize_resources(resources)
      @normalized_dirs = @normalized_resources - @resources
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