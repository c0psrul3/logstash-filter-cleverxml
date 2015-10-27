# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# XML filter. Takes a field that contains XML and expands it into
# an actual datastructure.
class LogStash::Filters::Cleverxml < LogStash::Filters::Base

  config_name "cleverxml"

  # Config for xml to hash is:
  #
  #     source => source_field
  #
  # For example, if you have the whole xml document in your @message field:
  #
  #     filter {
  #       xml {
  #         source => "message"
  #       }
  #     }
  #
  # The above would parse the xml from the @message field
  config :source, :validate => :string

  # Define target for placing the data
  #
  # for example if you want the data to be put in the 'doc' field:
  #
  #     filter {
  #       xml {
  #         target => "doc"
  #       }
  #     }
  #
  # XML in the value of the source field will be expanded into a
  # datastructure in the "target" field.
  # Note: if the "target" field already exists, it will be overridden
  # Required
  # If target is not defined and store_xml is set to "true", the output
  # will be written to the root of the event
  config :target, :validate => :string

  # xpath will additionally select string values (.to_s on whatever is selected)
  # from parsed XML (using each source field defined using the method above)
  # and place those values in the destination fields. Configuration:
  #
  # xpath => [ "xpath-syntax", "destination-field" ]
  #
  # Values returned by XPath parsring from xpath-synatx will be put in the
  # destination field. Multiple values returned will be pushed onto the
  # destination field as an array. As such, multiple matches across
  # multiple source fields will produce duplicate entries in the field
  #
  # More on xpath: http://www.w3schools.com/xpath/
  #
  # The xpath functions are particularly powerful:
  # http://www.w3schools.com/xpath/xpath_functions.asp
  #
  config :xpath, :validate => :hash, :default => {}

  # By default the filter will store the whole parsed xml in the destination
  # field as described above. Setting this to false will prevent that. 
  config :store_xml, :validate => :boolean, :default => true
  
   
  # By default XmlSimple will return an array for each element, even if there is
  # only one value, if you set this option to "false" it will return an array only
  # if there is more than one value
  # Note: if store_xml is set to "true" and target is not defined, the elements will
  # written as array to the root of the message, if you want the elements to be
  # written to the root of the message as single fields set force_array to "true"
  config :force_array, :validate => :boolean, :default => false
  
  public
  def register
    require "nokogiri"
    require "xmlsimple"

  end # def register

  public
  def filter(event)
    return unless filter?(event)
    matched = false

    @logger.debug("Running xml filter", :event => event)

    return unless event.include?(@source)

    value = event[@source]

    if value.is_a?(Array) && value.length > 1
      @logger.warn("XML filter only works on fields of length 1",
                   :source => @source, :value => value)
      return
    end

    # Do nothing with an empty string.
    return if value.strip.length == 0

    if @xpath
      begin
        doc = Nokogiri::XML(value)
      rescue => e
        event.tag("_xmlparsefailure")
        @logger.warn("Trouble parsing xml", :source => @source, :value => value,
                     :exception => e, :backtrace => e.backtrace)
        return
      end

      @xpath.each do |xpath_src, xpath_dest|
        nodeset = doc.xpath(xpath_src)

        # If asking xpath for a String, like "name(/*)", we get back a
        # String instead of a NodeSet.  We normalize that here.
        normalized_nodeset = nodeset.kind_of?(Nokogiri::XML::NodeSet) ? nodeset : [nodeset]

        normalized_nodeset.each do |value|
          # some XPath functions return empty arrays as string
          if value.is_a?(Array)
            return if value.length == 0
          end

          unless value.nil?
            matched = true
            event[xpath_dest] ||= []
            event[xpath_dest] << value.to_s
          end
        end # XPath.each
      end # @xpath.each
    end # if @xpath

    if @target.nil?
        # Default is to write to the root of the event.
        dest = event.to_hash
      else
        dest = event[@target]
    end
    
    if @store_xml
      begin
        if dest.nil?
          dest = XmlSimple.xml_in(value,{'ForceArray' => @force_array, 'SuppressEmpty' => true})
	  event[@target] = dest
	else
          dest.merge!(XmlSimple.xml_in(value,{'ForceArray' => @force_array, 'SuppressEmpty' => true}))
       	end
	
	matched = true
      rescue => e
        event.tag("_xmlparsefailure")
        @logger.warn("Trouble parsing xml with XmlSimple", :source => @source,
                     :value => value, :exception => e, :backtrace => e.backtrace)
        return
      end
    end # if @store_xml

    filter_matched(event) if matched
    @logger.debug("Event after xml filter", :event => event)
  end # def filter
end # class LogStash::Filters::Xml

