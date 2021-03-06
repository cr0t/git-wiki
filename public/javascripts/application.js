$(document).ready(function () {
	$("#contents a:first").css("color", "#ccc");
	$("#contents").css("background-color", "rgba(255, 255, 255, 0.9)");

	$("#contents_toggler").click(function (e) {
		e.preventDefault();

		$("#contents_data").toggle();
		$("#contents").css("background-color", "rgba(255, 255, 255, 0.9)");

		if ($("#contents_data").css("display") == "block") {
			$("#contents a:first").css("color", "#ccc");
		}
		else {
			$("#contents a:first").css("color", "#06C");
		}
	});

	$(".delete_link").click(function (e) {
		e.preventDefault();
		if (confirm("Are you sure? Also, the non-leaf-pages or pages with uploaded files/images will not be deleted, ask developer.")) {
			window.location = $(this).attr("href");
		}
	});

	$("#create_new_page").click(function (e) {
		e.preventDefault();

		var example_path = window.location.pathname.replace("/edit", "");

		var site_path = prompt("Please, input the new page site path (short name), it will be available at: " + example_path + "/", "");

		if (!site_path.match(/[0-9a-zA-Z-]+/gi)) {
			alert("The page site path must have only ASCII and alphanumeric symbols.");
		}
		else {
			if (site_path != null && site_path != "") {
				site_path = site_path.replace(/[ \.!@#$%^&*\(\)]+/g, "_");
				window.location = example_path + "/" + site_path;
			}
		}
	});

	if (getCookie("font_size") !== null) {
		$("#content").css("font-size", getCookie("font_size") + "px");
	}

	if (getCookie("line_height") !== null) {
		$("#content").css("line-height", getCookie("line_height") + "px");
	}

	if (getCookie("p_margin") !== null) {
		$("#content p").css("margin-bottom", getCookie("p_margin") + "px");
	}

	$("#font_plus, #font_minus").click(function (e) {
		e.preventDefault();

		var font_size       = parseInt($("#content").css("font-size"));
		var line_height     = parseInt($("#content").css("line-height"));
		var p_margin        = parseInt($("#content p").css("margin-bottom"));

		var new_font_size   = (font_size - 2);
		var new_line_height = (line_height - 2);
		var new_p_margin    = (p_margin - 12);

		if ($(this).attr("id") == "font_plus") {
			new_font_size   = (font_size + 2);
			new_line_height = (line_height + 2);
			new_p_margin    = (p_margin + 12);
		}

		if (new_p_margin < 0) {
			new_p_margin = 0;
		}

		setCookie("font_size", new_font_size);
		setCookie("line_height", new_line_height);
		setCookie("p_margin", new_p_margin);

		$("#content").css("font-size", new_font_size + "px");
		$("#content").css("line-height", new_line_height + "px");
		$("#content p").css("margin-bottom", new_p_margin + "px");
	});

	if (getCookie("show_results_details") !== null && getCookie("show_results_details") === "block") {
		$("pre").show();
	}

	$("#toggle_results_details").click(function (e) {
		e.preventDefault();
		$("pre").toggle();
		setCookie("show_results_details", $("pre").css("display"));
	});
});

function setCookie (name, value, expires, path, domain, secure) {
	var today = new Date();
	today.setTime( today.getTime() );

	if (expires) {
		expires = expires * 1000 * 60 * 60 * 24;
	}

	var expires_date = new Date(today.getTime() + (expires));
	document.cookie = name + '=' + escape(value) +
		((expires) ? ';expires=' + expires_date.toGMTString() : '') +
		((path) ? ';path=' + path : '') +
		((domain) ? ';domain=' + domain : '') +
		((secure) ? ';secure' : '');
}

function getCookie (name) {
	var start = document.cookie.indexOf(name + "=");
	var len   = start + name.length + 1;

	if ((!start) && (name != document.cookie.substring(0, name.length))) {
		return null;
	}

	if (start == -1) {
		return null;
	}

	var end = document.cookie.indexOf(';', len);
	if (end == -1) {
		end = document.cookie.length;
	}

	return unescape(document.cookie.substring(len, end));
}
