$(document).ready(function () {
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
});
