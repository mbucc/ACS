# /wp/presentation-pdf-download.tcl
ad_page_contract {
    Converts a presentation into PDF format

    @param presentation_id id of the presentation to convert

    @creation-date  07 Mar 2000
    @author Nuno Santos <nuno@arsdigita.com>
    @cvs-id presentation-pdf-download.tcl,v 3.2.2.6 2000/09/22 01:39:33 kevin Exp
} {
    presentation_id:naturalnum,notnull
}

proc_doc wp_replace_html_links_for_pdf {html} {Replaces HTML's image references and links for PDF output} {
    # image links:
    # <img src="/wp/attach/355/Slide1.JPG"> 
    # becomes
    # <img src="355-Slide1.JPG"> 
    regsub -all {<img src=\"/wp/attach/([0-9]+)/([^\"]+)\">} $html {<img src="\1-\2">} new_html

    # navigation and setup hyperlinks:
    # remove: done | next, top | next, previous | top | next, previous | top, change style, top
    regsub -all {<a href=\"[^\"]*\">previous</a> \| <a href=\"[^\"]*\">top</a> \| <a href=\"[^\"]*\">next</a>} $new_html "" new_html
    regsub -all {<a href=\"[^\"]*\">top</a> \| <a href=\"[^\"]*\">next</a>} $new_html "" new_html
    regsub -all {<a href=\"[^\"]*\">done</a> \| <a href=\"[^\"]*\">next</a>} $new_html "" new_html
    regsub -all {<a href=\"[^\"]*\">previous</a> \| <a href=\"[^\"]*\">top</a>} $new_html "" new_html
    regsub -all {<a href=\"[^\"]*\">change style</a>} $new_html "" new_html
    regsub -all {<a href=\"[^\"]*\">top</a>} $new_html "" new_html

    # other hyperlinks:
    # <a href="503.wimpy">link text</a>
    # becomes
    # link text
    regsub -all {<a href=\"[^\"]*\">} $new_html "" new_html
    regsub -all {</a>} $new_html "" new_html

    return $new_html
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "read"

# don't attempt conversion if there are no slides in the presentation
set slide_count_sql "select count(slide_id)
                     from wp_slides
                     where presentation_id = :presentation_id
                       and max_checkpoint is null"
set slide_count [db_string wp_sel_slide_count $slide_count_sql]
if {$slide_count == 0} {
    set title [db_string wp_sel_title "select title from wp_presentations where presentation_id = :presentation_id"]

    db_release_unused_handles

    ad_return_error "No slides in $title" "$title contains no slides, 
    so conversion to PDF format could not be performed.
    <p> Please go back using your browser and select a different presentation.<p>"

    return
}


# create temp directory (will contain HTML files and attachments)
set base_dir "/tmp/[ns_mktemp "$presentation_id-XXXXXX"]"
ns_mkdir $base_dir
ns_chmod $base_dir 0777

# output all attachments to the filesystem, to allow conversion to PDF
set attachs_sql "select a.attach_id, a.slide_id, a.file_name
                 from wp_attachments a, wp_slides s
                 where a.slide_id = s.slide_id
                   and s.presentation_id = :presentation_id
                   and s.max_checkpoint is null"

db_foreach wp_sel_attach $attachs_sql {
#    ns_ora blob_get_file $db "select attachment
    db_blob_get_file wp_sel_attach "select attachment
                                 from wp_attachments
                                 where attach_id = $attach_id" $base_dir/$attach_id-$file_name

    ns_chmod $base_dir/$attach_id-$file_name 0666
}

# output all slides as static HTML files
set slides_sql "select slide_id, title, sort_key
                from wp_slides
                where presentation_id = :presentation_id
                  and max_checkpoint is null
                order by sort_key"
set counter 0
set html_files ""
db_foreach wp_sel_slides_as_html $slides_sql {
    incr counter

    if {$counter == 1} {
	set toc_html [ns_httpget [ad_url][wp_presentation_url]/$presentation_id/]

	# replace image references within HTML to point at temporary files (created above)
	set toc_html [wp_replace_html_links_for_pdf $toc_html]

	set toc_html_filename "$base_dir/toc.html"
	append html_files "$toc_html_filename "
	
	set fileid [open $toc_html_filename w]
	puts $fileid $toc_html
	flush $fileid
	close $fileid
    }

    set slide_html [ns_httpget [ad_url][wp_presentation_url]/$presentation_id/$slide_id.wimpy]

    # replace image references within HTML to point at temporary files (created above)
    set slide_html [wp_replace_html_links_for_pdf $slide_html]

    set slide_html_filename "$base_dir/$slide_id.html"
    append html_files "$slide_html_filename "
    
    set fileid [open $slide_html_filename w]
    puts $fileid $slide_html
    flush $fileid
    close $fileid
}

db_release_unused_handles


# actually do the conversion to PDF
set pdf_filename "$base_dir/$presentation_id.pdf"

set command_line "[ad_parameter "PathToHtmlDoc" "wp" "/usr/bin/htmldoc"] --headfootfont Times-Italic --headfootsize 10 --header ... --footer .t1 --webpage -f $pdf_filename $html_files"

# create a temp "batch" file (needed due to command line length restricions)
set fileid [open "$base_dir/pdf-conversion-batch" w]
puts $fileid $command_line
flush $fileid
close $fileid

if [catch {exec sh $base_dir/pdf-conversion-batch} errmsg] {
    ad_return_error "Conversion to PDF failed" "The conversion to PDF format has failed. Please go back using your browser.
        <p>Here is the exact error message: <pre>$errmsg</pre></li>"
} else {
    ad_returnfile 200 "application/pdf" $pdf_filename
}

# cleanup
file delete -force $base_dir












