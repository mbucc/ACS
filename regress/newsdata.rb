# Register a new user.
# Created: Fri Oct 11 22:58:57 EDT 2013

load 'utils.rb'

require "watir-webdriver"
browser = Watir::Browser.new :ff

articles_n = 10
comments_n = 25

users = [
	user('amy@example.com'   , 'pwda', 'Amy'   , 'Adams'),
	user('bob@example.com'   , 'pwdb', 'Bob'   , 'McAdoo'),
	user('chris@example.com' , 'pwdc', 'Chris' , 'Everett'),
	user('dennis@example.com', 'pwdd', 'Dennis', 'Rodman'),
	user('eric@example.com'  , 'pwde', 'Eric'  , 'Idle')
]

news = Array.new
articles_n.times do
	news.push news()
end

comments = Array.new
comments_n.times do
	comments.push comment()
end

users.each    { |x| add_user(browser, x) }
news.each     { |x| add_news(browser, users[rand(0..users.length-1)], x) }
comments.each { |x| add_news_comment(browser, users[rand(0..users.length-1)], news[rand(0..news.length-1)], x) }
