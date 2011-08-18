# $Id: banner-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:23 carsten Exp $
set_the_usual_form_variables

# idea_id, intro, more_url, picture_html, keywords

#Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

# we were directed to return an error for intro
if {![info exists intro] || [empty_string_p $intro]} {
	incr exception_count
	append exception_text "<li>Please enter an idea."
} 

# we were directed to return an error for more_url
if {![info exists more_url] || [empty_string_p $more_url]} {
	incr exception_count
	append exception_text "Please enter a link to your URL."
} 

if {[info exists intro] && [string length $intro] > 4000 } {
	incr exception_count
	append exception_text "<li>Please limit your idea to 4000 characters."
} 

if {[info exists picture_html] && [string length $picture_html] > 4000 } {
	incr exception_count
	append exception_text "<li>Please limit your picture url to 4000 characters."
} 

if {[info exists keywords] && [string length $keywords] > 4000 } {
	incr exception_count
	append exception_text "<li>Please limit your keywords 4000 characters."
} 

if {$exception_count > 0} {
	ad_return_complaint $exception_count $exception_text
	return
}

# So the input is good --
# Now we'll do the insertion in the bannerideas table.
set db [banner_ideas_gethandle]
if [catch {ns_db dml $db "insert into bannerideas
      (idea_id, intro, more_url, picture_html, keywords)
      values
      ($idea_id, '$QQintro', '$QQmore_url', '$QQpicture_html', '$QQkeywords')" } errmsg] {

# Oracle choked on the insert
 if { [ database_to_tcl_string $db " 
    select count(*) from bannerideas where idea_id = $idea_id"] == 0  } { 

    # there was an error with the insert other than a duplication
    ad_return_error "Error in insert
    " "We were unable to do your insert in the database.
    Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
    }
} 
ad_returnredirect index.tcl
