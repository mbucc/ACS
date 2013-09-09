// address book change preferences
// 6/16/2000 xke

sortitems = 0;  // Automatically sort items within lists? (1 or 0)

function move(fbox,tbox) {
   for(var i=0; i<fbox.options.length; i++) {
       if(fbox.options[i].selected && fbox.options[i].value != "") {
           var no = new Option();
           no.value = fbox.options[i].value;
           no.text = fbox.options[i].text;
           tbox.options[tbox.options.length] = no;
           fbox.options[i].value = "";
           fbox.options[i].text = "";
       }
   }
   BumpUp(fbox);
   if (sortitems) SortD(tbox);
}

function BumpUp(box)  {
     for(var i=0; i<box.options.length; i++) {
         if(box.options[i].value == "")  {
             for(var j=i; j<box.options.length-1; j++)  {
                 box.options[j].value = box.options[j+1].value;
                 box.options[j].text = box.options[j+1].text;
             }
             var ln = i;
             break;
         }
     }

     if(ln < box.options.length)  {
         box.options.length -= 1;
         BumpUp(box);
     }
}

function SortD(box)  {
     var temp_opts = new Array(); 
     var temp = new Object();
     for(var i=0; i<box.options.length; i++)  {
        temp_opts[i] = box.options[i];
     }
     for(var x=0; x<temp_opts.length-1; x++)  {
         for(var y=(x+1); y<temp_opts.length; y++)  {
            if(temp_opts[x].text > temp_opts[y].text)  {
               temp = temp_opts[x].text;
               temp_opts[x].text = temp_opts[y].text;
               temp_opts[y].text = temp;
            }
         }
     }
     for(var i=0; i<box.options.length; i++)  {
         box.options[i].value = temp_opts[i].value;
         box.options[i].text = temp_opts[i].text;
     }
}

function move_vertical(box, num) {
   // num is either +1 or -1
   var temp_value;
   var temp_text;
   var length = box.options.length;
   for(var i=0; i<length; i++) {
       // make sure move is within range as well
       if(box.options[i].selected && box.options[i].value != "" && i+num<length && i+num>=0) {
           // swap with next or previous
	   temp_value = box.options[i].value;
	   temp_text = box.options[i].text;
           box.options[i].value = box.options[i+num].value;
           box.options[i].text = box.options[i+num].text;
           box.options[i+num].value = temp_value;
           box.options[i+num].text = temp_text;

       }
   }

   // move the selection
   for(var i=0; i<length; i++) {
       if(box.options[i].selected && box.options[i].value != "" && i+num<length && i+num>=0) {
	      box.options[i].selected=0
              box.options[i+num].selected=1;
              // for going down, skip next selection
              if (num>0) {
	         i = i+num;
	      }
       }
   }

}

function select_all(box) {
   var length = box.options.length;
   for(var i=0; i<length; i++) {
      box.options[i].selected=1;
   }
}
