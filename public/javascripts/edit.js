$(document).ready(function()	{
	$('#markdown').markItUp(mySettings);
	
	var pathname = window.location.pathname;
	var current_sitepath = pathname.substring(0, pathname.indexOf("edit") - 1);
	
	var uploader = new qq.FileUploader({
		element           : document.getElementById("file-uploader"),
		action            : "/upload",
		allowedExtensions : [ "png", "jpg", "jpeg", "gif" ],
		params            : { sitepath : current_sitepath },
		debug             : true,
		onComplete        : function(id, file_name, response_json) {
			if (response_json.success == true) {
				LOCAL_IMAGES.push("file_name");
			}
		}
	});
	
	if (LOCAL_IMAGES.length > 0) {
		for (i = 0; i < LOCAL_IMAGES.length; i++) {
			var element = '<li class="qq-upload-success"><span class="qq-upload-file">' + LOCAL_IMAGES[i] + '</span></li>';
			$(".qq-upload-list").append(element);
		}
	}
	
	$(".qq-upload-file").live("click", function () {
		$('#markdown').insertAtCaret('![](' + current_sitepath + '/' + $(this).html() + ' "")');
	});
});

var mySettings = {
	previewParserPath: '/preview',
	onShiftEnter: { keepDefault: false, openWith: '\n\n' },
	markupSet: [
		{ name: 'First Level Heading', key: '1', placeHolder: 'Your title here...', closeWith: function(markItUp) { return miu.markdownTitle(markItUp, '='); } },
		{ name: 'Second Level Heading', key: '2', placeHolder: 'Your title here...', closeWith: function(markItUp) { return miu.markdownTitle(markItUp, '-'); } },
		{ name: 'Heading 3', key: '3', openWith: '### ', placeHolder: 'Your title here...' },
		{ name: 'Heading 4', key: '4', openWith: '#### ', placeHolder: 'Your title here...' },
		{ name: 'Heading 5', key: '5', openWith: '##### ', placeHolder: 'Your title here...' },
		{ name: 'Heading 6', key: '6', openWith: '###### ', placeHolder: 'Your title here...' },
		{ separator: '---------------' },		
		{ name: 'Bold', key: 'B', openWith: '**', closeWith: '**'},
		{ name: 'Italic', key: 'I', openWith: '_', closeWith: '_'},
		{ separator: '---------------' },
		{ name: 'Bulleted List', openWith: '- ' },
		{ name: 'Numeric List', openWith: function(markItUp) { return markItUp.line + '. '; } },
		{ separator: '---------------' },
		{ name: 'Picture', key: 'P', replaceWith: '![[![Alternative text]!]]([![Url:!:http://]!] "[![Title]!]")'},
		{ name: 'Link', key: 'L', openWith: '[', closeWith: ']([![Url:!:http://]!] "[![Title]!]")', placeHolder: 'Your text to link here...' },
		{ separator: '---------------'},	
		{ name: 'Quotes', openWith: '> '},
		{ name: 'Code Block / Code', openWith: '(!(\t|!|`)!)', closeWith: '(!(`)!)'},
		{ separator: '---------------'},
		{ name: 'Preview', call: 'preview', className: 'preview' }
	]
}

// mIu nameSpace to avoid conflict.
var miu = {
	markdownTitle: function(markItUp, char) {
		heading = '';
		n = $.trim(markItUp.selection || markItUp.placeHolder).length;
		for (i = 0; i < n; i++) {
			heading += char;
		}
		return '\n'+heading;
	}
}

jQuery.fn.extend({
	insertAtCaret: function(myValue) {
		return this.each(function(i) {
			if (document.selection) {
				this.focus();
				sel = document.selection.createRange();
				sel.text = myValue;
				this.focus();
			}
			else if (this.selectionStart || this.selectionStart == '0') {
				var startPos = this.selectionStart;
				var endPos = this.selectionEnd;
				var scrollTop = this.scrollTop;
				this.value = this.value.substring(0, startPos) + myValue+this.value.substring(endPos,this.value.length);
				this.focus();
				this.selectionStart = startPos + myValue.length;
				this.selectionEnd = startPos + myValue.length;
				this.scrollTop = scrollTop;
			}
			else {
				this.value += myValue;
				this.focus();
			}
		})
	}
});
