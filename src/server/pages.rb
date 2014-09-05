require 'fileutils'
require 'tmpdir'

class Pages
	attr_reader :pages
	def initialize(src)
		@src = src

		raise "#{@src} does not exist" unless File.exists?(@src)

		@max = open("|pdfinfo #{@src}", 'r'){|info|
			m = /^Pages:\s+(\d+)/.match(info.read)
			raise "not a valid pdf" unless m
			m[1].to_i
		}

		@pages = []
		@ranges = []
	end

	def parse!(rangestr)
		if rangestr == 'all'
			@ranges = [[1, @max]]
			@pages = (1..@max).to_a
			return
		elsif rangestr == 'none'
			@ranges = []
			@pages = []
		end
		rangestr.split(/,/).each {|str|
			m = /^(\d+)(?:-(\d+))?$/.match(str)
			raise "bad page range" unless m

			first = [m[1].to_i, @max].min
			last = [(m[2] || first).to_i, @max].min
			range = (first..last).to_a - @pages
			next if range.empty?

			@pages.concat(range).sort!.uniq!
			@ranges << [range.first,range.last]
		}
	end

	def write(out)
		raise "empty output" if @pages.empty?

		Dir.mktmpdir {|dir|
			@ranges.each {|range|
				pid = fork {
					exec "pdfseparate -f #{range.first} -l #{range.last} #{@src} #{dir}/p%d.pdf"
				}
				Process.waitpid pid
			}

			if @pages.size == 1
				FileUtils.mv "#{dir}/p#{@pages.first}.pdf", out
			else
				pid = fork {
					exec "pdfunite #{@pages.map {|p| "#{dir}/p#{p}.pdf"}.join(' ')} #{out}"
				}
				Process.waitpid pid
			end
		}
	end

	def to_jpeg(page)
		jpeg = open("|pdftoppm -scale-to 800 -jpeg #{@src} -f #{page} -l #{page}", 'r') {|img|
			img.read
		}
		if RUBY_VERSION < "1.9"
			jpeg
		else
			jpeg.force_encoding(::Encoding::ASCII_8BIT)
		end
	end

	def to_s
		"Ranges: #{@ranges}, Pages: #{@pages}"
	end

end


__END__

file = ARGV[0]
rangestr = ARGV[1]

pages = Pages.new(file)
pages.parse!(rangestr)

puts pages

pages.write('out.pdf')
