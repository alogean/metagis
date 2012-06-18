require 'rubygems'
require 'find'
require 'rexml/document'
require 'rdf'
require 'rdf/ntriples'
require 'rdf/turtle'

include RDF

#require 'nokogiri'
# Open of a turtle writter with various prefixes
RDF::Turtle::Writer.open("sitg_skos_model.nt", 
  :base_uri => "http://www.sacac.ch/picos/thesaurus/", 
  :prefixes => {
  nil     => "http://www.sacac.ch/picos/thesaurus/ns#",
  :foaf   => "http://xmlns.com/foaf/0.1/",
  :rdf    => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  :rdfs   => "http://www.w3.org/2000/01/rdf-schema#",
  :owl    => "http://www.w3.org/2002/07/owl#",
  :skos   => "http://www.w3.org/2004/02/skos/core#",
  :dct    => "http://purl.org/dc/terms/",
  :coll   => "http://www.sacac.ch/picos/thesaurus/collections/",
  :schema => "http://www.sacac.ch/picos/thesaurus/schema#"
}) do |writer|   
  writer << RDF::Graph.new do |graph|
    temp_parent_node = Hash.new    
    Find.find('./db') do |path| 
      if File.directory? path then
        rdf_node = new_rdf_node = RDF::Node.new
        temp_parent_node[path] = rdf_node
        graph << RDF::Statement.new(new_rdf_node, RDF::type, RDF::SKOS.Concept)
        graph << RDF::Statement.new(new_rdf_node, RDF::SKOS.prefLabel, RDF::Literal.new(path, :language => :fr))      
      else  
        f = File.open(path)
        parent = path.gsub("/" + f.path.split("/").last, "")
        content = REXML::XPath.first(REXML::Document.new(f), '//DATASECTION//abstract//plainText')
        if content != nil then 
          if !content.to_s.empty? then 
            new_rdf_node = RDF::Node.new
            graph << RDF::Statement.new(new_rdf_node, RDF::type, RDF::SKOS.Concept)
            graph << RDF::Statement.new(new_rdf_node, RDF::SKOS.prefLabel, RDF::Literal.new(path, :language => :fr))
            graph << RDF::Statement.new(new_rdf_node, RDF::SKOS.definition, RDF::Literal.new(content, :language => :fr))
            if temp_parent_node.has_key? parent then
              graph << RDF::Statement.new(new_rdf_node, RDF::SKOS.broader, temp_parent_node[parent])
            end
          end
        end  
      end
    end
  end
end