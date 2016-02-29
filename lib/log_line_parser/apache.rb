#!/usr/bin/env ruby

module LogLineParser
  module Apache
=begin
All of the format strings listed in http://httpd.apache.org/docs/current/mod/mod_log_config.html#formats:
%% %a %{c}a %A %B %b %{VARNAME}C %D %{VARNAME}e %f %h %H %{VARNAME}i %k %l %L %m %{VARNAME}n %{VARNAME}o %p %{format}p %P %{format}P %q %r %R %s %t %{format}t %T %{UNIT}T %u %U %v %V %X %I %O %S %{VARNAME}^ti %{VARNAME}^to

As explained in http://httpd.apache.org/docs/current/logs.html:
"%r" = "%m %U%q %H"
=end

    module LogFormat
      COMMON = "%h %l %u %t \"%r\" %>s %b"
      COMMON_WITH_VH = "%v %h %l %u %t \"%r\" %>s %b"
      COMBINED = "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\""
    end

    FORMAT_STRING_SYMBOLE_TABLE = {
      "%%" => :percent,
      "%a" => :remote_ip,
      "%{c}a" => :underlying_peer_ip,
      "%A" => :local_ip,
      "%B" => :response_bytes,
      "%b" => :response_bytes,
      # "%{VARNAME}C" => :cookie,
      "%D" => :time_taken_us,
      # "%{VARNAME}e" => :,
      "%f" => :filename,
      "%h" => :remote_host,
      "%H" => :protocol,
      # "%{VARNAME}i" => :,
      "%{Referer}i" => :referer,
      "%{User-agent}i" => :user_agent,
      "%{X-Forwarded-For}i" => :x_forwarded_for,
      "%k" => :keepalive_number,
      "%l" => :remote_logname,
      "%L" => :error_log_request_id,
      "%m" => :method,
      # "%{VARNAME}n" => :,
      # "%{VARNAME}o" => :,
      "%p" => :server_port,
      # "%{format}p" => :,
      "%P" => :pid,
      # "%{format}P" => :,
      "%q" => :query_string,
      "%r" => :first_line_of_request,
      # "%R" => :handler,
      "%s" => :original_request_status,
      "%>s" => :last_request_status, # final status
      "%t" => :time, # Time the request was received
      # "%{format}t" => :,
      "%T" => :time_taken_s,
      # "%{UNIT}T" => :,
      "%u" => :remote_user,
      "%U" => :url_path,
      "%U%q" => :resource,
      "%v" => :virtual_host,
      "%V" => :server_name2,
      "%X" => :connection_status,
      "%I" => :received_bytes_including_headers,
      "%O" => :sent_bytes_including_headers,
      "%S" => :bytes_transferred,
      # "%{VARNAME}^ti" => :,
      # "%{VARNAME}^to" => :,
    }

    def self.parse_log_format(log_format)
      log_format.split(/ /).map do |string|
        string.sub(/^"/, "".freeze).sub(/"$/, "".freeze)
      end
    end

    def self.format_strings_to_symbols(format_strings)
      format_strings.map {|string| FORMAT_STRING_SYMBOLE_TABLE[string] }
    end
  end
end
