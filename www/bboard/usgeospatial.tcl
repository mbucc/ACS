# /www/bboard/usgeospatial.tcl

ad_page_contract {
    /www/bboard/usgeospatial.tcl
    @author unknown
    @creation-date unknown
    @cvs-id usgeospatial.tcl,v 3.2.2.3 2000/09/22 01:36:58 kevin Exp
} {
    topic:trim
    topic_id:integer
} 

if {[bboard_get_topic_info] == -1} {
    return
}

set page_content "[bboard_header "Pick a Region"]

<h2>Pick a region</h2>

for the $topic forum in <a href=\"index\">Discussion Forums</a> section of
<a href=\"[ad_pvt_home]\">[ad_system_name]</a>

<hr>
<h3>Where Do You Live?</h3>
<p>
 In order to help you zero in on your community, we have organized the discussion areas 
 around <a href=\"#regions\">Ten Geographic Regions</a>. Simply click on your region below. 
 You will then be able to read current messages, respond to a message, or post a new 
 message about your state, county or any polluting company that Scorecard covers.

<p>
"

set region_text "<ul>\n"

# Construct the string to display at the bottom for "Ten Geographic Regions"
# as "region_text".
# Also set the region descriptions as region{n}_desc.

# We do this up here instead of writing everything out immediately so we only
# have to go to the database once for this information.

set last_region ""

db_foreach region "
    select epa_region, 
           usps_abbrev, 
           description 
    from   bboard_epa_regions
    order by epa_region, 
             usps_abbrev" { 
		 
    if { $epa_region != $last_region } {


	if { ![empty_string_p $last_region] } {
            append region_text ")\n"
        }
	set last_region $epa_region
        set region${epa_region}_desc $description
        set region${epa_region}_url "usgeospatial-2.tcl?[export_url_vars topic topic_id epa_region]"
	append region_text "<li><a href=\"usgeospatial-2?[export_url_vars topic_id topic epa_region]\">Region $epa_region</a>: <b>$description</b> ("
    }
    append region_text "$usps_abbrev "
}

append region_text "</ul>"

db_release_unused_handles

append page_content "
          <a name=\"us_map\"><IMG USEMAP=\"#us_map\" SRC=\"graphics/forums_map.gif\"  ALT=\"US Regions\" height=314 width=548 border=0> 
          
<map name=\"us_map\">

<!------ Region 1 ------>
<area shape=\"poly\" coords=\"501,48, 512,44, 513,43, 516,45, 516,50, 515,54, 516,59, 517,62, 518,67, 520,70, 521,72, 517,74, 515,75 511,77, 508,80, 506,81, 
505,82, 501,83, 495,86, 493,89, 491,94 490,98, 488,103, 490,106, 491,108, 487,112, 481,112, 475,112, 471,114, 470,109, 472,102, 472,95, 473,90, 473,83, 
473,75, 473,73 474,72, 478,72, 481,71, 483,69, 483,66, 481,65, 482,62, 482,60, 483,58, 484,56, 486,55, 490,53, 494,56, 496,59, 500,59\" 
href=\"$region1_url\" onMouseOver=\"window.status='Region 1: $region1_desc (CT, ME, MA, NH, RI, and VT)'; 
box.text.value='Region 1: $region1_desc (CT, ME, MA, NH, RI, and VT)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 2 ------>
<area shape=\"poly\" coords=\"466,71, 455,72, 450,79, 446,80, 442,84, 440,89, 440,92, 436,93, 427,93, 420,91, 424,96, 416,103, 416,105, 453,107, 457,
115, 456,120, 459,128, 450,134, 458,141, 465,131, 464,123, 472,123, 481,120, 467,118\"
href=\"$region2_url\" onMouseOver=\"window.status='Region 2: $region2_desc (NJ, NY, Puerto Rico, and US Virgin Islands)'; 
box.text.value='Region 2: $region2_desc (NJ, NY, Puerto Rico, and US Virgin Islands)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 3 ------>
<area shape=\"poly\" coords=\"408,109, 408,135, 398,141, 394,147, 390,153, 393,159, 397,163, 386,169, 443,170, 456,148, 443,134, 456,128, 451,115, 449,110\" 
href=\"$region3_url\" onMouseOver=\"window.status='Region 3: $region3_desc (DE, ME, PA, VA, WV, and DC)'; 
box.text.value='Region 3: $region3_desc (DE, ME, PA, VA, WV, and DC)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 4 ------>
<area shape=\"poly\" coords=\"333,167, 330,175, 319,202, 317,204, 319,220, 313,234, 328,234, 331,241, 342,240, 345,242, 361,242, 
365,250, 377,244, 390,260, 388,269, 403,299, 409,296, 412,285, 402,252, 398,237, 403,221, 409,216, 421,207, 425,201, 435,194, 
448,181, 448,173, 380,173, 390,161, 384,150, 372,144, 357,157, 344,158, 340,164\" 
href=\"$region4_url\" onMouseOver=\"window.status='Region 4: $region4_desc (AL, FL, GA, KY, MS, NC, SC, and TN)'; 
box.text.value='Region 4: $region4_desc (AL, FL, GA, KY, MS, NC, SC, and TN)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 5 ------>
<area shape=\"poly\" coords=\"262,22, 266,60, 270,89, 313,89, 316,96, 325,106, 323,111, 317,115, 317,121 312,127, 319,143, 
325,144, 322,150, 330,158, 332,165, 345,152, 358,152, 371,141, 388,146, 405,131, 406,107, 388,116, 381,109, 387,96, 385,
83, 377,85, 381,75, 380,65, 372,63, 376,57, 367,50, 350,51, 337,48, 343,40, 331,46, 320,52, 301,50, 325,35, 297,26, 289,
27, 281,19\"
href=\"$region5_url\" onMouseOver=\"window.status='Region 5: $region5_desc (IL, IN, MI, MN, OH, and WI)'; 
box.text.value='Region 5: $region5_desc (IL, IN, MI, MN, OH, and WI))'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 6 ------>
<area shape=\"poly\" coords=\"158,166, 283,166, 283,173, 324,173, 323,179, 325,179, 314,202, 314,220, 309,236, 327,236, 331,248, 332,257, 318,255, 
307,250, 287,247, 282,249, 276,261, 265,262, 256,277, 260,294, 244,285, 241,274, 229,253, 218,246, 209,253, 208,257, 194,237 
180,226, 166,227, 159,232\"
href=\"$region6_url\" onMouseOver=\"window.status='Region 6: $region6_desc (AR, LA, NM, OK, and TX)'; 
box.text.value='Region 6: $region6_desc (AR, LA, NM, OK, and TX)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 7 ------>
<area shape=\"poly\" coords=\"203,97, 202,118, 221,118, 220,165, 284,164, 286,171, 326,171, 332,169, 324,155, 317,144, 311,
133, 307,123, 313,118, 314,111, 321,105, 316,99, 312,93, 312,89, 270,90, 267,102, 261,99, 254,98, 250,95\" 
href=\"$region7_url\" onMouseOver=\"window.status='Region 7: $region7_desc (IA, KS, MO, and NE)'; 
box.text.value='Region 7: $region7_desc (IA, KS, MO, and NE)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 8 ------>
<area shape=\"poly\" coords=\"95,21, 261,21, 267,86, 263,97, 250,92, 203,93, 200,121, 218,120, 218,164, 116,165, 116,107, 
142,107, 142,73, 137,72, 126,77, 116,62, 111,62, 114,49, 102,39, 98,31\" 
href=\"$region8_url\" onMouseOver=\"window.status='Region 8: $region8_desc (CO, MT, ND, SD, UT, and WY)'; 
box.text.value='Region 8: $region8_desc (CO, MT, ND, SD, UT, and WY)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 9 ------>
<area shape=\"poly\" coords=\"113,108, 28,108, 26,126, 32,135, 31,141, 42,156, 50,176, 58,187, 60,196, 70,
198 83,205, 90,219, 110,214, 111,219, 142,232, 157,231, 157,167, 115,167\"
href=\"$region9_url\" onMouseOver=\"window.status='Region 9: $region9_desc (AZ, CA, HI, NV, GU, and AS)'; 
box.text.value='Region 9: $region9_desc (AZ, CA, HI, NV, GU, and AS)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 10 ------>
<area shape=\"poly\" coords=\"42,23, 35,44, 35,30, 22,28 29,49, 25,93, 26,107, 140,106, 139,75, 124,79, 
115,66, 109,66, 110,51, 97,39, 91,21\" 
href=\"$region10_url\" onMouseOver=\"window.status='Region 10: $region10_desc (AK, ID, OR, and WA)'; 
box.text.value='Region 10: $region10_desc (AK, ID, OR, and WA)'; return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 2 (PR)------>
<area shape=\"rect\" coords=\"435, 254, 535, 309\" href=\"$region2_url\"
onMouseOver=\"window.status='Region 2: $region2_desc (NJ, NY, Puerto Rico, and US Virgin Islands) '; box.text.value='Region 2: $region2_desc (NJ, NY, Puerto Rico, and US Virgin Islands) '; 
return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 9 ------>
<area shape=\"circle\" coords=\"342,266, 10\" href=\"$region9_url\"
onMouseOver=\"window.status='Region 9: $region9_desc (AZ, CA, HI, NV, Guam, and AS)'; box.text.value='Region 9: $region9_desc (AZ, CA, HI, NV, Guam, and AS)'; 
return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 9 ------>
<area shape=\"rect\" coords=\"343,269, 382,309\" href=\"$region9_url\"
onMouseOver=\"window.status='Region 9: $region9_desc (AZ, CA, HI, NV, Guam, and AS)'; box.text.value='Region 9: $region9_desc (AZ, CA, HI, NV, Guam, and AS)'; 
return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 9 ------>
<area shape=\"rect\" coords=\"275,269, 336,309\" href=\"$region9_url\"
onMouseOver=\"window.status='Region 9: $region9_desc (AZ, CA, HI, NV, Guam, and AS)'; box.text.value='Region 9: $region9_desc (AZ, CA, HI, NV, Guam, and AS)'; 
return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 9 ------>
<area shape=\"rect\" coords=\"111,250, 190,303\" href=\"$region9_url\"
onMouseOver=\"window.status='Region 9: $region9_desc (AZ, CA, HI, NV, Guam, and AS)'; box.text.value='Region 9: $region9_desc (AZ, CA, HI, NV, Guam, and AS)'; 
return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

<!------ Region 10 ------>
<area shape=\"rect\" coords=\"11,230, 103,303\" href=\"$region10_url\"
onMouseOver=\"window.status='Region 10: $region10_desc (AK, ID, OR, and WA)'; box.text.value='Region 10: $region10_desc (AK, ID, OR, and WA)'; 
return true\" onMouseOut=\"window.status=''; box.text.value=''; return true\">

</map>
          <br>
          
          
          <FORM NAME=box><INPUT TYPE=TEXT NAME=text size=65 value= \" \"></form>

<h3><a name=regions>Ten Geographic Regions</a></h3>
$region_text

[bboard_footer]
"
doc_return  200 text/html $page_content

