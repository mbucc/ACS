<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id master.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}

  set page_title "Creating a Master Template"
  
  set menu [ad_template_menu { "Home" "../index.adp" } \
                             { "Tutorial" "index" }]

  set menu.rowcount [llength $menu]

  uplevel #0 {}
%>

<enclose src="../../templates/master.adp">
This is the content.
</enclose>
