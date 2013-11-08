# Register a new user.
# Created: Fri Oct 11 22:58:57 EDT 2013

load 'utils.rb'

require "watir-webdriver"
browser = Watir::Browser.new :ff

create_user(browser, user('a@b.com', 'abc', 'fname', 'lname'))

browser.close
