// standard.js
//
// by aure@arsdigita.com
//
// (but mostly adaptation of anonymous code found on various sites)
//
// standard.js,v 1.2 2000/06/08 21:15:23 randyb Exp

//do browser detection here
//placeholder for now; more robust testing to follow
var isNN, isIE, isMac;
var agent = navigator.userAgent;
var isMac;

if (agent.lastIndexOf('Mac')<0) isMac=false;
else isMac=true;

if (document.all){
	if (navigator.appName.indexOf("WebTV") != -1) {
		isWebTV = true;
	} else {
		isIE = true;
	}
} else if (document.layers){
	isNN = true;
	document.captureEvents(Event.MOUSEMOVE | Event.MOUSEUP | Event.RESIZE);
    window.onresize=myResizeFunction;
}

//standard handler for dealing with
//netscape's bad habits
if (isNN)
{var ws = window.innerWidth;
 var hs = window.innerHeight;}

function myResizeFunction()
{if (isNN)
 {if ((window.innerWidth != ws) || (window.innerHeight != hs))
       {window.location.href=window.location.href;}
	   }
}

//makes layers, courtesy of peterg
function mkLay(n,w,h,x,y,z,vis,cnt,exn,exe) {
	if (isNN) {
		vis == 1 ? vis='show' : vis='hide';
		document.write('<layer width='+w+' height='+h+' left='+x+' top='+y+' name="'+n+'" z-index='+z+' visibility="'+vis+'" '+exn+'>'+cnt+'</layer>');
	} else if (isIE) {
		vis == 1 ? vis='visible' : vis='hidden';
		document.write('<div id="'+n+'" style="position:absolute;width:'+w+';height:'+h+';left:'+x+';top:'+y+';z-index:'+z+';visibility:'+vis+';'+exe+'" >'+cnt+'</div>');
	}
}

//makes layers, courtesy of peterg
function mkLay2(n,w,h,x,y,z,vis,cntn,cnte, exn,exe) {
	if (isNN) {
		vis == 1 ? vis='show' : vis='hide';
		document.write('<layer width='+w+' height='+h+' left='+x+' top='+y+' name="'+n+'" z-index='+z+' visibility="'+vis+'" '+exn+'>'+cntn+'</layer>');
	} else if (isIE) {
		vis == 1 ? vis='visible' : vis='hidden';
		document.write('<div id="'+n+'" style="position:absolute;width:'+w+';height:'+h+';left:'+x+';top:'+y+';z-index:'+z+';visibility:'+vis+';'+exe+'" >'+cnte+'</div>');
	}
}


//cross-browser function to handle layer visibility
function visLay(nme,vis) {
	if (isNN) {
		vis ? vis='show' : vis='hide';
		document.layers[nme].visibility=vis;
	} else if (isIE) {
		vis ? vis='visible' : vis='hidden';
		document.all[nme].style.visibility=vis;
	}
}

//cross-browser layer positioning
function LayerPos(id,x,y){
	if (isNN){
		if (x != null) document.layers[id].left = x;
		if (y != null) document.layers[id].top = y;
	} else if(isIE){
		if (x != null) document.all[id].style.posLeft = x;
		if (y != null) document.all[id].style.posTop = y;
	}
}


function SwitchImg(which,newSrc,nnLayer){
	var layerInfo = "";
	if (isNN){
		layerInfo = nnLayer;
	}
	eval(layerInfo + "document.images['" + which + "'].src = '" + newSrc.src + "'");
}
