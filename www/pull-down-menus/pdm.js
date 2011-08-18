// /pull-down-menus/pdm.js
//
// by aure@arsdigita.com, February 2000
//
// menu navigation system
//
// requires standard.js
//
// $Id: pdm.js,v 1.1.2.1 2000/03/17 18:07:40 aure Exp $

var NavBar = new Array();
var menu_spacing = 0;
var cell_spacing = 0;
var cell_padding = 0;

var x_offset;
var y_offset;
var main_menu_bg_color;
var main_menu_hl_color;
var main_menu_bg_img_url;
var main_menu_hl_img_url;
var sub_menu_bg_color;
var sub_menu_hl_color;
var sub_menu_bg_img_url;
var sub_menu_hl_img_url;
var sub_sub_menu_bg_color;
var sub_sub_menu_hl_color;
var sub_sub_menu_bg_img_url;
var sub_sub_menu_hl_img_url;

var element_height, element_width;
var orientation;
var test_main_menu_bg_color = '#FFFFFF';

var last_casc1;
var last_casc2 = '';

var blank_src = '/graphics/graphing-package/transparent-dot.gif';
var blank_img = '<img src='+ blank_src + ' width=1 height=1>';

function NavBarItem(label, url, top_level_p, opened_p){
    // text of the NavBar item
    this.label = label;
    // location of the where to go on click
    this.url = url;
    // boolean describing whether this is a top level item
    this.TopLevelP = top_level_p;
    // boolean describing whether the item is opened
    this.OpenedP = opened_p;
    // create the array of cascade items for this NavBarItem
    this.cascade = new CascadeMenu();
    NavBar[NavBar.length] = this;
    return this;
}

//CascadeMenu class
//general cascade object for 1st and 2nd level cascades
//takes no arguments, contains array of cascadeitems
//has addMember method which adds cascade items to members array
function CascadeMenu(){
    this.members = new Array();
    this.addMember = AddMember;
    return this;
}

function CascadeItem(label, url, has_cascade) {
    // text of the NavBar item
    this.label = label;
    // location of the where to go on click
    this.url = url;
    // boolean of whether this item has a next level cascade
    this.has_cascade = has_cascade;
    // create the array of cascade items
    if (has_cascade){
	this.cascade = new CascadeMenu();
    }
}

//AddMember method
//adds members to CascadeMenu objects
//passes arguments to CascadeItem
function AddMember(label,url,has_cascade){
    var my_index = this.members.length;
    this.members[my_index] = new CascadeItem(label,url,has_cascade);
    return this.members[my_index];
}

// MakeNavLayers function
// writes out layers for netscape and divs for IE
function MakeNavLayers(){
    
    var mainNavBar = '';
    var main_act = '<map name="mainNavBar_map">';

    var num_opened = 0;
    var current_x_offset = 0;
    var current_y_offset = 0;
    var openbg_top = -1;
    var openbg_h = 0;

    if (orientation == 'horizontal') {
	mainNavBar += '<table border=0' + 
                      '       cellspacing=' + cell_spacing +
	              '       cellpadding=' + cell_padding +
                      '       width=' + (NavBar.length * element_width) + '>' +
                      '<tr>';
    } else {
	mainNavBar += '<table border=0' +
                      '       cellspacing=' + cell_spacing +
                      '       cellpadding=' + cell_padding +
                      '       width=' + element_width + '>';    
    }

    for(var i = 0; i < NavBar.length; i++) {
		
	if (NavBar[i].OpenedP){
	    font_decoration = '<u>';
	} else {
	    font_decoration = '';
	}

	if (orientation == 'horizontal') {
	    mainNavBar += '<td width=' + (element_width - 10) + '>' +
	                  '<font class="mainmenufont"> &nbsp; ' + 
	                  font_decoration + NavBar[i].label + 
                          '</td>';
	
	} else if (NavBar[i].TopLevelP){
	    mainNavBar += '<tr>' +
	                  '<td height=' + element_height +
	                  '    width='  + element_width  + 
	                  '    nowrap>' +
	                  '<font class="mainmenufont">&nbsp;' + 
	                  font_decoration + NavBar[i].label + 
	                  '</td></tr>';

	    if (NavBar[i].OpenedP) {
		if (num_opened > 0)
		alert("Warning: more than one open top-level nav item");
		if (num_opened == 0)
		num_opened = 1;
	    }
	} else {
	    mainNavBar += '<tr>' +
	                  '<td height=' + element_height +
	                  '    width='  + element_width  +
	                  '    nowrap>' +
	                  '<font class="mainmenufont">&nbsp;' + NavBar[i].label +
	                  '</td></tr>';
 
	    if (openbg_top == -1) openbg_top = current_y_offset;

	    openbg_h += element_height;
	}
 
	//Make the imagemap area html for this element
	main_act += MapArea(element_width,
                            element_height,
                            current_x_offset,
	                    current_y_offset,
                            NavBar[i].url,
                            'TopOver(' + i +',' + 
                                     (x_offset + current_x_offset) + ',' + 
                                     (y_offset + current_y_offset) + 
                                   ');',
	                    '');
	
	//build first level cascade for this nav item
	var sub1_id = 'casc1_' + i;
	var sub1_cont = '';
	var sub1_act = '<map name="'+ sub1_id + '_map">';
	
	//loop through this item's cascade items
	if(NavBar[i].cascade.members.length > 0){
	    sub1_cont += '<table border=0' +
                         '       cellpadding=' + cell_padding +
                         '       cellspacing=' + cell_spacing +
                         '       width=' + element_width + '>\n';

	    for (var j = 0; j < NavBar[i].cascade.members.length; j++) {
		var sub1_top = j * element_height;
		
		sub1_cont += '<tr>' +
                             '<td height=' + element_height + 
                             '    width='  + element_width  + 
		             '    nowrap>' + 
                             '<font class="submenufont">&nbsp;' + 
                             NavBar[i].cascade.members[j].label + 
                             '</font>' + 
                             '</td>' + 
                             '</tr>';
		
		//check for 2nd level cascades
		if (NavBar[i].cascade.members[j].has_cascade) {
		    var my_cascade = NavBar[i].cascade.members[j].cascade;
		    var sub2_id = 'casc2_' + i + "_" + j;
		    var sub2_cont = '';
		    var sub2_act = '<map name="'+ sub2_id + '_map">';
		    
		    //loop through this item's cascade items
		    sub2_cont += '<table border=0' + 
                                 '       cellpadding=' + cell_padding + 
                                 '       cellspacing=' + cell_spacing + 
                                 '       width=' + element_width + '>\n';

		    for (var k = 0; k < my_cascade.members.length; k++) {

			sub2_cont += '<tr>' +
			             '<td height=' + element_height +
			             '    width='  + element_width  +
			             '    nowrap>' +
			             '<font class="subsubmenufont">&nbsp;' + 
			             my_cascade.members[k].label +
			             '</font>' +
			             '</td>' +
			             '</tr>'; 

			// convenience variables
			var sub2_top = k * element_height;
			if (orientation == 'horizontal') {
			    var x1 = (x_offset + current_x_offset + element_width); 
			    var y1 = (y_offset + current_y_offset + element_height);
			} else {
			    var x1 = (x_offset + current_x_offset + 2 * element_width); 
			    var y1 = (y_offset + current_y_offset);
			}

			sub2_act += MapArea(element_width,
                                            element_height,
                                            0,
                                            sub2_top,
                                            my_cascade.members[k].url,
                                            'Cascade2Over(\'casc2_'+ k +'\',' + 
                                                          x1 + ',' + 
                                                          (y1 + sub1_top + sub2_top) +
                                                        ')',
                                            '');
		    }

		    sub2_cont += '</table>\n';

		    //write out second-level cascade
		    mkLay(sub2_id,
		          element_width,
                          element_height,
                          x1,
                          (y1 + sub1_top),
                          3,
                          false,
                          sub2_cont,
                          '',
                          '');
		    
		    sub2_act += '</map>\n' +
                                '<img src="' + blank_src + '"' + 
                                '     width=' + element_width + 
                                '     height='+ (sub2_top + element_height) +
                                '     usemap="#' + sub2_id + '_map" ' +
                                '     border=0>';

		    //write out first-level cascade activation layer
		    mkLay(sub2_id + '_act',
		          10,
		          10,
                          x1,
                          (y1 + sub1_top),
                          4,
		          false,
		          sub2_act,
		          '',
		          '');

		    //make first-level cascade bg layer
		    mkLay2(sub2_id + '_bg',
		          (element_width - menu_spacing),
		          (my_cascade.members.length * element_height),
		          x1,
                          (y1 + sub1_top),
                          1,
		          false,
		          '<body background="'+sub_sub_menu_bg_img_url+'" marginwidth=0 marginheight=0 leftmargin=0 topmargin=0>',
	                  '<div class="subsubmenu"><img width='+(element_width - menu_spacing)+' height='+(my_cascade.members.length * element_height)+' src='+blank_src+'></div>',
		          'bgcolor=' + sub_sub_menu_bg_color,
                          'background-color: ' + sub_sub_menu_bg_color + ';');
		    
		    last_casc2 = sub2_id;
		}

		if (orientation == 'horizontal') {
		    var x2 = (x_offset + current_x_offset); 
		    var y2 = (y_offset + current_y_offset + element_height);
		} else {
		    var x2 = (x_offset + current_x_offset + element_width); 
		    var y2 = (y_offset + current_y_offset);
		}

		//add to first-level cascade activation layer
		sub1_act += MapArea(element_width,
		                    element_height,
		                    0,
                                    sub1_top,
		                    NavBar[i].cascade.members[j].url,
                                    'Cascade1Over('+ j +',' + 
                                                  x2 + ',' + 
                                                  (y2 + sub1_top)  +',' + 
                                                   NavBar[i].cascade.members[j].has_cascade +',' + 
		                                   i + ')',
		                    '');
	    }
	    
	    sub1_cont += '</table>\n';
	    
	    //write out first-level cascade
	    mkLay(sub1_id,
	          element_width,
                  element_height,
	          x2,
                  y2,
	          3,
	          false,
	          sub1_cont,
	          '',
	          '');
	    
	    sub1_act += '</map>\n' + 
	                '<img src="' + blank_src + '"' + 
                        '     width=' + element_width + 
	                '     height=' + (sub1_top + element_height) +
                        '     usemap="#'+ sub1_id +'_map"' +
	                '     border=0>';

	    //write out first-level cascade activation layer
	    mkLay(sub1_id + '_act',
	          10,
	          10,
	          x2,
	          y2,
	          4,
	          false,
	          sub1_act,
	          '',
	          '');

	    //make first-level cascade bg layer
	    mkLay2(sub1_id + '_bg',
	          (element_width - menu_spacing),
                  (NavBar[i].cascade.members.length * element_height),
                  x2,
	          y2,
	          1,
	          false,
                  '<body background="'+sub_menu_bg_img_url+'" marginwidth=0 marginheight=0 leftmargin=0 topmargin=0>',
	          '<div class="submenu"><img width='+(element_width - menu_spacing)+' height='+(NavBar[i].cascade.members.length * element_height)+' src='+blank_src+'></div>',
	          'bgcolor=' + sub_menu_bg_color,
                  'background-color: ' + sub_menu_bg_color + ';');
	    
	    last_casc1 = sub1_id;
	}

	if (orientation == 'horizontal') {
	    current_x_offset += element_width;
	} else {
	    current_y_offset += element_height;
	}

    }
    
    if (orientation == 'horizontal') {
	var navbar_width = NavBar.length * element_width;
	var navbar_height = element_height;
    } else {
	var navbar_width = element_width;
	var navbar_height = current_y_offset;
    }

    mkLay2('nav_bg_off',
          navbar_width,
          navbar_height,
          x_offset,
          y_offset,
          1,
          true,
          '<body background="'+main_menu_bg_img_url+'" marginwidth=0 marginheight=0 leftmargin=0 topmargin=0>',
	  '<div class="mainmenu"><img width='+(element_width - menu_spacing)+' height='+(element_height)+' src='+blank_src+'></div>',
          'bgcolor=' + main_menu_bg_color,
          'background-color: ' + main_menu_bg_color + ';');

    //make alternate bgcolor for open items if there are any
    if (openbg_top != -1 && orientation == 'vertical') {
	mkLay('nav_openbg',
	      element_width,
	      openbg_h,
	      x_offset,
	      (y_offset + openbg_top),
	      2,
	      true,
	      blank_img,
	      'bgcolor=' + test_main_menu_bg_color,
	      'background-color: ' + test_main_menu_bg_color + ';');
    }

    // highlight main element
    mkLay2('nav_highlight',
          (element_width - menu_spacing),
          element_height,
          (x_offset - 1),
          y_offset,
          3,
          false,
          '<body background="'+main_menu_hl_img_url+'" marginwidth=0 marginheight=0 leftmargin=0 topmargin=0>',
	  '<div class="mainmenuhl"><img width='+(element_width - menu_spacing)+' height='+(element_height)+' src='+blank_src+'></div>',
          'bgcolor=' + main_menu_hl_color,
          'background-color: ' + main_menu_hl_color + ';');
    
    mainNavBar += '</tr></table>';

    //make nav layers
    mkLay('nav_layers',
          10,
          10,
          x_offset,
          (y_offset - 1),
          50,
          true,
          mainNavBar,
          '',
          '');
    
    main_act += '</map>\n' + 
                '<img src="' + blank_src + '"' +
                '     width=' + navbar_width + 
                '     height=' + navbar_height +
                '     usemap="#mainNavBar_map"' +  
                '     border=0>';

    mkLay('nav_act_' + i,
          10,
          10,
          x_offset,
          (y_offset - 1),
          51,
          true,
          main_act,
          '',
          '');
    
    //make deactivation layer
    mkLay('closer',
          0,
          0,
          0,
          0,
          0,
          false,
          '<a href="#" onmouseover="CloseAll()">' +
              '<img src="' + blank_src + '"' +
              '     width=850' + 
              '     height=800' +
              '     border=0></a>',
          '',
          '');

    if (orientation == 'horizontal') {
	var x3 = x_offset;
	var x4 = x_offset;
    } else {
	var x3 = (x_offset + element_width);
	var x4 = (x_offset + 2 * element_width);
    }

    //make first-level cascade highlight layer
    mkLay2('casc1_highlight',
          (element_width - menu_spacing),
          element_height,
	  x3,
          y_offset,
          2,
          false,
          '<body background="'+sub_menu_hl_img_url+'" marginwidth=0 marginheight=0 leftmargin=0 topmargin=0>',
	  '<div class="submenuhl"><img width='+(element_width - menu_spacing)+' height='+(element_height)+' src='+blank_src+'></div>',
          'bgcolor=' + sub_menu_hl_color,
	  'background-color: ' + sub_menu_hl_color + ';');

    //make second-level cascade highlight layer
    mkLay2('casc2_highlight',
          element_width,
          element_height,
          x4,
          y_offset,
	  2,
          false,
          '<body background="'+sub_sub_menu_hl_img_url+'" marginwidth=0 marginheight=0 leftmargin=0 topmargin=0>',
	  '<div class="subsubmenuhl"><img width='+(element_width - menu_spacing)+' height='+(element_height)+' src='+blank_src+'></div>',
          'bgcolor=' + sub_sub_menu_hl_color,
	  'background-color:' + sub_sub_menu_hl_color + ';');
}

//CloseAll
//closes all opened explore items
//called by giant mouseover layer activated by any rollover
function CloseAll(){
    visLay("nav_highlight",false);
    visLay(last_casc1, false);
    visLay(last_casc1 + '_bg', false);
    visLay(last_casc1 + '_act', false);
    visLay("casc1_highlight",false);
    //SwitchImg(last_subarrow,subarrow_off,"document.layers['nav_layers'].");
    
    if (last_casc2 != ""){
	visLay(last_casc2, false);
	visLay(last_casc2 + '_bg', false);
	visLay(last_casc2 + '_act', false);
    }
    visLay("casc2_highlight",false);
    
    visLay("closer",false);
}

//TopOver
//handles toplevel mouseovers
function TopOver(which,x,y){
    //first turn stuff off
    visLay(last_casc1, false);
    visLay(last_casc1 + '_bg', false);
    visLay(last_casc1 + '_act', false);
    visLay("casc1_highlight",false);
    if (last_casc2 != ""){
	visLay(last_casc2, false);
	visLay(last_casc2 + '_bg', false);
	visLay(last_casc2 + '_act', false);
    }
    visLay("casc2_highlight",false);
    //SwitchImg(last_subarrow,subarrow_off,"document.layers['nav_layers'].");
    
    //then turn stuff on
    LayerPos('nav_highlight',x,y);
    visLay('nav_highlight',true);
    var my_cascade = 'casc1_' + which;
    last_casc1 = my_cascade;
    
    visLay(my_cascade, true);
    visLay(my_cascade + '_bg', true);
    visLay(my_cascade + '_act', true);
    //var my_subarrow = 'subarrow_' + which;
    //last_subarrow = my_subarrow;
    //SwitchImg(my_subarrow,subarrow_on,"document.layers['nav_layers'].");
    visLay('closer',true);
}

//Cascade1Over
//1st level cascade mouseovers
function Cascade1Over(which,x,y,hasCascade,cascID){
    //first turn stuff off
    if (last_casc2 != ""){
	visLay(last_casc2, false);
	visLay(last_casc2 + '_bg', false);
	visLay(last_casc2 + '_act', false);
    }
    visLay("casc2_highlight",false);
    
    //then turn stuff on
    LayerPos("casc1_highlight",x,y);
    visLay("casc1_highlight",true);
    
    if (hasCascade){
	var my_cascade = 'casc2_' + cascID +"_" + which;
	last_casc2 = my_cascade;
	visLay(my_cascade, true);
	visLay(my_cascade + '_bg', true);
	visLay(my_cascade + '_act', true);
    }
    
    visLay('closer',true);
}

//Cascade2Over
//2nd level cascade mouseovers
function Cascade2Over(which,x,y){
    
    LayerPos("casc2_highlight",x,y);
    visLay("casc2_highlight",true);
}

//MapArea
//returns individual lines of an image map
//used to build activation layers
function MapArea(width,height,x,y,url,over,out){
    var my_map = '<area shape="rect" coords="';
    my_map += x + ',' + y + ',' + (x + width) + ',' + (y + height);
    my_map += '" href="'+ url +'" onmouseover="'+ over +'" onmouseout="'+ out +'" onclick="return '+ (url != "#") +';">\n';
    return my_map;
}

