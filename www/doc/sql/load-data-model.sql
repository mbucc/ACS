--
-- /www/doc/sql/load-data-model.sql
--
-- Initialize an ACS database. To run this file, type:
--
-- % sqlplus username/password < load-data-model.sql
--
-- load-data-model.sql,v 3.13.2.15 2001/01/13 01:51:53 khy Exp
--

@modules
@../../../packages/acs-core/apm
@../../../packages/acs-core/community-core
@../../../packages/acs-core/user-groups
@../../../packages/acs-core/security
@content-sections
@pl-sql
@general-permissions
@news
@calendar
@bboard
@classifieds
@contest
@display
@download
@adserver
@dw
@faq
@registry
@spam
@neighbor
@address-book
@bannerideas
@chat
@content-tagging
@email-handler
@glossary
@member-value
@robot-detection
@tools
@file-storage
@bookmarks
@general-comments
@general-links
@general-portraits
@ticket
@ticket-data
@portals
@crm
@user-custom
@curriculum
@press
@partner
@wp
@poll
@events
@homepage
@pull-down-menus
@pull-down-menu-data
@intranet
@survey-simple.sql
@job-listings
@monitoring.sql
@wap
@db-logging
@table-metadata
@manuals
@security-create.sql