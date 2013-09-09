# /www/bboards/sample-questions.tcl
ad_page_contract {
    Some stuff for people who can't figure out their own questions
    to ask

    @cvs-id sample-questions.tcl,v 3.0.12.3 2000/09/22 01:36:54 kevin Exp
} {
    topic:notnull
}


set edf_management_blather {<h3>Sample Questions to Ask Companies About Pollution Prevention</h3>

Pollution prevention means not creating waste in the first place and
reducing the use of toxic chemicals as inputs into business
operations.  Pollution prevention is different from "pollution
control" or "waste management" (including recycling, treatment,
burning, and disposal), which are less preferred methods to protect
the environment.  These strategies only stop waste chemicals from
entering the environment <em> after </em> they have been
unintentionally created.

<p>

The five sample questions on pollution prevention can help you
distinguish between real reductions in pollution and reductions which
only occur on paper, and can help you gain additional information
about facility environmental practices and performance.  Feel free to
edit the questions before posting them for a company to respond.

<p>

<ol>
<li>What toxic chemicals does your facility use or produce that it does not report to <a href="http://www.scorecard.org/general/tri/tri_gen.html"> TRI </a>, and has your facility switched to these chemicals since 1988?
<p>
<li>Were TRI reductions a result of calculating or measuring releases in a different manner, having other facilities perform operations formerly performed on-site, or a decline in production? Please explain.
<p>
<li>Do you have a pollution prevention plan, or an equivalent document identifying changes that will be made to improve plant efficiency and reduce use of toxic chemicals, with a summary that you will share with the public?
<p>
<li>Does your facility use materials accounting (i.e., input-output calculations) to identify pollution prevention opportunities?
<p>
<li>I am interested in how your total waste generation to air, water, and land relates to your production. Is the <a href= "http://www.scorecard.org/general/tri/tri_desc.html#Total_Production-Related_Waste"> total production-related waste (TPRW)</a> per unit produced declining? Please provide annual numbers (TPRW, units produced, and define the units used).
<p>
</ol>

<h3>Sample Questions to Ask Companies about an Unusual Event Such as a Spill or a Stack Release</h3>

The two sample questions about an unusual event will enable you to see
if a company has an acceptable explanation for an accident or other
event, and whether it has a system in place to investigate problems
and prevent them in the future.  Begin your questioning by describing
the event, including what occurred, when it occurred, and where, being
as specific as possible.  Feel free to edit the questions before
posting them for a company to respond.

<ol>
<li>Please explain what happened, and why.

<li>What actions are being taken, or have been taken, to prevent this
event from happening again?

</ol>

}

bboard_get_topic_info

doc_return  200 text/html "
[bboard_header "Sample Questions"]

<h2>Sample Questions</h2>

for the [bboard_complete_backlink $topic_id $topic $presentation_type]

<hr>

$edf_management_blather

[bboard_footer]"
