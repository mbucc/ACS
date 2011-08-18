# $Id: index.tcl,v 3.0 2000/02/06 03:27:39 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Referrals to [ad_system_name]"]

<h2>Referrals to [ad_system_name]</h2>

[ad_admin_context_bar "Referrals"]

<hr>

<ul>

<form method=GET action=\"main-report.tcl\">
<li>last 
<select name=n_days>
[ad_generic_optionlist [concat [day_list] [list "all"]] [concat [day_list] [list "all"]] 7]
</select> days <input type=submit value=\"Go\">
</form>


<p>

<li><a href=\"search-engines.tcl\">from search engines</a>

</ul>

<h4> Advanced </h4>
<ul>
<li> <a href =\"mapping.tcl\">URL lumping patterns</a>
</ul>

<blockquote>
<i>Lumping patterns are useful when you want to lump all referrals from a
particular site together under one rubric.  This is particularly
useful in the case of referrals from search engines.</i>
</blockquote>

[ad_admin_footer]
"
