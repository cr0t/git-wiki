$(document).ready(function () {
	$("#contents_spacer").css("float", "right");
	$("#contents_spacer").css("width", 200);
	$("#contents_spacer").css("height", 36);
	
	$("#contents_container").css("position", "relative");
	$("#contents_container").css("width", 950);
	$("#contents_container").css("margin", "0 auto");
	
	$("#contents").css("width", 200);
	$("#contents").css("min-height", 36);
	//$("#contents").css("text-align", "right");
	$("#contents").css("position", "absolute");
	$("#contents").css("border", "2px solid #fff");
	$("#contents").css("left", 750);
	$("#contents").css("overflow", "auto");
	
	$("#contents_toggler").click(function (e) {
		e.preventDefault();
		$("#contents_data").toggle();
		$("#contents").css("background-color", "rgba(255, 255, 255, 0.8)");
	});
});
