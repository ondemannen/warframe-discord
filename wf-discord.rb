#!/usr/bin/ruby
require 'rss'
require 'open-uri'
require 'net/http'
require 'json'

discordid = ARGV[0] && ARGV[0].match(/discord/) ? true : false
search = ARGV[1]

url = "http://content.warframe.com/dynamic/rss.php?#{Random.new_seed}"

@discord_webhook = nil
if File.exist?(File.expand_path("~/etc/wf-discord.cfg"))
	# Create the file in ~/etc and just copy the prowl API key into it
	@discord_webhook = File.open(File.expand_path("~/etc/wf-discord.cfg")).read.chomp
end

done = []
saved = '/tmp/.warframe.rss'
if File.exist?(saved)
	fn = File.open(saved, "r")
	fn.each do |l|
		done << l.chomp
	end
end
@fn = File.open(saved, "a")

class String
	def clr1; "\e[90m#{self}\e[0m" end  # gray
	def clr2;  "\e[91m#{self}\e[0m" end # red
	def clr3;  "\e[92m#{self}\e[0m" end # green
	def clr4;  "\e[93m#{self}\e[0m" end # yellow
	def clr5;  "\e[94m#{self}\e[0m" end # blue
	def clr6;  "\e[95m#{self}\e[0m" end # purple
	def clr7;  "\e[95m#{self}\e[0m" end # bright yellow
	def clr8;  "\e[33m#{self}\e[0m" end # dull yellow
	def clr9;  "\e[34m#{self}\e[0m" end # dull yellow
end

def pretty_colors(str)
	str.gsub!(/(\d+cr|\(\d+K\))/,'\1'.clr3)
	str.gsub!(/(\d?x? (Mutagen Mass|Fieldron|Detonite Injector|Mutalist Nav Coordinate))/i,'\1'.clr2)
	str.gsub!(/([\w\s]+ \(Resource\))/i,'\1'.clr1)
	str.gsub!(/([\w\s]+ \(Blueprint\))/i,'\1'.clr6)
	str.gsub!(/([\w\s]+ \(Aura\))/i,'\1'.clr5)
	str.gsub!(/([\w\s]+ \(Key\))/i,'\1'.clr7)
	str.gsub!(/([\w\s]+ \(Mod\))/i,'\1'.clr4)
	str.gsub!(/([\w\s]+ \(Item\))/i,'\1'.clr9)
	str.gsub!(/((Forma|Orokin (Reactor|Catalyst)) Blueprint)/,'\1'.clr8)
	str
end

def send_message(data)
	uri = URI(@discord_webhook)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
	req.body = data.to_json
	res = http.request(req)
	puts "response #{res.body}"
end

open(url) do |rss|
	feed = RSS::Parser.parse(rss)
	feed.items.each do |item|
		data = {}
		data['content'] = sprintf("```%s (%s)```", item.author, item.title)
		guid = item.guid.to_s.gsub(/<.*?>(.*)<.*?>/,'\1')
		if !search
			printf("%s (%s)\n", item.author, pretty_colors(item.title))
			if @discord_webhook && discordid
				if(!done.include?(guid))
					send_message(data)
					@fn.puts guid
				end
			end
			next
		elsif item.title.match(/#{search}/i)
			if @discord_webhook && discordid
				if(!done.include?(guid))
					send_message(data)
					#cmd.gsub(/_TEXT_/,item.title).gsub(/_EVENT_/,item.author)}
					@fn.puts guid
				end
			else
				printf("%s, %s\n", item.author, pretty_colors(item.title))
			end
		end
	end
end
