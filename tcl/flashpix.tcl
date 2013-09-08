ad_library {
    
    @author probably philg
    @creation-date ?
    @cvs-id  flashpix.tcl,v 3.2.2.1 2000/07/25 11:27:49 ron Exp

}

proc philg_img_target {conn url_stub fpx_filename jpeg_front width height copyright_text caption tech_details tutorial_info} {
    set referer [ns_set get [ns_conn headers $conn] Referer]
    # we allow user to set a bunch of preferences
    set cookie [ns_set get [ns_conn headers $conn] Cookie]
    set complete_backlink ""
    if { $referer != "" } {
	set complete_backlink "<br><br>Return to what you were reading by using your browser's Back button.  Or you can try <a href=\"$referer\">clicking here to go back</a>"
    }
    if { $caption == "" } {
	set caption $jpeg_front
    }
    if { $copyright_text == "" } {
	set complete_copyright "<br><br>Any photograph is copyrighted when created.  You should find the photographer and get permission to use this image."
    } else {
	set complete_copyright "<br><br><a href=\"/philg/nasty-copyright-notice\">$copyright_text</a>"
    }
    set complete_tech_details ""
    if { $tech_details != "" } {
	set complete_tech_details "<BR><BR><i>$tech_details</i>\n"
    }
    if { [string first "thumbnail_preference=4base_jpeg" $cookie] != -1 } {
	# user has requested the huge JPEGs
	set result "<html>
<head>
<title>$jpeg_front</title>
</head>

<body bgcolor=#ffffff text=#000000>

<center>

$caption
$complete_tech_details

<br>
<br>

<img src=\"${url_stub}${jpeg_front}.4.jpg\">

<br>
<br>
Available as <a href=\"${url_stub}${jpeg_front}.3.jpg\">a 500x750 pixel JPEG</a> or 
<a href=\"/photo/show-a-flashpix?url_stub=[ns_urlencode $url_stub]&fpx_filename=[ns_urlencode $fpx_filename]&width=$width&height=$height&jpeg_front=[ns_urlencode $jpeg_front]\">a FlashPix</a>

$complete_backlink
$complete_copyright

<br>
<br>

Note: This browser has been customized to request huge JPEGs by default.  If you want to change the
default image size or format that you get after clicking on a
thumbnail, then <a href=\"/photo/personalize-thumbnail-targets\">just tell us what you'd prefer</a>.

<hr width=200>

<a href=\"/philg/\"><address>philg@mit.edu</address></a>
</center>

</body>
</html>"
    } elseif { [string first "thumbnail_preference=base_fpx" $cookie] != -1 } {
	# 500x750 pixel FlashPix
	set result "<html>
<head>
<title>$jpeg_front</title>
</head>

<body bgcolor=#ffffff text=#000000>

<center>

<applet
 name=\"FViewer\"
 code=\"hp.image.iip.FViewer\"
 codebase=\"http://18.43.0.71/OpenPix/classes\"
 archive=\"FViewer.zip\"
 width=\"$width\"
 height=\"$height\"
 MAYSCRIPT
 alt=\"FViewer Applet Unavailable\">
<param name=\"cabbase\"  value=\"FViewer.cab\">
<param name=\"BgColor\" value=\"#FFFFFF\">
<param name=\"SourceURL\"
 value=\"/opx-bin/OpxIIPISA.dll?FIF=${url_stub}${fpx_filename}\">
</applet>

<br>
<br>
Available as <a href=\"${url_stub}${jpeg_front}.4.jpg\">a 1000x1500 pixel JPEG</a> or 
<a href=\"${url_stub}${jpeg_front}.3.jpg\">a 500x750 pixel JPEG</a>

<br>
<br>
$caption
$complete_tech_details
$complete_backlink
$complete_copyright

<br>
<br>

Note: This browser has been customized to request <a
href=\"http://clickthrough.photo.net/ct/philg/photo/index.html?send_to=http://image.hp.com\">FlashPix files</a> by
default.  If you want to change the default image size or format that
you get after clicking on a thumbnail, then <a
href=\"/photo/personalize-thumbnail-targets.tcl\">just tell us what
you'd prefer</a>.  If you wish to make a print of this image for personal use, you should
probably 

<a
href=\"http://rawfpx.photo.net${url_stub}${fpx_filename}\">download the raw
FlashPix file</a> and then 

read <a href=\"/photo/color-printers\">my article on
color printers</a>.

<hr width=200>

<a href=\"/philg/\"><address>philg@mit.edu</address></a>
</center>

</body>
</html>" } elseif { [string first "thumbnail_preference=base4_fpx" $cookie] != -1 } {
	# 200x400 pixel FlashPix (BASE/4)
    if { $width > 256 && $height > 256 } {
	set new_width [expr $width  / 2 ]
	set new_height [expr $height / 2]
    } else {
	# not all that big an image
	set new_width $width
	set new_height $height
    }
    set result "<html>
<head>
<title>$jpeg_front</title>
</head>

<body bgcolor=#ffffff text=#000000>

<center>

<applet
 name=\"FViewer\"
 code=\"hp.image.iip.FViewer\"
 codebase=\"http://18.43.0.71/OpenPix/classes\"
 archive=\"FViewer.zip\"
 width=\"$new_width\"
 height=\"$new_height\"
 MAYSCRIPT
 alt=\"FViewer Applet Unavailable\">
<param name=\"cabbase\"  value=\"FViewer.cab\">
<param name=\"BgColor\" value=\"#FFFFFF\">
<param name=\"SourceURL\"
 value=\"/opx-bin/OpxIIPISA.dll?FIF=${url_stub}${fpx_filename}\">
</applet>

<br>
<br>
Available as <a href=\"${url_stub}${jpeg_front}.4.jpg\">a 1000x1500 pixel JPEG</a> or 
<a href=\"${url_stub}${jpeg_front}.3.jpg\">a 500x750 pixel JPEG</a>

<br>
<br>
$caption
$complete_tech_details
$complete_backlink
$complete_copyright

<br>
<br>

Note: This browser has been customized to request <a
href=\"http://clickthrough.photo.net/ct/philg/photo/index.html?send_to=http://image.hp.com\">FlashPix files</a> by
default.  If you want to change the default image size or format that
you get after clicking on a thumbnail, then <a
href=\"/photo/personalize-thumbnail-targets.tcl\">just tell us what
you'd prefer</a>.  If you wish to make a print of this image for personal use, you should
probably read <a href=\"/photo/color-printers\">my article on
color printers</a>, especially the tips at the top for how to select
the View Image option and Print Preview.

<hr width=200>

<a href=\"/philg/\"><address>philg@mit.edu</address></a>
</center>

</body>
</html>" } else {
	# just the default
	set result "<html>
<head>
<title>$jpeg_front</title>
</head>

<body bgcolor=#ffffff text=#000000>

<center>

<img src=\"${url_stub}${jpeg_front}.3.jpg\" width=$width height=$height>

<br>
<br>
Available as <a href=\"${url_stub}${jpeg_front}.4.jpg\">a 1000x1500 pixel JPEG</a> or 
<a href=\"/photo/show-a-flashpix?url_stub=[ns_urlencode $url_stub]&fpx_filename=[ns_urlencode $fpx_filename]&width=$width&height=$height&jpeg_front=[ns_urlencode $jpeg_front]\">a FlashPix</a> (perfect for printing)

<br>
<br>
$caption
$complete_tech_details
$complete_backlink
$complete_copyright

<br>
<br>

Note: you can personalize this site.  If you want to change the
default image size or format that you get after clicking on a
thumbnail, then <a href=\"/photo/personalize-thumbnail-targets\">just tell us what you'd prefer</a>.

<hr width=200>

<a href=\"/philg/\"><address>philg@mit.edu</address></a>
</center>

</body>
</html>"}
      return $result
}

