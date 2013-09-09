<%=[ad_header "Ticket system help"]%>

<%
    ad_page_contract {
	{return_url "/ticket/"}
    } {
	Displays ticket tracker help

	@param return_url where we go when finished

	@cvs-id help.adp,v 3.1.10.2 2000/09/08 20:48:08 kevin Exp
    }
%>

<h1>Ticket system help</h1>

<%= [ticket_context [list [list $return_url {Ticket Tracker}] [list {} {Help}]]] %>

<hr>
    <h3> Navigation and Viewing </h3>
    
    By default all tickets for all projects are displayed. 
    If you restrict viewing to a particular project or feature area
    you may remove the restriction by chosing the link "Ticket Tracker" on 
    the context bar.
    <p>
      To view an individual ticket you follow the link under the "ID#"
      column.
    <p>
      the links under the project and feature are columns will
      restrict the tickets to the given project.
      
      
    <h3> Creating tickets </h3>
    You create a ticket via the Add new ticket link.  If you are viewing a 
    particular project you may create a ticket directly in that project.
    <p>
      If a default assignee exists that person will be automatically 
      notified.

    <h3> Custom Settings </h3>
    You can set the defaults for your account via the "Custom Settings"
    link in the upper right.  You can also put the ticket tracker 
    in "expert mode" which allows creating and save custom table views 
    and sorts.
    
    <h3> Sorting </h3>
    You can sort on a given column by clicking on the heading for the 
    column.
    <p>
      The sorts are "stable" which means that if you first sort by
      priority then by status by clicking on each column respectively
      the second sort will be on "status then priority."  Clicking
      twice on the heading will reverse the normal sort order.
      
      
      
      
      <%=[ad_footer]%>


