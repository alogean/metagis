require 'rubygems'
require 'find'
require 'rexml/document'
require 'nokogiri'

Find.find('./db') do |path| 
  if !File.directory? path
  then 
    f = File.open(path)
      puts "=============================================================================================="
      puts "#{path}"
      puts "=============================================================================================="
      $stderr.print "parsing  #{path}\r"
      doc = REXML::Document.new File.open(path)
      puts REXML::XPath.first(doc, '//plainText')
      #puts Nokogiri::XML(f).xpath('//TRANSFER//DATASECTION')
    f.close
  end
end