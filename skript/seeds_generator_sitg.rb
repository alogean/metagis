require 'rubygems'
require 'find'
require 'rexml/document'
   
Find.find('./db') do |path| 
  if File.directory? path then
    puts path      
  else  
    f = File.open(path)
      parent = path.gsub("/" + f.path.split("/").last, "")
      #content = REXML::XPath.first(REXML::Document.new(f), '//DATASECTION//abstract//plainText').to_s
      title = REXML::XPath.first(REXML::Document.new(f), '//DATASECTION//title//plainText').to_s
=begin      
      if content != nil then 
        if !content.to_s.empty? then
          puts "--" + path
          puts "  --" + content
        end
      end
=end
        if title != nil then 
          if !title.to_s.empty? then
            puts path + " " + title
          end
        end
    end
end
