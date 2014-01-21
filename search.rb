require 'shellwords'

query = ARGV[0].strip
search_path = ARGV[1]

def clean(string)
	clean = string.dup
	clean.gsub!("&", "&amp;")
	clean.gsub!("<", "&lt;")
	clean.gsub!(">", "&gt;")
	clean.gsub!("'", "&apos;")
	# clean.gsub!("\"", "&quot;")
	clean
end

def get_item_for_file(result)
	item = Item.new
	if File.file? result
		item.title = File.basename result, '.md'
		item.subtitle = "Open this note"
		item.arg = result
		item.icon = result
		item.subtitle = result
		item.type = "file"
	else
		item.title = File.basename result
		item.subtitle = "Search this directory"
		item.arg = result
		item.type = "file"
		item.icon = result
		item.valid = false
		item.autocomplete = File.basename(result) + '/'
	end
	item
end

class Item
	attr_accessor :uid, :arg, :type, :valid, :autocomplete, :title, :subtitle, :icon, :icon_is_file

	def initialize
		@uid = nil
		@arg = nil
		@type = nil
		@valid = true
		@autocomplete = nil
		@title = ""
		@subtitle = ""
		@icon = ""
		@icon_is_file = true
	end
	# UID = how alfred knows which search result is which, to prioritize in the future
	# ARG = argument passed to next part of workflow
	# type = set to "file" if the result is a file that can have stuff done to it
	# valid = if the result is actionable.
	# autocomplete = if this is set and valid is no, this content will be inserted into the alfred window

	def valid_string
		@valid ? "yes" : "no"
	end

	def to_s
		string = ""
		string << %{<item}
		string << %{ uid="#{clean @uid}"} if @uid
		string << %{ arg="#{clean @arg}"} if @arg
		string << %{ type="#{clean @type}"} if @type
		string << %{ valid="#{clean valid_string}"}
		string << %{ autocomplete="#{clean @autocomplete}"} if @autocomplete
		string << %{>}
		string << %{<title>#{clean @title}</title>}
		string << %{<subtitle>#{clean @subtitle}</subtitle>}
		string << %{<icon type="fileicon">#{clean @icon}</icon>} if @icon_is_file
		string << %{<icon>#{clean @icon}</icon>} if !@icon_is_file
		string << %{</item>}
	end
end

# If the user has specified a directory, add it to the search path
# and keep only the last little bit as the search query
if query =~ /\//
	directory_path = query.match(/(.+)\//)[1]

	# if File.directory? File.join(search_path, directory_path)
		search_path = File.join(search_path, directory_path)
		query = query.match(/\/(.*)$/)[1]
	# end
end

item_list = []

# If the user has a query, search for it!
if query.length > 0
	search_results = `mdfind #{Shellwords.escape(query)} -onlyin #{Shellwords.escape(search_path)}`

	search_results.each_line do |result|
		result.strip!

		if item_list.length < 9
			item_list << get_item_for_file(result)
		end
	end
# No query? Just display recently modified files
elsif File.directory?(search_path)
	files = Dir[File.join(search_path, '*')].sort { |a, b| File.mtime(b) <=> File.mtime(a) }
	files.each do |file|
		if item_list.length < 15
			item_list << get_item_for_file(file.to_s)
		end
	end
end

# If there is a query, the last option should be to create a new note with that name
if query && query.length > 0
		item = Item.new
		item.title = "Create #{query}"
		item.subtitle = "Create a new note called #{query}"
		# item.subtitle = File.join(search_path, query)
		item.arg = File.join(search_path, query)
		item.icon = 'newnote.png'
		item.icon_is_file = false

		item.title = "Edit the #{File.basename(search_path)} template" if query == ".template"
		item.subtitle = "This template will be used for new notes in the #{File.basename(search_path)} folder"
		item_list << item
end

puts %{<?xml version="1.0"?><items>} + item_list.join + %{</items>}