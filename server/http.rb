require 'socket'
require 'cgi'

module Http
	class Server
		def initialize(port)
			@srv = TCPServer.new('*', port)
			@resources = []
		end
		def on(path, methods = /GET/, &block)
			@resources << Path.new(path, methods, block)
		end
		def run
			@resources.sort! {|a,b| b.to_s <=> a.to_s}
			@patterns = Regexp.union(@resources.map {|p| p.pattern})
			@indexes = {}
			total = 0
			@resources.each{|p|
				@indexes[total] = p
				total += p.size + 1
			}
			while(conn = @srv.accept)
				conn.sync = true
				Thread.new(conn) {|conn|
					begin
						while true
							req = Request.new(conn)
							break unless req.parse!

							res = Response.new(conn)

							handle(req, res)
							res.send
						end
					ensure
						conn.close
					end
				}
			end
		end
		def handle(req, res)
			if m = @patterns.match(req.path)
				c = m.captures.each_with_index.select {|c,i| c}.map {|c,i| i}
				resource = @indexes[c.first]
				if(req.method == "OPTIONS")
					res['Access-Control-Allow-Methods'] = resource.list
					res['Access-Control-Allow-Headers'] = req['Access-Control-Request-Headers'].to_s
				else
					if resource.allow?(req.method)
						begin
							vars = Hash[c.drop(1).each_with_index.map {|i,j|
								[resource.vars[j].to_sym, m[i+1]]
							}]
							resource.block.call(req, res, vars)
						rescue => e
							res.status = InternalServerError
							res.text = e.to_s
						end
					else
						res.status = MethodNotAllowed
						res.text = "method #{req.method} not implemented for #{req.path}"
					end
				end
			else
				res.status = NotFound
				res.text = "no resource to match url #{req.path}"
			end

			res['Access-Control-Allow-Origin'] = '*'
		end
	end
	class Path
		attr_reader :vars, :block
		def initialize(path, methods, block)
			@vars = []
			@path = path.gsub(/{(\w+)}/) {
				 @vars << $1
				'([\w\-\.]+)'
			}.sub(/\/\*$/) {
				@vars << '*'
				'(\/.*)?'
			}.sub(/\/$/, '')
			@methods = methods
			@block = block
		end
		def pattern
			Regexp.new("(#{@path})")
		end
		def list
			@methods.source.split(/\|/).push("OPTIONS").join(", ")
		end
		def allow?(method)
			! @methods.match(method).nil?
		end
		def size
			@vars.size
		end
		def to_s
			@path
		end
	end
	class Headers
		def initialize
			@h = {}
		end
		def each(&block)
			@h.each(&block)
		end
		def [](name)
			@h[fix_case name]
		end
		def []=(name, value)
			@h[fix_case name] = value
		end
		def fix_case(name)
			name.split(/-/).map {|p| p.capitalize}.join('-')
		end
		def to_s
			@h.to_s
		end
	end
	class Request
		attr_reader :request_line, :method, :url, :path, :body, :headers
		def initialize(conn)
			@conn = conn
			@headers = Headers.new
		end
		def parse!
			@request_line = @conn.gets
			m = /(\w+)\s+(([\w\.\/]*)\??(.*))\s+HTTP\/1\.1/.match(@request_line)
			return false unless m

			@method, @url, @path, query = m[1], m[2], m[3], m[4]
			@props = Hash[query.scan(/(\w+)=([\w\s%\-+,\.\/]*)&?/).map {|k,v| [k.downcase.to_sym,CGI::unescape(v)]}] if query

			while (line = @conn.gets) != "\r\n"
				m = /([\w\-]+):\s*(.*)/.match(line)
				@headers[m[1]] = m[2]
			end
			if length = @headers['Content-Length']
				@body = @conn.read(length.to_i)
			end
			return true
		end
		def [](name)
			@headers[name]
		end
		def query?(name)
			@props[name] if @props
		end
	end
	class Response
		def initialize(conn)
			@conn = conn
			@status = OK
			@headers = Headers.new
			@headers['Content-Length'] = 0
		end
		def []=(name, value)
			@headers[name] = value
		end
		def status
			Http.constants.select {|c| Http.const_get(c) == @status}.map {|c| c.to_s}.first.scan(/[A-Z]+[a-z]*/).join(' ')
		end
		def status=(status)
			@status = status
		end
		def body=(body)
			@headers['Content-Length'] = body.size
			@body = body
		end
		def send
			@conn.send("HTTP/1.1 #{@status} #{status}\r\n", 0)
			@headers.each {|name,value|
				@conn.send("#{name}: #{value}\r\n", 0)
			}
			@conn.send("\r\n", 0)
			@conn.send(@body, 0) if @body
			@conn.flush
		end

		{
			:text => 'text/plain',
			:html => 'text/html',
			:binary => 'application/octet-stream',
			:json => 'application/json',
			:jpeg => 'image/jpeg',
			:gif => 'image/gif',
			:png => 'image/png',
		}.each {|name,mime|
			send(:define_method, "#{name}=".to_sym) {|body|
				@headers['Content-Type'] = mime
				self.body = body
			}
		}
	end
	OK = 200
	Created = 201
	Accepted = 202
	SeeOther = 303
	BadRequest = 400
	NotFound = 404
	MethodNotAllowed = 405
	InternalServerError = 500
end

