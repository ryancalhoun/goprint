require './pages'
require 'json'

module Preview
	class Document
		def initialize(file)
			@file = file
			@pages = Pages.new(file)
		end
		def to_json(rangestr)
			@pages.parse!(rangestr)
			JSON.generate({
				"pages" => @pages.pages.map {|p| {"page" => p, "url" => "/preview/page/#{p}/?file=#{@file}"}}
			})
		end
	end
	class Page
		def initialize(file)
			@file = file
			@pages = Pages.new(file)
		end
		def to_jpeg(page)
			@pages.to_jpeg(page)
		end
	end
end

