# Register a new user.
# Created: Fri Oct 11 22:58:57 EDT 2013

load 'utils.rb'

require "watir-webdriver"
browser = Watir::Browser.new :ff

#usera = user('amy@example.com', 'pwda', 'Amy', 'Adams')
#userb = user('bob@example.com', 'pwdb', 'Bob', 'McAdoo')
#
#add_user(browser, usera)
#logout(browser)
#
#add_user(browser, userb)
#logout(browser)
#
#news1 = news('title1')
#news2 = news('title2', 15)
#news3 = news('title3')
#
#add_news(browser, usera, news1)
#add_news(browser, userb, news2)
#add_news(browser, usera, news3)

add_news_comment(browser, usera, news2, comment())
