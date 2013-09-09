# /portals/manage-portal-js.tcl

ad_page_contract {
    Javascript for manage-portal.tcl
    
    @author aure@arsdigita.com
    @author dh@arsdigita.com
    @param max_page
    @param total
    @creation-date ?
    @cvs-id manage-portal-js.tcl,v 3.2.2.6 2000/09/22 01:39:01 kevin Exp
} {
    {max_page:integer,notnull}
    {total:integer,notnull}
}

set page_content "

// Key for functions:
//  down = 0: move up
//  down = 1: move down
    
function moveTable(direction,side,page) {
    selectbox = side + page;
    
    selected_index = document.theForm\[selectbox].selectedIndex;
    if (selected_index != -1) {
	oldText = document.theForm\[selectbox].options\[selected_index].text;
	oldValue = document.theForm\[selectbox].options\[selected_index].value;
    }
    if (selected_index != -1 && oldValue != \"null\") {
	if (direction == \"up\") {
	    // move table up
	    if (selected_index > 0) {
		// the table was in the interior of a page, so moving up means swapping with the table above
		document.theForm\[selectbox].options\[selected_index].text = document.theForm\[selectbox].options\[selected_index-1].text;
		document.theForm\[selectbox].options\[selected_index].value = document.theForm\[selectbox].options\[selected_index-1].value;
		document.theForm\[selectbox].options\[selected_index-1].text = oldText;
		document.theForm\[selectbox].options\[selected_index-1].value = oldValue;
		document.theForm\[selectbox].selectedIndex--;
	    } else  if (selected_index == 0 && page > 1) {
		// the table was at the top of the page already, so we now place it at the end of the previous page 
		newpage = page-1;
		newselectbox = side + newpage;

		// calculate where to move the table to (length of the current select box + 1)
		real_length = 0
		x = \"continue\"
		while ( x == \"continue\" ) {
		    if (document.theForm\[newselectbox].options\[real_length].value==\"null\") {
			x = \"stop\"
		    } else {
			real_length++;
		    }
		}

		// Moves text/value to the bottom of one page up
		document.theForm\[newselectbox].options\[real_length].text = oldText;
		document.theForm\[newselectbox].options\[real_length].value = oldValue;

		// erase the table from the original page
		document.theForm\[selectbox].options\[selected_index].text = \"\";
		document.theForm\[selectbox].options\[selected_index].value = \"null\";
		
		// move everything in the originating page shift up
		counter = 0
		while (counter < $total-1) {
		    oldText = document.theForm\[selectbox].options\[counter].text
		    oldValue = document.theForm\[selectbox].options\[counter].value
		    document.theForm\[selectbox].options\[counter].text = document.theForm\[selectbox].options\[counter+1].text;
		    document.theForm\[selectbox].options\[counter].value = document.theForm\[selectbox].options\[counter+1].value;
		    document.theForm\[selectbox].options\[counter+1].text = oldText;
		    document.theForm\[selectbox].options\[counter+1].value = oldValue;
		    counter++;
		}
		return false;
	    }
	} else if (direction == \"down\") {
	    // move table down

	    // calculate the index of the last element in the current page (needed to check for interior moves or moves to new pages)
	    real_length = 0
	    x = \"continue\"
	    while (x == \"continue\" ) {
		if (document.theForm\[selectbox].options\[real_length].value==\"null\") {
		    x = \"stop\"
		    real_length--;
		} else {
		    real_length++;
		}
	    }

	    if (selected_index < real_length) {
		// move within the page, so just swap values with the table below
		document.theForm\[selectbox].options\[selected_index].text = document.theForm\[selectbox].options\[selected_index+1].text;
		document.theForm\[selectbox].options\[selected_index].value = document.theForm\[selectbox].options\[selected_index+1].value;
		document.theForm\[selectbox].options\[selected_index+1].text = oldText;
		document.theForm\[selectbox].options\[selected_index+1].value = oldValue;
		document.theForm\[selectbox].selectedIndex++;
		
	    } else if (selected_index == real_length && page < $max_page) {
		// move table down to the next page
		newpage = page+1;
		newselectbox = side + newpage;
		
		// shuffle everyone down one (from the top) to make room for the new table which will appear at the top
		counter = document.theForm\[newselectbox].options.length-2;
		while (counter > -1) {
		    oldText = document.theForm\[newselectbox].options\[counter].text
		    oldValue = document.theForm\[newselectbox].options\[counter].value
		    document.theForm\[newselectbox].options\[counter].text = document.theForm\[newselectbox].options\[counter+1].text;
		    document.theForm\[newselectbox].options\[counter].value = document.theForm\[newselectbox].options\[counter+1].value;
		    document.theForm\[newselectbox].options\[counter+1].text = oldText;
		    document.theForm\[newselectbox].options\[counter+1].value = oldValue;
		    counter = counter - 1;
		}
		
		// move table into top place on new page
		document.theForm\[newselectbox].options\[0].text = document.theForm\[selectbox].options\[selected_index].text;
		document.theForm\[newselectbox].options\[0].value = document.theForm\[selectbox].options\[selected_index].value;

		// erase the table from the original page
		document.theForm\[selectbox].options\[selected_index].text = \"\";
		document.theForm\[selectbox].options\[selected_index].value = \"null\";
	    }
	}
    } else {
	// nothing was selected 
	alert(\"Please select a table first.\");
    }
    return false;
}  

function slide(side,page) {
    // move table from one side to the other side of the page
    selectbox = side + page;
    if (side == \"left\") {
	newselectbox = \"right\"+page;
    } else {
	newselectbox = \"left\"+page;
    }
    
    selected_index = document.theForm\[selectbox].selectedIndex;
    if (selected_index != -1) {
	oldText = document.theForm\[selectbox].options\[selected_index].text;
	oldValue = document.theForm\[selectbox].options\[selected_index].value;
    } else {
	alert(\"Please select a module first\");
	return false;
    }
    
    if ( oldValue==\"null\") {
	alert(\"Please select a module first\");
	return false;
    }
    
    real_length = 0
    x = \"continue\"
    while ( x == \"continue\" ) {
	// calculate the last entry in the destination page
	if (document.theForm\[newselectbox].options\[real_length].value==\"null\") {
	    x = \"stop\"
	} else {
	    real_length++;
	}
    }
	
    // table to the bottom of other side of page
    document.theForm\[selectbox].options\[selected_index].text = document.theForm\[newselectbox].options\[real_length].text;
    document.theForm\[selectbox].options\[selected_index].value = document.theForm\[newselectbox].options\[real_length].value;
    document.theForm\[newselectbox].options\[real_length].text = oldText;
    document.theForm\[newselectbox].options\[real_length].value = oldValue;
	
    // get the length of the originating page
    real_length = 1
    x = \"continue\"
    while ( x == \"continue\" ) {
	if (document.theForm\[selectbox].options\[real_length].value==\"null\") {
	    x = \"stop\"
	} else {
	    real_length++;
	}
    }
    // shift everything below the moved element up one in the original selectbox
    counter = selected_index
    while (counter < real_length) {
	oldText = document.theForm\[selectbox].options\[counter].text
	oldValue = document.theForm\[selectbox].options\[counter].value
	document.theForm\[selectbox].options\[counter].text = document.theForm\[selectbox].options\[counter+1].text;
	document.theForm\[selectbox].options\[counter].value = document.theForm\[selectbox].options\[counter+1].value;
	document.theForm\[selectbox].options\[counter+1].text = oldText;
	document.theForm\[selectbox].options\[counter+1].value = oldValue;
	counter++;
    }
    return false;
}

function Delete(side, page) {
    selectbox = side + page;
    selected_index = document.theForm\[selectbox].selectedIndex;

    if (selected_index != -1) {
	oldText = document.theForm\[selectbox].options\[selected_index].text;
	oldValue = document.theForm\[selectbox].options\[selected_index].value;
    } else {
	alert(\"Please select a module first\");
	return false;
    }

    if (oldValue != \"null\") {
	document.theForm\[selectbox].options\[selected_index].value=\"null\"; 
	document.theForm\[selectbox].options\[selected_index].text=\"\"; 
	
	real_length = 0
	x = \"continue\"
	while ( x == \"continue\" ) {
	    // calculate the number of ellements in the target page after the move
	    if (document.theForm\[\"new\"].options\[real_length].value==\"null\") {
		x = \"stop\"
	    } else {
		real_length++;
	    }
	}
	// Moves text/value to the bottom of the unused table box
	document.theForm\[\"new\"].options\[real_length].text = oldText;
	document.theForm\[\"new\"].options\[real_length].value = oldValue;
	
    } else {
	// nothing selected
	alert(\"Please select a module first\");
    }

    real_length = 1
    x = \"continue\"
    while ( x == \"continue\" ) {
	// calculate the number of elements in the 'from' selectbox (after the move?)
	if (document.theForm\[selectbox].options\[real_length].value==\"null\") {
	    x = \"stop\"
	} else {
	    real_length++;
	}
    }
    counter = selected_index
    // Adjusts for the blank on the old selectbox
    while (counter < real_length) {
	oldText = document.theForm\[selectbox].options\[counter].text
	oldValue = document.theForm\[selectbox].options\[counter].value
	document.theForm\[selectbox].options\[counter].text = document.theForm\[selectbox].options\[counter+1].text;
	document.theForm\[selectbox].options\[counter].value = document.theForm\[selectbox].options\[counter+1].value;
	document.theForm\[selectbox].options\[counter+1].text = oldText;
	document.theForm\[selectbox].options\[counter+1].value = oldValue;
	counter++;
    }
    return false;
}

function addTable(side, page) {
    selectbox = side + page;
    selected_index = document.theForm\[\"new\"].selectedIndex;
    if (selected_index != -1) {
	oldText = document.theForm\[\"new\"].options\[selected_index].text;
	oldValue = document.theForm\[\"new\"].options\[selected_index].value;
    } else {
	alert(\"Please select a module first\");
	return false;
    }

    if (oldValue != \"null\") {
	 	
	real_length = 0
	x = \"continue\"
	while ( x == \"continue\" ) {
	    // calculate the number of ellements in the target page after the move
	    if (document.theForm\[selectbox].options\[real_length].value==\"null\") {
		x = \"stop\"
	    } else {
		real_length++;
	    }
	}
	// Moves text/value to the bottom
	document.theForm\[selectbox].options\[real_length].text = oldText;
	document.theForm\[selectbox].options\[real_length].value = oldValue;
	
    } else {
	// nothing selected
	alert(\"Please select a module first\");
    }

    real_length = 1
    x = \"continue\"
    while ( x == \"continue\" ) {
	// calculate the number of elements in the 'from' selectbox 
	if (document.theForm\[\"new\"].options\[real_length].value==\"null\") {
	    x = \"stop\"
	} else {
	    real_length++;
	}
    }

    // erase the table from the original page
    document.theForm\[\"new\"].options\[selected_index].text = \"\";
    document.theForm\[\"new\"].options\[selected_index].value = \"null\";

    counter = selected_index;
    // Adjusts for the blank on the old selectbox
    while (counter < real_length) {
	oldText = document.theForm\[\"new\"].options\[counter].text
	oldValue = document.theForm\[\"new\"].options\[counter].value
	document.theForm\[\"new\"].options\[counter].text = document.theForm\[\"new\"].options\[counter+1].text;
	document.theForm\[\"new\"].options\[counter].value = document.theForm\[\"new\"].options\[counter+1].value;
	document.theForm\[\"new\"].options\[counter+1].text = oldText;
	document.theForm\[\"new\"].options\[counter+1].value = oldValue;
	counter++;
    }
    return false;
}

function doSub() {
    // Loads the string of elements on a page into hidden variables .left and  .right
    // These are used on the latter page for the update.
"
    set page_temp 1
while {$page_temp <= $max_page} {
	append page_content "
    document.theForm\[\"left\"].value += '{'+doSubSide(\"left$page_temp\")+'} ';
    document.theForm\[\"right\"].value += '{'+doSubSide(\"right$page_temp\")+'} ' ;
    document.theForm\[\"hiddennames\"].value += '{'+document.theForm.page_name$page_temp.value+'} '"    
	incr page_temp
    }
append page_content "
    return true;
}

function doSubSide(side) {
    val = \"\";
    for (i=0;i<document.theForm\[side].length;i++) {
	newval = document.theForm\[side].options\[i].value;
	if (newval != \"null\") {
	    if (i!=0) { val += \" \"; }   
	    val += newval
	}
    } 
    return val;
}

function spawnWindow(action, side,page) {

    // This function edits a module
    if (page > 0) {
	selectbox = side + page;
    } else {
	selectbox = 'new';
    }
    selected_index = document.theForm\[selectbox].selectedIndex;

    if (selected_index != -1) {
	oldText = document.theForm\[\"new\"].options\[selected_index].text;
	oldValue = document.theForm\[\"new\"].options\[selected_index].value;
    } else {
	alert(\"Please select a module first\");
	return false;
    }

    Value = document.theForm\[selectbox].options\[selected_index].value;

    if (Value != \"null\") {
	file = action+'-table.tcl?[export_url_vars group_id]&table_id='+Value
	window.open(file,'TableEditor','toolbar=no,location=no,directories=no,status=no,scrollbars=yes,resizable=yes,copyhistory=no,width=640,height=480')
	return false;
    } else {
	alert(\"Please select a module first\");
	return false;
    }
}

"

doc_return  200 text/html $page_content
