# /www/neighbor/post-new-old.tcl

ad_page_contract {
    An older version of post-new.tcl

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id post-new-old.tcl,v 3.1.2.3 2000/09/22 01:38:56 kevin Exp
    @param subcategory_1 the category to post into
} {
    subcategory_1:notnull
    poster_name:notnull
    poster_email:notnull
}

set exception_text ""
set exception_count 0

# bounce the ad if they didn't choose a category

if { [string equal $subcategory_1 "Choose a Category"] } {
    append exception_text "<li>You didn't choose a category for your posting.\n"
    incr exception_count
}

if { [string first "@" $poster_name] != -1 } {
    append exception_text "<li>You typed an \"@\" in the name field.  Unless you are the 
    musician formerly known as Prince, I suspect that you mistakenly typed your email address
    in the name field.\n"
    incr exception_count
}

if { ![regexp {.+@.+\..+} $poster_email] } {
    append exception_text "<li>Your email address doesn't look like
    'foo@bar.com'.  We only accept postings from people with email
    addresses.  If you got here, it probably means either that (a) you are
    going to wait another 27 years to see if this Internet fad catches on,
    or (b) that you are an AOL subscriber who thinks that he doesn't have to 
    type the \"aol.com\".
    "
    incr exception_count
}

if { $exception_count != 0 } {
    set page_content [neighbor_error_page $exception_count $exception_text]
} else {
    set page_content "[neighbor_header "Post Step"]"

    ns_set put $form one_line "$about : "
    ns_set put $form neighbor_to_neighbor_id new

    append page_content [bt_mergepiece [classified_NtoN_form new] $form]
}

doc_return  200 text/html $page_content

