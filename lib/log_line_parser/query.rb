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

    private

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
