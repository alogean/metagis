require 'nokogiri'
require 'json'

def parse_file
  
  f = File.open("bfs_products.xml")
  doc = Nokogiri::XML(f)
  a = Hash.new
  doc.xpath("//record").each do |rec|
    num = rec.xpath("prodnr").text
    b = Hash.new
    c = Hash.new
    c['fr'] = rec.xpath("text[@xml:lang='fr']").text
    c['de'] = rec.xpath("text[@xml:lang='de']").text
    c['en'] = rec.xpath("text[@xml:lang='en']").text
    c['it'] = rec.xpath("text[@xml:lang='it']").text
    b['def'] = c
    b['id'] = num
  
    key_a = num.split(".")
  
    case key_a.size
      when 1
        if !a.has_key? key_a[0] 
          then a[key_a[0]]=b
        end
      when 2
        if !a[key_a[0]].has_key? key_a[1] 
          then a[key_a[0]][key_a[1]]=b 
        end
      when 3
        if !a[key_a[0]][key_a[1]].has_key? key_a[2] 
          then a[key_a[0]][key_a[1]][key_a[2]]=b 
        end
      when 4
        if !a[key_a[0]][key_a[1]][key_a[2]].has_key? key_a[3] 
          then a[key_a[0]][key_a[1]][key_a[2]][key_a[3]]=b 
        end
      when 5
        if !a[key_a[0]][key_a[1]][key_a[2]][key_a[3]].has_key? key_a[4] 
          then a[key_a[0]][key_a[1]][key_a[2]][key_a[3]][key_a[4]]=b 
        end
      when 6
        if !a[key_a[0]][key_a[1]][key_a[2]][key_a[3]][key_a[4]].has_key? key_a[5] 
          then a[key_a[0]][key_a[1]][key_a[2]][key_a[3]][key_a[4]][key_a[5]]=b 
        end
    end
  end
  return a
end

def output_in_file 
  open("output.txt", "w") do |io|  
    a.keys.each do |k|
      io.write k
      io.write "\n"
      a[k].keys.each do |n|
        io.write a[k][n]
        io.write "\n"
      end
      io.write "=======================================\n"
    end
  end
end

def output_hash ( hash, filehandle, tab ) 
  if hash.is_a? Hash then
    hash.keys.each do |key|
      if key == "def" then
        filehandle.write tab + output_node(hash)
        filehandle.write "\n"
      else
        if hash[key].is_a? Hash then
          output_hash(hash[key], filehandle, tab + "--")
        #else
        #  filehandle.write "ERROR 1: not a hash : " + hash[key]
        end
      end 
    end
  else 
    filehandle.write "ERROR 2: not a hash : " + hash
  end    
end 

def output_node ( hash)
  if hash.is_a? Hash then
    hash['def']['fr'] + " (" + hash['def']['de'] + ")"
  end
end  

open("output.txt", "w") do |io|  
  a = parse_file
  output_hash(a, io, "")
end


