require 'rubygems'
require 'hpricot'
require 'cgi'
require 'csv'
require 'rexml/document'
require 'nokogiri'


module OHTHandler

 PATH_TO_HTML                      = "daten/OHTs_html/"
 PATH_TO_XSD                       = "daten/OHTs_xsd/"
 PATH_TO_SHEMATRON                 = "daten/OHTs_shematron/"
 PATH_TO_GEN_MAC_ABSOLUT           = "/Users/ecolix/Xprojets/ICSneu/ICSneu_svn/runtime-EclipseApplication/proto-faktendaten-demo/"
 PATH_TO_GEN_RELATIV               = "daten/OHTs_gen/"
 PATH_TO_GEN_WIN_ABSOLUT           = "C:/Users/ecolix/runtime-ICSNeuManager.product/ohts/"
 MAPPING_FILE_OHT_NUM_TO_OHT_NAME  = "daten/mapping_html_xsd.csv"
 PATH_TO_ICSALT_GEN                = "daten/ICSalt_gen/"
 ICS_ALT_UMD                       = "daten/umd.csv"
 OHT_ICSALT_MAP                    = "daten/MDs-OHTs_mapping.csv"
 ICS_ALT_MAPPING_PROJECT           = "daten/mapping.xml"
 ICS_ALT_MAPPING_PROJECT_VOEGEL_V  = "/Users/ecolix/icsneu/protoOHTs/daten/VOEGEL_Vbis.xml"
 PATH_TO_GEN                       = PATH_TO_GEN_RELATIV
 SEPARATOR                         = ";"
 TYPE_NUM_RANGE                    = "NumerischerWerteBereich"
 LOGGING                           = false


 #---------------------------------------------------------------------------------------------------------------------
 #
 #---------------------------------------------------------------------------------------------------------------------
 Map_oht_num_to_oht_name = {}
 CSV.open(MAPPING_FILE_OHT_NUM_TO_OHT_NAME, 'r') do |row|
   Map_oht_num_to_oht_name[row[0].split(";")[0].split(" ")[1]] = row[0].split(";")[1]
 end
 Map_oht_num_to_oht_name.keys.each do |key|
   #p key + " --> " + Map_oht_num_to_oht_name[key]
 end

 #---------------------------------------------------------------------------------------------------------------------
 # Map used to store the result of the mapping project
 #---------------------------------------------------------------------------------------------------------------------
 Map_icsalt_oht_xpath = {}
 p "Read information of the mapping project..."
 f = File.open(ICS_ALT_MAPPING_PROJECT)
 mappings = Nokogiri::XML(f)
 f.close
 mappings.xpath("//Mapping").each do |mapping|
   md_xpath       = mapping.xpath("Textwert//UntermerkmalXPath")
   md_uxpathes = mapping.xpath("Textwert//Unterpfade//Unterpfad")
   if md_xpath.inner_text.size != 0 then
     md_name = mapping.xpath("MerkmalName").inner_text
     md_num  = mapping.xpath("UntermerkmalNummer").inner_text
     unless Map_icsalt_oht_xpath.has_key? md_name
       #p "Map " + md_name + " defined"
       Map_icsalt_oht_xpath[md_name] = {}
     end
     if md_uxpathes.size > 0 then
       md_uxpathes.each do |unterpath|
         full_path = md_xpath.inner_text + "/" + unterpath.inner_text
         Map_icsalt_oht_xpath[md_name][full_path] = md_num
         #p "Map " + md_name + ": key: " + full_path + " value: " + md_num
       end
     else
       Map_icsalt_oht_xpath[md_name][md_xpath.inner_text] = md_num
     end
   end
 end
 p "End of reading mapping .information"
 f = File.open(ICS_ALT_MAPPING_PROJECT_VOEGEL_V)
 mappings_voegel = Nokogiri::XML(f)
 f.close
 Map_icsalt_oht_xpath["VOEGEL_V"] = {}
 mappings_voegel.xpath("//Mapping").each do |mapping|
   md_num  = mapping.xpath("UntermerkmalNummer").inner_text

   md_xpath1 = mapping.xpath("UntermerkmalXPath1")
   if md_xpath1.inner_text.size != 0 then
     Map_icsalt_oht_xpath["VOEGEL_V"][md_xpath1.inner_text] = md_num
   end

   md_xpath2 = mapping.xpath("UntermerkmalXPath2")
   if md_xpath2.inner_text.size != 0 then
     Map_icsalt_oht_xpath["VOEGEL_V"][md_xpath2.inner_text] = md_num
   end

   md_xpath3 = mapping.xpath("UntermerkmalXPath3")
   if md_xpath3.inner_text.size != 0 then
     Map_icsalt_oht_xpath["VOEGEL_V"][md_xpath3.inner_text] = md_num
   end

   md_xpath4 = mapping.xpath("UntermerkmalXPath4")
   if md_xpath4.inner_text.size != 0 then
     Map_icsalt_oht_xpath["VOEGEL_V"][md_xpath4.inner_text] = md_num
   end

   md_xpath5 = mapping.xpath("UntermerkmalXPath5")
   if md_xpath5.inner_text.size != 0 then
     Map_icsalt_oht_xpath["VOEGEL_V"][md_xpath5.inner_text] = md_num
   end

   md_xpath6 = mapping.xpath("UntermerkmalXPath6")
   if md_xpath6.inner_text.size != 0 then
     Map_icsalt_oht_xpath["VOEGEL_V"][md_xpath6.inner_text] = md_num
   end

 end


 #---------------------------------------------------------------------------------------------------------------------
 # Map used to store xpath information that is read by parsing the ohts
 #---------------------------------------------------------------------------------------------------------------------
 Map_xpath_ohts = {}

 #---------------------------------------------------------------------------------------------------------------------
 # Map used to store information of ICSalt Untermerkmalen
 #---------------------------------------------------------------------------------------------------------------------
 ICSalt_MD = {}
 p "Read ICSalt Untermerkmal Informations ..."
 CSV.open(ICS_ALT_UMD, 'r') do |row|
   mdkey = row[1].gsub(" ", "").gsub("\303\204", "AE").gsub("\303\226", "OE").gsub("\303\234", "UE")
   child = row[2].gsub(" ", "")
   parent = row[3].gsub(" ", "")
   desc = row[5].gsub("\303\274", "ue").gsub("\303\266", "oe").gsub("\303\244", "ae").gsub("\302\260)", "°")
   a = [child.gsub(".", "_"), parent, desc]
   unless ICSalt_MD.has_key? mdkey
     ICSalt_MD[mdkey] = {}
   end
   ICSalt_MD[mdkey][Float(child)] = a
 end

 #---------------------------------------------------------------------------------------------------------------------
 # Map used to store information of ICSalt Untermerkmalen
 #---------------------------------------------------------------------------------------------------------------------
 ICSalt_mapped_MDs_rest = {
         "VOEGEL_A"=> "EC_BIRD_TOX",
         "ARTHROP" => "EC_HONEYBEESTOX"
 }

 #---------------------------------------------------------------------------------------------------------------------
 # Map used to store information of ICSalt Untermerkmalen
 #---------------------------------------------------------------------------------------------------------------------
 ICSalt_OHTs = {"ADS_DESORP" => "EN_ADSORPTION",
                "VOEGEL_V"=> "EC_BIRD_TOX", "BIENEN" => "EC_HONEYBEESTOX",
                "ALGEN" => "EC_ALGAETOX",
                "AQ_PFLANZE" => "EC_AQ_PLANTS_OTHER",
                "DAPHNIEN_A" => "EC_DAPHNIATOX",
                "DAPHNIEN_V" => "EC_CHRONDAPHNIATOX",
                "DDRUCK" => "PC_VAPOUR",
                "FETTLOSL" => "PC_SOL_ORGANIC",
                "FISCHE_V" => "EC_CHRONFISHTOX",
                "FISCHE_A"=> "EC_FISHTOX",
                "H2OLOSL"=> "PC_WATER_SOL",
                "HEN_KON"=> "EN_HENRY_LAW",
                "HYDRO"=> "TO_HYDROLYSIS",
                "LOGPOW"=> "PC_PARTITION",
                "MIKRO_AQUA"=> "EC_BACTOX",
                "MIKRO_TERR"=> "EC_SOIL_MICRO_TOX",
                "OBFLSPA"=> "PC_SURFACE_TENSION",
                "PART_GR"=> "PC_GRANULOMETRY",
                "PFLANZEN"=> "EC_PLANTTOX",
                "PHOTO"=> "TO_PHOTOTRANS_AIR",
                "REGENWURM"=> "EC_SOILDWELLINGTOX",
                "REL_DICHT"=> "PC_DENSITY",
                "SCHMELZP"=> "PC_MELTING",
                "SED_ORG"=> "EC_SEDIMENTDWELLINGTOX",
                "SIEDEP"=> "PC_BOILING",
                "SONST_AQ_A"=> "EC_AQUATIC_OTHER"}

 OHTs_ICSalt = {}
 ICSalt_OHTs.keys.each do |key|
   OHTs_ICSalt[ICSalt_OHTs[key]] = key
 end

 # =======================================================================================
 #
 # Class OHT: Top level oject usde to store inoformation about an OECD Harmonized
 # Template.
 #
 # =======================================================================================
 class OHT
   attr_accessor :name, :title, :number, :sections, :section_keys

   def initialize(name, title, number)
     @name = name
     @title = title
     @number = number
     @sections = {}
     @section_keys = []
   end
 end

 # ============================================================================
 #
 # Class Section
 #
 # ============================================================================
 class Section
   attr_accessor :name, :label, :desc, :card, :blocks, :block_keys,
                 :subsections, :subsection_keys, :fields, :field_keys, :level

   def initialize(name, label, desc, level, card = "1")
     @name = name
     @label = label
     @desc = desc
     @card = card
     @level = level

     @blocks = {}
     @block_keys = []

     @subsections = {}
     @subsection_keys = []

     @fields = {}
     @field_keys = []
   end
 end

 # ============================================================================
 #
 # class Field
 #
 # ============================================================================
 class Field
   attr_accessor :name, :label, :type, :oht_format, :desc, :rem, :xpath, :enumcode, :level

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def initialize(name, label, type, oht_format, desc, rem, xpath, enumcode, level)
     @name = name
     @label = label
     @type = type
     @oht_format = oht_format
     @desc = desc
     @rem = rem
     @xpath = xpath
     @enumcode = enumcode
     @level = level
   end
 end


 # ============================================================================
 #
 # class Node
 #
 # ============================================================================
 # TODO : this class should replace Section. Use of a recursive structure
 class Node
   attr_accessor :name, :label, :type, :desc, :card, :children, :level, :parent, :fields, :hlevel

   # --------------------------------------------------------------------------
   # Class constructor
   # --------------------------------------------------------------------------
   def initialize(name, label, type, desc, parent, level, card = "1")
     @name = name
     @label = label
     @desc = desc
     @type = type
     @parent = parent
     @level = level
     @card = card
     @hlevel = 0 #hierarchie level
     @index = {}
     @children = []
     @fields = []
   end

   # --------------------------------------------------------------------------
   # A children is added
   # --------------------------------------------------------------------------
   def add (name, label=nil, type=nil, desc=nil, level=nil, card=1)
     b = Node.new(name, label, type, desc, self, level, card)
     b.set_hlevel(self.hlevel + 1)
     @children << b
     @index[name] = @children.size-1
     return b
   end

   # --------------------------------------------------------------------------
   # set the hierachy level of a node in tree (root = 1)
   # --------------------------------------------------------------------------
   def set_hlevel(hlevel)
     @hlevel = hlevel
   end

   # --------------------------------------------------------------------------
   # based on the hierachy level of a 2 nodes, determine their parental relation
   # --------------------------------------------------------------------------
   def is_parent_of (ahlevel)
     if ahlevel > self.hlevel then
       true
     else
       false
     end
   end

   # --------------------------------------------------------------------------
   # Based on the name of a child return the child
   # --------------------------------------------------------------------------
   def child(block_name)
     @children[@index[block_name]]
   end

 end

 # ============================================================================
 #
 # class OHTParser
 #
 # ============================================================================
 class OHTParser

   attr_accessor :oht, :html, :xsd

   @@basetypes = []
   @@enumerations = {}

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def initialize(html_source)
     begin
       @html = open(html_source) { |f| Hpricot(f) }
     rescue Errno::ENOENT
       puts "The file " + html_source + " could not be read."
     end
     # read the content of the second table
     tables = @html.search("/html/body//table")
     if tables.size >= 1 then
       @data = tables[1]
     end
     oht_num = @html.at("/html/head/title").inner_text.gsub("\302\240", " ").split(" ")[4]
     if Map_oht_num_to_oht_name.has_key? oht_num
       name = Map_oht_num_to_oht_name[oht_num].gsub("_20070330_000000.xsd", "")
       f = File.open(PATH_TO_XSD + Map_oht_num_to_oht_name[oht_num])
       #@xsd = REXML::Dokument.new(f)
       f.close
     else
       name = "UNDEFINED_NAME_" + oht_num
       p "no xsd file for template " + oht_num
     end
     title =   @html.at("/html/head/title").inner_text.gsub("\302\240", " ").split(":")[1]
     @oht = OHT.new(name, title, oht_num)

     # parse the HTML OHT file and fill the @oht object
     p "Parsing content of OHT " + name
     read_content()

     #remove "Data Source" Section
     #@oht.section_keys.slice!(0)
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def read_content

     last_used_section_name = ""
     last_used_subsection_name = ""
     last_used_block_name = ""
     last_used_parent_type = ""
     last_used_parent_type_for_block = ""
     last_used_type = ""
     last_field_label = ""

     #builder = Nokogiri::XML::Builder.new do |xml|
     #  xml.root {}
     #end

     (@data.search("//tr")).each do |tr|

       tds = tr.search("//td")
       #=======================================================================
       # fieldnumber
       fnum = tds[0]
       #=======================================================================
       # field description and label
       fdesc = tds[1]
       #=======================================================================
       ftype = tds[2]
       if ftype != nil
         types = ftype.search("//li")
         #=====================================================================
         # 1. Field type
         type = t_t(types[0])
         #=====================================================================
         # 2. Data type
         format = t_t(types[1])
         if format != nil then
           format = to_name(format)
         else
           p "Data typ is nil"
         end
         #=====================================================================
         # 3. Group ID
         groupId = t_t(types[2])
         #=====================================================================
         # 4. Max occ.
         cardinality = t_t(types[3])
         #=====================================================================
         # 5. Detail level
         level = t_t(types[4])
         #=====================================================================
         # 6. Picklist code
         enumcode = t_t(types[5]).gsub("-", "_")
       else
         ftype = ""
       end
       #=======================================================================
       # Remarks, Picklist, Freetext template
       rem = t_t(tds[3])
       if type == "TEXT-TEMPL"
         rem_fields = rem.split("-")
       end
       #=======================================================================
       helptxt = tds[4]
       #=======================================================================
       shorthelp = tds[5]
       #=======================================================================
       txpath = t_t(tds[6])
       if txpath != nil then
         xpath = txpath.gsub("\n", "").gsub("><", "/").gsub("<", "/").gsub(">", "")
         xpatharray = xpath.split("/i5:")
         if xpatharray.last != nil then
           l = xpatharray.last.length
           if l >= 12 then
             if xpatharray.last[l-12..l] == "LOQUALIFIER/" then
               isnumrange = true
             end
           end

         end
       else
         p "xpath does not exist"
       end

       if type != nil then
         case type
           when "HEAD-1"
             label = t_h(fdesc.search("//strong"))
             name = to_name(label)
             @oht.sections[name] = Section.new(name, label, wrap(t_t(shorthelp), 80), level)
             @oht.section_keys << name
             last_used_section_name = name
             last_used_parent_type = "head1"
           when "HEAD-2"
             label = t_h(fdesc.search("//strong"))
             ssname = to_name(label)
             @oht.sections[last_used_section_name].subsections[ssname] = Section.new(ssname, label, wrap(t_t(shorthelp), 80), level)
             @oht.sections[last_used_section_name].subsection_keys << ssname
             last_used_subsection_name = ssname
             last_used_parent_type  = "head2"
           when "HEAD BLOCK"
             blocklabel = t_h(fdesc.search("//em"))
             blockname = to_name(blocklabel)
             block = Section.new(blockname, blocklabel, wrap(t_t(shorthelp), 80), level, cardinality)
             if last_used_parent_type != "headblock" then
               last_used_parent_type_for_block = last_used_parent_type
             end
             case last_used_parent_type_for_block
               when "head1"
                 @oht.sections[last_used_section_name].blocks[blockname] = block
                 @oht.sections[last_used_section_name].block_keys << blockname
                 last_used_parent_type_for_block = "head1"
                 last_used_block_name = blockname
               when "head2"
                 @oht.sections[last_used_section_name].subsections[last_used_subsection_name].blocks[blockname] = block
                 @oht.sections[last_used_section_name].subsections[last_used_subsection_name].block_keys << blockname
                 last_used_parent_type_for_block ="head2"
                 last_used_block_name = blockname
             end
             last_used_parent_type = "headblock"
           # this is a field or
           else
             if ((last_used_type != "LIST-OPEN") and (last_used_type != "LIST-OPEN-SUP")) then
               field_label = t_h(fdesc.search("//p")).gsub(";", "")
               if field_label != last_field_label then
                 field_name = to_name(field_label)
                 if isnumrange then
                   type = TYPE_NUM_RANGE
                 end
                 if type[0..3] == "LIST" then
                   type = "LIST"
                 end
                 field = Field.new(field_name, field_label, format, type, wrap(t_t(shorthelp), 80), rem, xpath, enumcode, level)
                 Map_xpath_ohts[xpath] = field
                 #p "Map_xpath_ohts : key: " + xpath + " value: " + field.label
                 fieldkey = field_name + "-" + type
                 case last_used_parent_type
                   when "head1"
                     @oht.sections[last_used_section_name].fields[fieldkey] = field
                     @oht.sections[last_used_section_name].field_keys << fieldkey
                     if type == "TEXT-TEMPL" then
                       rem_fields.each do |fieldname|
                         pfname = fieldname.gsub(":", "").gsub("\n", "").lstrip.rstrip
                         fname = to_name(pfname)
                         fkey = fname + "-" + type
                         field = Field.new(fname, pfname, format, type, "", "", "", "", "3")
                         @oht.sections[last_used_section_name].fields[fkey] = field
                         @oht.sections[last_used_section_name].field_keys << fkey
                       end
                     end
                   when "head2"
                     @oht.sections[last_used_section_name].subsections[last_used_subsection_name].fields[fieldkey] = field
                     @oht.sections[last_used_section_name].subsections[last_used_subsection_name].field_keys << fieldkey
                     if type == "TEXT-TEMPL" then
                       rem_fields.each do |fieldname|
                         pfname = fieldname.gsub(":", "").gsub("\n", "").lstrip.rstrip
                         fname = to_name(pfname)
                         fkey = fname + "-" + type
                         field = Field.new(fname, pfname, "STRING/255", type, "", "", "", "", "3")
                         @oht.sections[last_used_section_name].subsections[last_used_subsection_name].fields[fkey] = field
                         @oht.sections[last_used_section_name].subsections[last_used_subsection_name].field_keys << fkey
                       end
                     end
                   when "headblock"
                     case last_used_parent_type_for_block
                       when "head1"
                         b1 = @oht.sections[last_used_section_name].blocks[last_used_block_name]
                         b1.fields[fieldkey] = field
                         b1.field_keys << fieldkey
                         if type == "TEXT-TEMPL" then
                           rem_fields.each do |fieldname|
                             pfname = fieldname.gsub(":", "").gsub("\n", "").lstrip.rstrip
                             fname = to_name(pfname)
                             fkey = fname + "-" + type
                             field = Field.new(fname, pfname, "STRING/255", type, "", "", "", "", "3")
                             b1.fields[fkey] = field
                             b1.field_keys << fkey
                           end
                         end
                       when "head2"
                         b2 = @oht.sections[last_used_section_name].subsections[last_used_subsection_name].blocks[last_used_block_name]
                         b2.fields[fieldkey] = field
                         b2.field_keys << fieldkey
                         if type == "TEXT-TEMPL" then
                           rem_fields.each do |fieldname|
                             pfname = fieldname.gsub(":", "").gsub("\n", "").lstrip.rstrip
                             fname = to_name(pfname)
                             fkey = fname + "-" + type
                             field = Field.new(fname, pfname, "STRING/255", type, "", "", "", "", "3")
                             b2.fields[fkey] = field
                             b2.field_keys << fkey
                           end
                         end
                       else
                         p last_used_parent_type_for_block
                         p "Last_used_parent_type_for_block is neither a head1 nor a head2"
                     end
                   else
                     p last_used_parent_type
                     p "last_used_parent_type is neither a head1 nor a head2, nor a head3"
                 end
               end

             end
             last_field_label = field_label
         end
         last_used_type = type
       end
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def read_content_2
     root = Node.new(@oht.name, @oht.title, "root", @oht.title, nil, 1)
     last_node = root
     (@data.search("//tr")).each do |tr|
       last_used_type = ""
       last_field_label = ""

       tds = tr.search("//td")
       #=======================================================================
       # fieldnumber
       fnum = tds[0]
       #=======================================================================
       # field description and label
       fdesc = tds[1]
       #=======================================================================
       ftype = tds[2]
       if ftype != nil
         types = ftype.search("//li")
         #=====================================================================
         # 1. Field type
         type = t_t(types[0])
         #=====================================================================
         # 2. Data type
         format = t_t(types[1])
         if format != nil then
           format = to_name(format)
         else
           p "Data typ is nil"
         end
         #=====================================================================
         # 3. Group ID
         groupId = t_t(types[2])
         #=====================================================================
         # 4. Max occ.
         cardinality = t_t(types[3])
         #=====================================================================
         # 5. Detail level
         level = t_t(types[4])
         #=====================================================================
         # 6. Picklist code
         enumcode = t_t(types[5]).gsub("-", "_")
       else
         ftype = ""
       end
       #=======================================================================
       # Remarks, Picklist, Freetext template
       rem = t_t(tds[3])
       if type == "TEXT-TEMPL"
         rem = rem.gsub("- ", "
     - ")
       end
       #=======================================================================
       helptxt = tds[4]
       #=======================================================================
       shorthelp = tds[5]
       #=======================================================================
       txpath = t_t(tds[6])
       if txpath != nil then
         xpath = txpath.gsub("\n", "").gsub("><", "/").gsub("<", "/").gsub(">", "")
         xpatharray = xpath.split("/i5:")
         if xpatharray.last != nil then
           l = xpatharray.last.length
           if l >= 12 then
             if xpatharray.last[l-12..l] == "LOQUALIFIER/" then
               isnumrange = true
             end
           end

         end
       else
         p "xpath does not exist"
       end

       if type != nil then
         case type[0..4]
           when "HEAD-"
             label = t_h(fdesc.search("//strong"))
             name = to_name(label)
             last_node = root.add(name, label, type, wrap(t_t(shorthelp), 80), level)
           when "HEAD BLOCK"
             label = t_h(fdesc.search("//em"))
             name = to_name(label)
             last_node.add(name, label, "headblock", wrap(t_t(shorthelp), 80), level)
           else
             if ((last_used_type != "LIST-OPEN") and (last_used_type != "LIST-OPEN-SUP")) then
               field_label = t_h(fdesc.search("//p")).gsub(";", "")
               if field_label != last_field_label then
                 field_name = to_name(field_label)
                 if isnumrange then
                   type = TYPE_NUM_RANGE
                 end
                 if type[0..3] == "LIST" then
                   type = "LIST"
                 end
                 field = Field.new(field_name, field_label, format, type, wrap(t_t(shorthelp), 80), rem, xpath, enumcode, level)
                 Map_xpath_ohts[xpath] = field
                 #p "Map_xpath_ohts : key: " + xpath + " value: " + field.label
                 fieldkey = field_name + "-" + type
                 last_node.fields << field

               end
             end
             last_used_type = type
             last_field_label = field_label
         end
       end
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def to_XML
     builder = Nokogiri::XML::Builder.new do |xml|
       xml.root {}
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def t_h(element)
     if !element.nil? then
       clean(element.inner_html)
     else
       ""
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def t_t(element)
     if !element.nil? then
       clean(element.inner_text)
     else
       ""
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def clean(astring)
     if !astring.nil? then
       astring.gsub(/\r\n/, ' ').gsub(/\t/, '').gsub(/&nbsp;/, ' ')
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def unescape(astring)
     if !astring.nil? then
       CGI.unescapeHTML(astring)
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate(filename)

     File.open(filename, 'w') do |f|
       p "Generating : " + @oht.name
       gen_header(f)
       generate_list_section(f)
       generate_section_type_definitions(f)
       f.puts ""
       f.puts "struct MerkmalsDef:"
       f.puts "    " + @oht.name.downcase + " " + @oht.name + " label <\"" + @oht.title + "\">"
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_inline(filename, verbous=false)
     if File.file? filename then
       filename = filename.gsub(".csv", "_2.csv")
     end
     File.open(filename, 'w') do |f|
       p "Generating : " + @oht.name
       if !@@basetypes.include? TYPE_NUM_RANGE
       then
         @@basetypes << TYPE_NUM_RANGE
       end
       generate_list_section_inline(f, verbous)
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_list_section(f)
     @oht.section_keys.each do |ks|
       s = @oht.sections[ks]
       f.puts "  //"
       f.puts "  // " + s.label
       f.puts "  //"
       f.puts "  " + s.name.downcase + "  MD_" + s.name
       f.puts "      label <\"" + s.label + "\">"
       f.puts "      \"" + s.desc + "\""
       f.puts ""
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_list_section_inline(f, verbous=true)
     fnum = 26
     if verbous then
       sep = SEPARATOR
     else
       sep = SEPARATOR
     end
     if !verbous then
       f.puts "<ICSneu ID>" + sep + "<ICSalt MD>" + sep + "<ICSalt ID>" + sep + "<ICSalt UMD DESC>" + sep*11 + "<OHT LEVEL>" + sep + "<TO BE SEARCH>" + sep + "<MANDATORY>" + sep + "<IS NEW>" + sep + "<EXAMPLE>" + sep + "<REMARKS>" + sep + "<XPATH>"
       f.puts "1;;;;SECTION;ADMINISTRATIVE DATA;;;;;;;;;1;;;;;;
2;;;;;FIELD TEXT;Record ID[Record ID];;;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/documentReferencePK/uuid
3;;;;;FIELD TEXT;Submission substance ID[Submission substance ID];;;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/ownerRef
4;;;;;FIELD TEXT;Record identifier[Record identifier];;;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/name
5;;;;;TABLE;Modification historyModification history;;;;;;;;1;;;;;;
6;;;;;;FIELD TEXT;Date[Date];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/modificationHistory/modifications/date
7;;;;;;FIELD STRING-255;Author[Author];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/modificationHistory/modifications/modificationBy
8;;;;;;FIELD STRING-255;Remarks[Remarks];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/modificationHistory/modifications/comment
9;;;;;;FIELD DATA PROTECTION;Flags[Flags];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection
10;;;;;;FIELD LIST;Confidentiality flag[Confidentiality flag];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection/confidentiality
11;;;;;;FIELD TEXT;Justification for confidentiality[Justification for confidentiality];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection/justification
12;;;;;;FIELD LIST;Regulatory purpose[Regulatory purpose];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection/regulatoryPurposes[          ]/value
13;;;;;;FIELD OTHERTEXT;Regulatory purpose[no label];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection/regulatoryPurposes[          ]/otherValue
14;;;;;;FIELD LIST;Purpose flag[Purpose flag];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/purposeFlag
15;;;;;;FIELD CHECKBOX;Robust study summary[Robust study summary];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/robustStudy
16;;;;;;FIELD CHECKBOX;Used for classification[Used for classification];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/usedForClassification
17;;;;;;FIELD CHECKBOX;Used for MSDS[Used for MSDS];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/usedForMSDS
18;;;;;;FIELD LIST;Data waiving[Data waiving];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataWaiving/value
19;;;;;;FIELD TEXTAREA;Justification for data waiving[Justification for data waiving];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataWaivingJustification
20;;;;;;FIELD LIST;Study result type[Study result type];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/studyResultType/value
21;;;;;;FIELD OTHERTEXT;Study result type[no label];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/studyResultType/otherValue
22;;;;;;FIELD TEXT;Study period[Study period];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/studyPeriod
23;;;;;;FIELD LIST;Reliability[Reliability];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/reliability/value
24;;;;;;FIELD OTHERTEXT;Reliability[no label];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/reliability/otherValue
25;;;;;;FIELD TEXTAREA;Rationale for reliability incl. deficiencies[Rationale for reliability incl. deficiencies];;;;;;;1;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/rationalReliability"
     else
       f.puts "1;SECTION;ADMINISTRATIVE DATA;;desc :  
2;;FIELD TEXT;Record ID[Record ID];;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/documentReferencePK/uuid
;;;desc : UUID (Universal Unique ID) generated by the system. This is a worldwide unique number allocated when a record is created. It cannot be modified and will follow the object during all its life time.
3;;FIELD TEXT;Submission substance ID[Submission substance ID];;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/ownerRef
;;;desc : The unique ID(s) of the chemical substance to which this submission, i.e. data set, is associated. System-generated display of relevant (e.g. first three) substance identifiers indicated in the data set definition. Read-only.
4;;FIELD TEXT;Record identifier[Record identifier];;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/name
;;;desc : Text-type identification of a record for use in a record navigator.
5;;TABLE;Modification history
;;;desc : Heading of field block 'Modification history'
6;;;FIELD TEXT;Date[Date];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/modificationHistory/modifications/date
;;;;desc : A system-generated date representing the date a record was created or modified. Read-only field.
7;;;FIELD STRING-255;Author[Author];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/modificationHistory/modifications/modificationBy
;;;;desc : Some ID of IUCLID user who created or modified the record. System generated (based on login ID of the user).
8;;;FIELD STRING-255;Remarks[Remarks];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/modificationHistory/modifications/comment
;;;;desc : Remarks on Tracking of record creation and update.
9;;;FIELD DATA PROTECTION;Flags[Flags];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection
;;;;desc :  
10;;;FIELD LIST;Confidentiality flag[Confidentiality flag];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection/confidentiality
;;;;desc : Flag for indicating either one of the following reasons of confidentiality: (i) CBI (confidential business information): The data must not be provided to other companies or disseminated to the public. (ii) IP (intellectual property): The data should only be provided to other companies when they are trusted (e.g. consortia or with letter of access); the data must not be disseminated to the public. (iii) no PA (not public available): The data can be provided to other companies, but must not be disseminated to the public.
;;;;litteral : CBI (confidential business information)
;;;;litteral :  IP (intellectual property)
;;;;litteral : no PA (not public available)
11;;;FIELD TEXT;Justification for confidentiality;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection/justification
;;;;desc : Justification for confidentiality.
12;;;FIELD LIST;Regulatory purpose[Regulatory purpose];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection/regulatoryPurposes[          ]/value
;;;;desc : Indication of the regulatory or other programme for which the data are used.
;;;;litteral :  EU: BPD
;;;;litteral :  EU: PPP
;;;;litteral :  EU: REACH
;;;;litteral :  CA: CEPA
;;;;litteral :  CA: PCPA
;;;;litteral :  JP: CSCL
;;;;litteral :  OECD: HPVC
;;;;litteral :  US: EPA HPVC
;;;;litteral :  US: FIFRA
;;;;litteral :  US: TSCA
;;;;litteral : other:Remarks:Actually, this is a multiple-choice list where items can be selected arbitrarily but each item can only be selected once.
13;;;FIELD OTHERTEXT;Regulatory purpose[no label];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataProtection/regulatoryPurposes[          ]/otherValue
;;;;desc :  
14;;;FIELD LIST;Purpose flag[Purpose flag];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/purposeFlag
;;;;desc : Flag for marking the purpose of a record in terms of use for hazard or risk assessment. Useful as filter for printing or exporting only records with a given flag or combination of flags.
;;;;litteral : key study
;;;;litteral : supporting study
;;;;litteral :  weight of evidence
15;;;FIELD CHECKBOX;Robust study summary[Robust study summary];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/robustStudy
;;;;desc : Flag for marking a robust study summary.
;;;;litteral : yes
;;;;litteral :  no
16;;;FIELD CHECKBOX;Used for classification;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/usedForClassification
;;;;desc : Flag for indicating that information of a record is used for the classification of that substance.
;;;;litteral : yes
;;;;litteral :  no
17;;;FIELD CHECKBOX;Used for MSDS[Used for MSDS];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/usedForMSDS
;;;;desc : Flag for indicating that information of a record is used for Material Safety Datasheet (MSDS).
;;;;litteral : yes
;;;;litteral :  no
18;;;FIELD LIST;Data waiving[Data waiving];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataWaiving/value
;;;;desc : Indicator of data waiving.
;;;;litteral : Picklist Values:study technically not feasible
;;;;litteral :  study scientifically unjustified
;;;;litteral :  exposure considerations
;;;;litteral :  other justification
19;;;FIELD TEXTAREA;Justification for data waiving;;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/dataWaivingJustification
;;;;desc : Justification and rationale for the data waiver.
20;;;FIELD LIST;Study resulttype[Study result type];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/studyResultType/value
;;;;desc : Indicator showing whether the study result represents a measured or an estimated value.
;;;;litteral :  experimental result
;;;;litteral :  experimental study planned
;;;;litteral :  estimated by calculation
;;;;litteral :  read-across based on grouping of substances (category approach)
;;;;litteral :  read-across from supporting substance (structural analogue or surrogate)
;;;;litteral :  (Q)SAR
;;;;litteral :  other:
;;;;litteral :  no data
21;;;FIELD OTHERTEXT;Study result type[no label];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/studyResultType/otherValue
;;;;desc :  
22;;;FIELD TEXT;Study period[Study period];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/studyPeriod
;;;;desc : Period during which the study was conducted, with start and end date.
23;;;FIELD LIST;Reliability[Reliability];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/reliability/value
;;;;desc : Indication of the adequacy of data at the discretion of the person preparing the study summary. Defined scores: 1 = Reliable without restrictions; 2 = Reliable with restrictions; 3 = Not reliable; 4 = Not assignable.
;;;;litteral :  1 (reliable without restriction)
;;;;litteral :  2 (reliable with restrictions)
;;;;litteral :  3 (not reliable)
;;;;litteral :  4 (not assignable)
;;;;litteral :  other:
24;;;FIELD OTHERTEXT;Reliability[no label];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/reliability/otherValue
;;;;desc :  
25;;;FIELD TEXTAREA;Rationale for reliability incl. deficiencies[Rationale for reliability incl. deficiencies];;;;;;eu.eca.iuclid.common.business.data.EndpointStudyRecord:/rationalReliability
;;;;desc : Comments about how the reliability of data was determined and other related remarks, including indication and interpretation of arguments defending a study or deficiencies if relevant for justifying whether study was downgraded or not."

     end
     @oht.section_keys.each do |ks|
       s = @oht.sections[ks]
       if verbous then
         f.puts fnum.to_s + sep + "SECTION" + sep + s.label
       else
         f.puts fnum.to_s + sep*4 + "SECTION" + sep + s.label + sep*9 + s.level + sep*6
       end
       fnum+=1
       if verbous then
         f.puts sep*2 + "desc : " + s.desc.gsub("\n     ", " ")
       end
       # Fields in a section
       fnum+=generate_list_fields_inline(f, s, "", fnum, verbous)
       s.block_keys.each do |keyblock|
         block = s.blocks[keyblock]
         nameblock = "BLOCK"
         if block.card != "1" then
           nameblock = "TABLE"
         end
         if verbous then
           f.puts fnum.to_s + sep*2 + nameblock + sep + block.label
         else
           f.puts fnum.to_s + sep*5 + nameblock + sep + block.label + sep*8 + block.level + sep*6
         end
         fnum+=1
         if verbous then
           f.puts sep*3 + "desc : " + block.desc.gsub("\n     ", " ")
         end
         fnum+=generate_list_fields_inline(f, block, sep, fnum, verbous)
       end
       s.subsection_keys.each do |keysubsection|
         ss = s.subsections[keysubsection]
         if verbous then
           f.puts fnum.to_s + sep*2 + "SUB-SECTION" + sep + ss.label
         else
           f.puts fnum.to_s + sep*5 + "SUB-SECTION" + sep + ss.label + sep*8 + ss.level + sep*6
         end
         if verbous then
           f.puts sep*3 +"desc : " + ss.desc.gsub("\n     ", " ")
         end
         fnum+=1
         fnum+=generate_list_fields_inline(f, ss, sep, fnum, verbous)
         ss.block_keys.each do |keyblock|
           block = ss.blocks[keyblock]
           nameblock = "BLOCK"
           if block.card != "1" then
             nameblock = "TABLE"
           end
           if verbous then
             f.puts fnum.to_s + sep*3 + nameblock + sep + block.label
           else
             f.puts fnum.to_s + sep*6 + nameblock + sep + block.label + sep*7 + block.level + sep*6
           end
           fnum+=1
           if verbous then
             f.puts sep*4 + "desc : " + block.desc.gsub("\n     ", " ")
           end
           fnum+=generate_list_fields_inline(f, block, sep*2, fnum, verbous)
         end
       end
     end
     if !verbous then
       if OHTs_ICSalt.keys.include? @oht.name.gsub("_SECTION", "") then
         f.puts sep*20
         f.puts sep + "No mapped ICSalt fields" + sep*18
         mdname = OHTs_ICSalt[@oht.name.gsub("_SECTION", "")]
         tmp_array = []
         Map_icsalt_oht_xpath[mdname].keys.each do |skey|
           if Map_icsalt_oht_xpath[mdname][skey] != "" then
             tmp_array << Float(Map_icsalt_oht_xpath[mdname][skey])
           end
         end
         tmp_array2 = []
         ICSalt_MD[mdname].keys.each do |v|
           if !tmp_array.include? v then
             tmp_array2 << v
           end
         end
         tmp_array2.sort.each do |i|
           f.puts sep + mdname + sep + i.to_s + sep + ICSalt_MD[mdname][i][2] + sep*17
         end

       end
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_section_type_definitions(f)
     @oht.section_keys.each do |sectionkey|
       s = @oht.sections[sectionkey]
       f.puts ""
       f.puts ""
       f.puts "//=============================================================================="
       f.puts "// Type definition of the section : " + s.label
       f.puts "//=============================================================================="
       f.puts "struct MD_" + s.name
       f.puts "       label <\"" + s.label + "\"> :"
       f.puts ""

       # Fields in a section
       generate_list_fields(f, s, "  ")

       # Blocks in a section
       generate_list_blocks(f, s, "  ")


       # Subsections in a section
       generate_list_subsections(f, s)

     end
     @oht.section_keys.each do |sectionkey|
       s = @oht.sections[sectionkey]
       generate_subsection_definitions(f, s)
     end
     @oht.section_keys.each do |sectionkey|
       s = @oht.sections[sectionkey]
       generate_block_definitions(f, s)
     end

   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_list_subsections(f, s)
     s.subsection_keys.each do |keysubsection|
       ss = s.subsections[keysubsection]
       f.puts "  " + ss.name.downcase + "  MD_" + ss.name
       f.puts "      label <\"" + ss.label + "\">"
       f.puts "      \"" + ss.desc + "\""
       f.puts ""
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_list_blocks(f, s, tab)
     s.block_keys.each do |keyblock|
       block = s.blocks[keyblock]
       if block.card != "1" then
         ca = " [0.." + block.card + "]"
       else
         ca = ""
       end
       f.puts tab + block.name.downcase + "  MD_" + block.name + ca
       f.puts tab + "   label <\"" + block.label + "\">"
       f.puts tab + "   \"" + block.desc + "\""
       f.puts ""
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_list_fields_inline(f, struct, tab, fnum, verbous=true)
     s = SEPARATOR
     nf = 0
     struct.field_keys.each do |fieldkey|
       field = struct.fields[fieldkey]
       nf+=1
       if !@@basetypes.include? field.type
       then
         @@basetypes << field.type
       end
       if field.enumcode != "[N/A]"
       then
         fieldtype = "Enum_" + field.enumcode
         if !@@enumerations.has_key? field.enumcode
         then
           @@enumerations[field.enumcode] = field.rem.gsub("Picklist Values:", "").split("||")
         end
       else
         fieldtype = "BT_" + field.type
       end
       if verbous then
         f.puts fnum.to_s + s + tab + s + "FIELD " + field.oht_format + s + field.label + (s*8)[0..6-tab.length] + field.xpath
         f.puts tab + s*3 + "desc : " + field.desc.gsub("\n     ", " ")
       else


         #-------------------------------------------------------------------------------------------------------------
         #-------------------------------------------------------------------------------------------------------------
         # logic that put the information of the mapping project in the csv file
         mdn = get_icsalt_name(field)
         mdn1 = OHTs_ICSalt[@oht.name.gsub("_SECTION", "")]
         p mdn
         p mdn1
         if (mdn != "") and (mdn != nil) then
           if  Map_icsalt_oht_xpath.has_key? mdn then
             num = Map_icsalt_oht_xpath[mdn][field.xpath]
           else
             num = ""
           end
         else
           num = ""
         end
         #TODO this ist num == nil should be checked elsewere
         if num == nil then
           num = ""
         end
         um = ""
         if num != "" then
           if ICSalt_MD.has_key? mdn then
             if ICSalt_MD[mdn].has_key? Float(num) then
               um = ICSalt_MD[mdn][Float(num)][2]
             end
           else
             p "ICSalt_MD has no key : " + mdn
           end
         else
           mdn == ""
         end
         f.puts fnum.to_s + s + mdn + s + num + s + um + s*2 + tab + "FIELD " + field.oht_format + s + field.label + (s*8)[0..6-tab.length] + s + field.level + s*6 + field.xpath
         #-------------------------------------------------------------------------------------------------------------
         #-------------------------------------------------------------------------------------------------------------


       end
       if verbous then
         if field.enumcode != "[N/A]" then
           @@enumerations[field.enumcode].each do |litteral|
             f.puts tab + s*3 + "litteral : " + litteral
           end
         end
         if field.oht_format == "TEXT-TEMPL"
           f.puts tab + s*3 + field.rem.gsub("      - ", tab + s*3 + "   - ")
         end
       end
       fnum+=1
     end
     return nf
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_list_fields(f, struct, tab)
     struct.field_keys.each do |fieldkey|
       field = struct.fields[fieldkey]
       if !@@basetypes.include? field.type
       then
         @@basetypes << field.type
       end
       if field.oht_format != TYPE_NUM_RANGE then
         if field.enumcode != "[N/A]"
         then
           fieldtype = "Enum_" + field.enumcode
           if !@@enumerations.has_key? field.enumcode
           then
             @@enumerations[field.enumcode] = field.rem.gsub("Picklist Values:", "").split("||")
           end
         else
           fieldtype = "BT_" + field.type
         end
       else
         fieldtype = "BT_" + TYPE_NUM_RANGE
       end

       f.puts tab + field.name.downcase + "  " + fieldtype
       f.puts tab + "  label <\"" + field.label + "\">"
       description = tab + "  \"" + field.desc
       if field.oht_format == "TEXT-TEMPL"
         description = description + "

         " + field.rem
       end
       description = description + "\""
       f.puts description
       f.puts tab + "  @ xpath = \"" + field.xpath + "\""
       f.puts ""
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def get_oht_name(field)
     OHTHandler.get_md_from_xpath(field.xpath)
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def get_icsalt_name(field)
     oht_name = get_oht_name(field)
     if OHTs_ICSalt.has_key? oht_name
       OHTs_ICSalt[oht_name]
     else
       ""
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_subsection_definitions(f, s)
     s.subsection_keys.each do |subsectionkey|
       ss = s.subsections[subsectionkey]
       f.puts ""
       f.puts ""
       f.puts "//=============================================================================="
       f.puts "// Section :" + s.label
       f.puts "// Type definition of the subsection : " + ss.label
       f.puts "//=============================================================================="
       f.puts "struct MD_" + ss.name
       f.puts "       label <\"" + ss.label + "\"> :"
       f.puts ""

       # Fields in a subsection
       generate_list_fields(f, ss, "  ")

       # Blocks in a subsection
       generate_list_blocks(f, ss, "  ")
     end
     s.subsection_keys.each do |subsectionkey|
       ss = s.subsections[subsectionkey]
       generate_block_definitions(f, ss)
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def generate_block_definitions(f, s)
     s.block_keys.each do |blockkey|
       b = s.blocks[blockkey]
       f.puts ""
       f.puts ""
       f.puts "//=============================================================================="
       f.puts "// " + s.label
       f.puts "// Type definition of the block : " + b.label
       f.puts "//=============================================================================="
       f.puts "struct MD_" + b.name
       f.puts "       label <\"" + b.label + "\"> :"
       f.puts ""

       # Fields in a block
       generate_list_fields(f, b, "  ")
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def gen_header(f)
     f.puts @oht.name
     f.puts ""
     f.puts "import \"imports/E.faktdaten\"    // Aufzaehlung Typen"
     f.puts "import \"imports/BT.faktdaten\"   // Basis Typen"
     #        f.puts "import \"imports/U.faktdaten\"    // Einheit Typen"
     #        f.puts "import \"imports/FBT.faktdaten\"  // Fachliche Typen"
     #        f.puts "import \"imports/MD.faktdaten\"   // Merkmalsdefinitionstypen"
     f.puts ""
     f.puts "////////////////////////////////////////////////////////////////////////////////"
     f.puts "//"
     f.puts "//  Merkmalsdefinition:" + @oht.title
     f.puts "//"
     f.puts "////////////////////////////////////////////////////////////////////////////////"
     f.puts "struct " + @oht.name + " :"
     f.puts "     \"" + @oht.title + "\""
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def wrap(str, max_size)
     all = []
     line = ''
     for l in str.split
       if (line+l).length >= max_size
         all.push(line)
         line = ''
       end
       line += line == '' ? l : ' ' + l
     end
     all.push(line).join("\n     ")
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def to_name (astring)
     if astring != nil then
       if astring.length > 0
         # if the first letter is a number a "_" is put before
         if astring[0].chr =~ /\d/ then
           astring = "_" + astring
         end
       end
       astring.gsub(" ", "_").gsub(",", "").gsub("'", "_").gsub(".", "").gsub("(", "").gsub(")", "").gsub("%", "Pourcentage").gsub("-", "_").gsub("#", "x").gsub("/", "_").gsub("&sup", "_").gsub(";", "").gsub(":", "").gsub("&degc", "degree_Celsius")
     else
       "The name of the field is nil"
     end
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def self.bts
     @@basetypes
   end

   # --------------------------------------------------------------------------
   #
   # --------------------------------------------------------------------------
   def self.enums
     @@enumerations
   end

 end
 # end of class


 # ---------------------------------------------------------------------------------------
 # Return the name of the Merkmal Definition contains in the Xpath expression
 # ---------------------------------------------------------------------------------------
 def get_md_from_xpath(xpath)
   if (xpath != nil) or (xpath != "") then
     a = xpath.split("/i5:")
     if a.size >= 4 then
       a[3]
     else
       puts "no md could be found for the xpath " + xpath
     end
   else
     puts "The parameter xpath can not be nil or an empty string."
   end
 end

 # ---------------------------------------------------------------------------------------
 # By taking als input the OHT Templates 1 to 89 following are generated:
 #  - faktendaten (DSL)
 #  - Excel csv file (for the documentation)
 #  - Excel csf file for the MD-mapping
 # ---------------------------------------------------------------------------------------
 def read_all_ohts
   p ""
   p "========================================================================================="
   p "Generation of all OHTs Templates"
   result = []
   for i in 4..100 do
     if i > 0 and i < 10 then
       a = "0" + i.to_s
     else
       a =  i.to_s
     end
     m = OHTParser.new(PATH_TO_HTML + "ch" + a + ".html")
     result << m
   end
   result
 end

 # ---------------------------------------------------------------------------------------
 # By taking als input the OHT Templates 1 to 89 following are generated:
 #  - faktendaten (DSL)
 #  - Excel csv file (for the documentation)
 #  - Excel csf file for the MD-mapping
 # ---------------------------------------------------------------------------------------
 def generate_all_ohts (ohts)
   p ""
   p "========================================================================================="
   p "Generation of all OHTs Templates"
   ohts.each do |m|
     m.generate(PATH_TO_GEN + m.oht.name + ".faktdaten")
     m.generate_inline(PATH_TO_GEN + m.oht.name + "_doc.csv", true)
     m.generate_inline(PATH_TO_GEN + m.oht.name + ".csv", false)
   end

   if !File.directory? PATH_TO_GEN + "imports"
   then
     Dir.mkdir PATH_TO_GEN + "imports"
   end

   File.open(PATH_TO_GEN + "imports/BT.faktdaten", 'w') do |f|
     f.puts "BT"
     f.puts ""
     OHTParser.bts.each do |bt|
       f.puts "struct BT_" + bt + " :"
       f.puts ""
     end
   end

   File.open(PATH_TO_GEN + "imports/E.faktdaten", 'w') do |f|
     f.puts "E"
     f.puts ""
     OHTParser.enums.keys.each do |e|
       f.puts "struct Enum_" + e + " :"
       OHTParser.enums[e].each do |litteral|
         f.puts "       // " + litteral
       end
       f.puts ""
     end
   end

 end

 # ---------------------------------------------------------------------------------------
 #
 # ---------------------------------------------------------------------------------------
 def print_mapping_results
   p "========================================================================================================"
   p "Print mapping results"
   open("daten/xpath_all.csv", 'w') do |ff|

     Map_icsalt_oht_xpath.keys.each do |md|
       Map_icsalt_oht_xpath[md].keys.each do |k|
         if Map_xpath_ohts.has_key? k then
           f = Map_xpath_ohts[k]
           a = f.xpath.split("/i5:")
           a.slice!(0..3)
           da = ""
           a.each do |p|
             da = da + p + "/"
           end
           ff << da + ";" + ICSalt_MD[md][Float(Map_icsalt_oht_xpath[md][k])][0] + ";" + ICSalt_MD[md][Float(Map_icsalt_oht_xpath[md][k])][2] + "\n"
         else
           #p k + ";" + Map_icsalt_oht_xpath[md][k]
         end
       end
     end
   end
 end

 # ---------------------------------------------------------------------------------------
 #
 # ---------------------------------------------------------------------------------------
 def print_ICSalt_OHTs
   p ""
   p "=========================================================================================="
   p "Print the map from the mapping project"
   ICSalt_OHTs.keys.each do |key|
     p "ICSalt_OHTs[ \"" + key + "\" ] = \"" + ICSalt_OHTs[key]
   end

 end

 # ---------------------------------------------------------------------------------------
 # From the ICSalt Untermerkmalen (csv file exported from the ICSalt DB) a map is build
 # ---------------------------------------------------------------------------------------
 def generate_ics_alt
   p ""
   p "========================================================================================"
   p "Generation of ICSalt Merkmalen"
   if !File.directory? PATH_TO_ICSALT_GEN
   then
     Dir.mkdir PATH_TO_ICSALT_GEN
   end

   ICSalt_MD.each do |k, v|
     filename = PATH_TO_ICSALT_GEN + k + ".csv"
     File.open(filename, 'w') do |f|
       p "Generating " + filename
       v.keys.sort.each do |z|
         if v[z][1] == "0" then
           f.puts v[z][0].to_s + ";;" + v[z][2].to_s
         else
           f.puts ";" + v[z][0].to_s + ";" + v[z][2].to_s
         end

       end
     end
   end
 end


 module_function :print_mapping_results
 module_function :print_ICSalt_OHTs
 module_function :generate_ics_alt
 module_function :generate_all_ohts
 module_function :read_all_ohts
 module_function :get_md_from_xpath

 ohts = read_all_ohts
 generate_all_ohts ohts
 #print_mapping_results
 #print_ICSalt_OHTs
end

