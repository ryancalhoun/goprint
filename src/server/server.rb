PRINT_CMD = "lp -dhp"

require './http'
require './capture'
require './pages'
require './preview'

srv = Http::Server.new(8080)
srv.on('/capture', /POST/) {|req,res|
	cap = Capture.new
	cap.produce(req.body)
	res['X-Output-File'] = cap.out
}
srv.on("/print", /POST/) {|req,res|
	file = req.query?(:file)
	rangestr = req.query?(:range) || "all"

	unless file
		res.status = Http::BadRequest
		res.text = "missing parameter 'file'"
		next
	end
	unless File.exists?(file)
		res.status = Http::NotFound
		res.text = "file does not exist in cache"
		next
	end

	out = file
	if rangestr != "all"
		p = Pages.new(file)
		p.parse!(rangestr)
		out = file + "out.pdf"
		p.write(out)
	end

	pid = fork {
		exec "#{PRINT_CMD} #{out}"
	}
	Process.waitpid pid
	FileUtils.rm file
	FileUtils.rm out if out != file
}
srv.on('/preview/document') {|req,res|
	file = req.query?(:file)
	rangestr = req.query?(:range) || "all"

	unless file
		res.status = Http::BadRequest
		res.text = "missing parameter 'file'"
		next
	end
	unless File.exists?(file)
		res.status = Http::NotFound
		res.text = "file does not exist in cache"
		next
	end

	p = Preview::Document.new(file)
	res.json = p.to_json(rangestr)
}
srv.on('/preview/page/{page}') {|req,res,vars|
	file = req.query?(:file)

	unless file
		res.status = Http::BadRequest
		res.text = "missing parameter 'file'"
		next
	end

	p = Preview::Page.new(file)
	res.jpeg = p.to_jpeg(vars[:page])
}

srv.run
