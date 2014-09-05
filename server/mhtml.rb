require 'base64'
require 'cgi'
require 'fileutils'

class MHtml

	def initialize(dir)
		@parts = []
		@dir = dir
	end

	def <<(line)
		if m = /boundary="(.+)"/.match(line)
			@boundary = m[1]
		elsif @boundary
			if line.chomp == "--" + @boundary
				@parts.last.close unless @parts.empty?
				@parts << Part.new(@dir)
			elsif line.chomp == "--" + @boundary + "--"
				@parts.last.close
			else
				@parts.last << line unless @parts.empty?
			end
		end
	end

	def fileurl
		@parts.first.fileurl unless @parts.empty?
	end

	def update!
		resources = {}
		@parts.each {|part|
			resources[part.res] = part
		}

		@parts.each {|part|
			part.update!(resources) if part.complete?
		}
	end

	def write
		@parts.each {|part|
			part.write if part.complete?
		}
	end

	class Part
		attr_reader :res, :loc, :enc, :type, :content

		def initialize(dir)
			@dir = dir
		end

		def <<(line)
			if m = /Content-Transfer-Encoding: (.+)/.match(line)
				@enc = m[1].chomp
			elsif m = /Content-Location: ((?:\w+:\/\/)?\/?(.+))/.match(line)
				@res = m[1].chomp
				@loc = m[2].chomp.sub('#', '_')[0..254]
			elsif m = /Content-Type: (.+)/.match(line)
				@type = m[1].chomp
			elsif line == "\r\n" && ! @content
				if @loc !~ /\.html$/ && @type == "text/html"
					@loc.gsub(/\.html/, '')
					@loc += '.html'
				end
				@content = ""
			else
				append(line)
			end
		end

		def fileurl
			if @loc =~ /\/$/
				"file://" + File.expand_path(File.join(@dir, @loc)) + "/index.html"
			else
				m = /^([^?]+)(\?.+)?$/.match(@loc)
				"file://" + File.expand_path(File.join(@dir, m[1])) + CGI.escape(m[2].to_s)
			end
		end

		def append(line)
			return unless @content
			if @enc == 'quoted-printable' 
				@content += line.unpack('M*')[0]
			elsif @enc == 'base64'
				@content += Base64.decode64(line)
			else
				@content += line
			end
		end

		def complete?
			@closed
		end

		def close
			@closed = true
		end

		def update!(resources)
			urls = @content.scan(/(?:(?:src|href|data-url)="([^"]+)"|url\(([^)]+)\))/).flatten.compact
			urls.each {|url|
				res = resources[CGI.unescapeHTML url]
				@content.gsub!(url, res.fileurl) if res
			}
		end

		def write
			if @loc =~ /\/$/
				dir = File.join(@dir, @loc)
				file = 'index.html'
			else
				dir = File.join(@dir, File.dirname(@loc))
				file = File.basename @loc
			end
			FileUtils.mkdir_p dir
			File.open(File.join(dir, file), 'wb') {|f| f.write @content}
		end
	end

end
=begin
mhtml = MHtml.new
STDIN.each_line {|line|
	mhtml << line
}

mhtml.update!
mhtml.write
puts mhtml.fileurl
=end
