function preview_main()
{
	var file = get_query_string()["file"];
	if(typeof(file) != "undefined")
	{
		setup_controls(file);
		get_preview(file);
	}
}

function do_print(file)
{
	var post = new XMLHttpRequest();
	post.open("POST", server + "/print/" + make_query_string(file), true);
	post.onreadystatechange = function() {
		if(post.readyState == 4)
		{
			if(post.status == 200)
				window.close();
			else
				alert("Print failed: " + post.responseText);
		}
	};
	post.send();
}

function get_preview(file)
{
	var get = new XMLHttpRequest();
	get.open("GET", server + "/preview/document/" + make_query_string(file), true);
	get.onreadystatechange = function() {
		if(get.readyState == 4)
		{
			var resp = JSON.parse(get.responseText);
			update_content(resp.pages);
		}
	};
	get.send();
}

var refresh = function()
{
	var timer;
	return function(file) {
		window.clearTimeout(timer);
		timer = window.setTimeout(function() {
			get_preview(file);
		}, 1000);
	};
}();

function update_content(pages)
{
	var content = document.getElementById('content');
	var html = '';
	for(var i in pages)
	{
		html += '<div class="page"><img style="width:100%" src="' + server + pages[i].url + '"/></div> <div class="page_number">' + pages[i].page + '</div>\n';
	}
	content.innerHTML = html;
}

function get_query_string()
{
	var result = {};
	var q = location.search.slice(1);
	var exp = /([^&=]+)=([^&]*)/g;
	var m;
	while(m = exp.exec(q))
		result[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
	return result;
}

function make_query_string(file)
{
	var orientation = get_radio_state("orientation");
	var range = get_radio_state("range");
	if(range == "pages")
		range = document.getElementById("rangestr").value;

	return "?file=" + file + "&orientation=" + orientation + "&range=" + range;
}

function get_radio_state(name)
{
	var buttons = document.getElementsByName(name);
	for(var i in buttons)
	{
		if(buttons[i].checked)
			return buttons[i].value;
	}
	return null;
}

function setup_controls(file)
{
	// print
	var print = document.getElementById("print");
	print.onclick = function() {
		do_print(file);
	}

	// range
	var buttons = document.getElementsByName("range");
	for(var i in buttons)
	{
		buttons[i].onclick = function() {
			var rangestr = document.getElementById("rangestr");
			if(this.value == "pages")
			{
				rangestr.disabled = false;
				rangestr.select();
			}
			else
			{
				rangestr.disabled = true;
			}
			refresh(file);
		}
	}
	document.getElementById("rangestr").oninput = function() {
		refresh(file);
	}

	// orientation
	var buttons = document.getElementsByName("orientation");
	for(var i in buttons)
	{
		buttons[i].onclick = function() {
			refresh(file);
		}
	}
}
document.addEventListener('DOMContentLoaded', function() {
	preview_main();
});

