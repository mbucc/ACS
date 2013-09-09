# /webmail/folder-move-to.tcl

ad_page_contract {
    Set the current folder to mailbox_id and return to index.
    
    @param mailbox_id Usually, this is the ID of the mailbox. If set to "@NEW", we redirect
    to create a new mailbox

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id folder-move-to.tcl,v 1.4.6.3 2000/08/13 20:04:25 mbryzek Exp
} {
    mailbox_id
    { return_url "index" }
}

if { $mailbox_id == "@NEW" } {
    # Create new mailbox.
    ad_returnredirect "folder-create?target=[ns_urlencode $return_url]"
    return
}

# Have to explicitly validate this integer because it was not validated 8in
# ad_page_contract
validate_integer mailbox_id $mailbox_id

set cached_mailbox_id [ad_get_client_property -browser t "webmail" "mailbox_id"]

if { $cached_mailbox_id != $mailbox_id } {
    ad_set_client_property -browser t "webmail" "mailbox_id" $mailbox_id
}

ad_returnredirect $return_url
