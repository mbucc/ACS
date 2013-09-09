# /www/admin/referer/index.tcl
ad_page_contract {

    Provides an interface to the referer system that lets admins select which referrals to view.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 4 Jul 1998
    @cvs-id index.tcl,v 3.3.2.5 2000/09/22 01:35:59 kevin Exp

}

set page_content "[ad_admin_header "Referrals to [ad_system_name]"]

<h2>Referrals to [ad_system_name]</h2>

[ad_admin_context_bar "Referrals"]

<hr>

<ul>

<form method=GET action=\"main-report\">
<li>last 
<select name=n_days>
[ad_generic_optionlist [concat [day_list] [list "all"]] [concat [day_list] [list "all"]] 7]
</select> days <input type=submit value=\"Go\">
</form>

<p>

<li><a href=\"search-engines\">from search engines</a>

</ul>

<h4> Advanced </h4>
<ul>
<li> <a href =\"mapping\">URL lumping patterns</a>
</ul>

<blockquote>
<i>Lumping patterns are useful when you want to lump all referrals from a
particular site together under one rubric.  This is particularly
useful in the case of referrals from search engines.</i>
</blockquote>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
