# /webmail/folder-move-to.tcl
# by jsc@arsdigita.com (2000-02-23)

# Set the current folder to mailbox_id and return to index.

ad_page_variables {mailbox_id}

if { $mailbox_id == "@NEW" } {
    # Create new mailbox.
    ad_returnredirect "folder-create.tcl?target=[ns_urlencode "index.tcl"]"
    return
}

validate_integer mailbox_id $mailbox_id

set cached_mailbox_id [ad_get_client_property "webmail" "mailbox_id"]

if { $cached_mailbox_id != $mailbox_id } {
    ad_set_client_property -persistent f "webmail" "mailbox_id" $mailbox_id
}

ad_returnredirect "index.tcl"
