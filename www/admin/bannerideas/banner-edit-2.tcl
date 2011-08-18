# $Id: banner-edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:23 carsten Exp $
set_the_usual_form_variables

# intro, more_url, picture_html, keywords, idea_id

set exception_count 0
set exception_text ""

# we were directed to return an error for intro
if {![info exists intro] ||[empty_string_p $intro]} {
	incr exception_count
	append exception_text "<li>Please enter an idea."
} 

# we were directed to return an error for more_url
if {![info exists more_url] ||[empty_string_p $more_url]} {
	incr exception_count
	append exception_text "<li>Please enter a link to your URL."
} 

if {$exception_count > 0} {
	ad_return_complaint $exception_count $exception_text
	return
}

# So the input is good --
# Now we'll do the update of the bannerideas table.
set db [banner_ideas_gethandle]
if [catch {ns_db dml $db "update bannerideas 
      set intro = '$QQintro', 
	more_url = '$QQmore_url', 
	picture_html = '$QQpicture_html', 
	keywords = '$QQkeywords'
      where idea_id = '$idea_id'" } errmsg] {

# Oracle choked on the update
    ad_return_error "Error in update
    " "We were unable to do your update in the database.
    Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

ad_returnredirect index.tcl
