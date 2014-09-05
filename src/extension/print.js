var preview = "http://print.home/preview";

chrome.contextMenus.create({"title": "Print page", "contexts": ["page"], "onclick": function(info, tab) {
	chrome.pageCapture.saveAsMHTML({tabId: tab.id}, function(data) {
		var script = new XMLHttpRequest();
		script.onreadystatechange = function() {
			if(script.readyState == 4)
			{
				var fn = eval(script.responseText);
				fn(data);
			}
		}
		script.open("GET", preview + "/open.js?" + escape(new Date()), true);
		script.send();
	});
}});
