(function(data) {
	var request = function(method, url, onComplete, data) {
		var req = new XMLHttpRequest();
		req.onreadystatechange = function() {
			if(req.readyState == 4)
				onComplete(req);
		}
		req.open(method, url + "?" + escape(new Date()), true);
		req.send(data);
	}
	var onPageLoad = function(loc) {
		request("POST", server + "/capture", function(res) {
			if(res.status == 200)
			{
				file = res.getResponseHeader("X-Output-File");
				loc.replace(preview + "/?file=" + file);
			}
			else
			{
				loc.replace(preview + "/error.html");
			}
		}, data);
	}
	request("GET", preview, function(res) {
		if(res.status == 0)
		{
			alert("Print server is not running");
		}
		else
		{
			var w = window.open("", '_blank', 'height=600,toolbar=0,location=0,menubar=0,scrollbars=1');
			w.document.write(res.responseText);
			onPageLoad(w.location);
		}
	});
})

