require 'fileutils'
require 'tmpdir'
require './mhtml'

class Capture
	attr_reader :out
	def initialize
		@out = "cache/#{(0..16).to_a.map{|a| rand(16).to_s(16)}.join}.pdf"
	end

	def produce(body) FileUtils.mkdir_p('cache')
		Dir.mktmpdir {|dir|
			mhtml = MHtml.new(dir)

			body.each_line {|line|
				mhtml << line
			}

			phantomjs = File.expand_path 'phantomjs-1.9.2-linux-x86_64'
			exe = File.join(phantomjs, "bin/phantomjs")
			rast = File.expand_path "rasterize.js"

			mhtml.update!
			mhtml.write

			p = fork {
				exec exe, rast, mhtml.fileurl, @out, "Letter"
			}
			pid, status = Process.waitpid2 p
		}
	end

end

