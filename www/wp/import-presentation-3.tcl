# /wp/import-presentation-3.tcl

ad_page_contract  {
    Imports a presentation from another server.
    @author Alen Zekulic (alen@ultra.hr)
    @creation-date 2000-09-11
    @cvs-id import-presentation-3.tcl,v 1.1.2.5 2000/09/24 15:16:07 azekulic Exp
} { 
    url:notnull,trim
    email:optional
    password:optional
}


ad_maybe_redirect_for_registration
set user_id [ad_verify_and_get_user_id]

set exception_count 0
set include_slides_p 1

regsub {(([0-9]+)\.wimpy)?$} $url "" url
set complete_url "$url/export-presentation?[export_url_vars email password include_slides_p]"

if [catch {array set presentation_properties [ns_httpget "$complete_url"]} errmsg] {
   ad_return_error "Error" "Import failed, here is the exact error message: <pre>$errmsg</pre>"
   return
}

if [exists_and_not_null presentation_properties(status_code)] {
   if {![wp_check_status_code $presentation_properties(status_code) $url $email $password]} {
     return
   }
} else {
   ad_return_error "Unexpected Result" "We received an unexpected result when querying for the status of requested presentation. It would be helpful if you could email <a href=\"mailto:[ad_system_owner]\">[ad_system_owner]</a> with the events that led up to this occurrence."
   return
}


ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: text/html
"
ns_startcontent -type text/html

ns_write "
[wp_header [list "" "WimpyPoint"] "Importing Presentation"]
"

db_transaction {

    set presentation_id [wp_nextval "wp_ids"]
    
    # Reading from the presentation_properties array, 
    # create the presentation in the database.

    foreach i [array names presentation_properties] {
        if { $i != "slides" } {
           set $i $presentation_properties($i)
        }
    }

    db_dml pres_insert { 
        insert into wp_presentations(presentation_id, title, page_signature, 
                                     copyright_notice, creation_date, creation_user, 
                                     public_p, audience, background)
                             values (:presentation_id, :title, :page_signature, 
                                     :copyright_notice, :creation_date, :user_id, 
                                     :public_p, :audience, :background)
    }

    ns_write "<p>Title: <b>$presentation_properties(title)</b>.\n
    <ul>"

    set sort_key 0
    set checkpoint 0 

    db_dml checkpoint_insert {
       insert into wp_checkpoints(presentation_id, checkpoint, wp_checkpoints_id)
                           values(:presentation_id, 0, wp_checkpoints_seq.nextval)
    }

    # Reading from $presentation_properties(slides), create the slides in 
    # the presentation. For each attachment, download the attachment from 
    # the foreign server and insert it.

    foreach slide $presentation_properties(slides) {
        set slide_id [wp_nextval "wp_ids"]
        array set slide_properties $slide
        foreach i [array names slide_properties] {
            # initialize bind variables for insert
            if { $i != "slide_id" } {
              set $i $slide_properties($i)
            }
        }
        db_dml slide_insert {
            insert into wp_slides (slide_id, presentation_id, min_checkpoint, sort_key,
                                   title, include_in_outline_p, context_break_after_p,
                                   preamble, bullet_items, postamble, modification_date)
            values(:slide_id, :presentation_id, :checkpoint, :sort_key,
                   :title, :include_in_outline_p, :context_break_after_p,
                   :preamble, :bullet_items, :postamble, :modification_date)
        }
        ns_write "<li>imported slide: <b>$title</b>.</li>\n
                  <ul>"

        set sort_key [expr { $sort_key + 1.0 }]

        # For each attachment, download the attachment from 
        # the foreign server and insert it.
        foreach attach $slide_properties(attach) {
            array set attach_properties $attach
            foreach i [array names attach_properties] {
                # initialize bind variables for insert
                set $i $attach_properties($i)
            }

            regexp {(.+/wp)(/display/[0-9]+)} $url all attach_url rest

            set complete_url "$attach_url/attach/$attach_id/$file_name?[export_url_vars email password]"

            set tmpdir_list [ad_parameter_all_values_as_list TmpDir]
            if [empty_string_p $tmpdir_list] {
                set tmpdir "/tmp"
            } else {
                set tmpdir [lindex $tmpdir_list 0]
            }

            set tmpfile "$tmpdir/[ns_mktemp "$attach_id-XXXXXX"]"

            set wget [ad_parameter "PathToWget" "wp" "/usr/local/bin/wget"]

            exec "$wget" "-qO" "$tmpfile" "$complete_url"

            db_dml wp_insert_attachment {
                insert into wp_attachments(attach_id, slide_id, attachment,
                                           file_size, file_name, mime_type, display)
                                    values(wp_ids.nextval, :slide_id, empty_blob(),
                                           :file_size, :file_name, :mime_type, :display)
                returning attachment into :1
            } -blob_files $tmpfile
            ns_write "<li>imported attachment: <code>$file_name</code>.</li>\n"

            file delete $tmpfile
        }
        ns_write "</ul>\n"
    }
} on_error {
    ns_write "</ul></ul>\n"
    set exception_count 1
}

db_release_unused_handles

ns_write "</ul>\n"

if { $exception_count } {
    ns_write "<p><font color=red><strong>Error: Import failed.</strong></font>
              <p>Here is the exact error message: <pre>$errmsg</pre>
              <p>
              [wp_footer]"
    return
}

ns_write "
<p>
 Presentation <a href=\"/wp/display/$presentation_id/\"> 
               $presentation_properties(title)</a> imported.
 \[ <a href=\"presentation-top?presentation_id=$presentation_id\">edit</a> |
    <a href=\"presentation-delete?presentation_id=$presentation_id\">delete</a> \]

<p>
[wp_footer]
"
