# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/cleverxml"

describe LogStash::Filters::Cleverxml do

  describe "parse standard xml (Deprecated checks)" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "raw"
        target => "data"
      }
    }
    CONFIG

    sample("raw" => '<foo key="value"/>') do
      insist { subject["tags"] }.nil?
      insist { subject["data"]} == {"key" => "value"}
    end

    #From parse xml with array as a value
    sample("raw" => '<foo><key>value1</key><key>value2</key></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["data"]} == {"key" => ["value1", "value2"]}
    end

    #From parse xml with hash as a value
    sample("raw" => '<foo><key1><key2>value</key2></key1></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["data"]} == {"key1" => [{"key2" => ["value"]}]}
    end

    #From bad xml
    sample("raw" => '<foo /') do
      insist { subject["tags"] }.include?("_xmlparsefailure")
    end
  end

  describe "parse standard xml but do not store (Deprecated checks)" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "raw"
        target => "data"
        store_xml => false
      }
    }
    CONFIG

    sample("raw" => '<foo key="value"/>') do
      insist { subject["tags"] }.nil?
      insist { subject["data"]} == nil
    end
  end

  describe "parse xml and store values with xpath (Deprecated checks)" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "raw"
        target => "data"
        xpath => [ "/foo/key/text()", "xpath_field" ]
      }
    }
    CONFIG

    # Single value
    sample("raw" => '<foo><key>value</key></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["xpath_field"]} == ["value"]
    end

    #Multiple values
    sample("raw" => '<foo><key>value1</key><key>value2</key></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["xpath_field"]} == ["value1","value2"]
    end
  end

  ## New tests

  describe "parse standard xml" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "xmldata"
        target => "data"
      }
    }
    CONFIG

    sample("xmldata" => '<foo key="value"/>') do
      insist { subject["tags"] }.nil?
      insist { subject["data"]} == {"key" => "value"}
    end

    #From parse xml with array as a value
    sample("xmldata" => '<foo><key>value1</key><key>value2</key></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["data"]} == {"key" => ["value1", "value2"]}
    end

    #From parse xml with hash as a value
    sample("xmldata" => '<foo><key1><key2>value</key2></key1></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["data"]} == {"key1" => [{"key2" => ["value"]}]}
    end

    #From bad xml
    sample("xmldata" => '<foo /') do
      insist { subject["tags"] }.include?("_xmlparsefailure")
    end
  end

  describe "parse standard xml but do not store" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "xmldata"
        target => "data"
        store_xml => false
      }
    }
    CONFIG

    sample("xmldata" => '<foo key="value"/>') do
      insist { subject["tags"] }.nil?
      insist { subject["data"]} == nil
    end
  end

  describe "parse xml and store values with xpath" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "xmldata"
        target => "data"
        xpath => [ "/foo/key/text()", "xpath_field" ]
      }
    }
    CONFIG

    # Single value
    sample("xmldata" => '<foo><key>value</key></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["xpath_field"]} == ["value"]
    end

    #Multiple values
    sample("xmldata" => '<foo><key>value1</key><key>value2</key></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["xpath_field"]} == ["value1","value2"]
    end
  end

  describe "parse correctly non ascii content with xpath" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "xmldata"
        target => "data"
        xpath => [ "/foo/key/text()", "xpath_field" ]
      }
    }
    CONFIG

    # Single value
    sample("xmldata" => '<foo><key>Français</key></foo>') do
      insist { subject["tags"] }.nil?
      insist { subject["xpath_field"]} == ["Français"]
    end
  end

  describe "parse including namespaces" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "xmldata"
        xpath => [ "/foo/h:div", "xpath_field" ]
        remove_namespaces => false
      }
    }
    CONFIG

    # Single value
    sample("xmldata" => '<foo xmlns:h="http://www.w3.org/TR/html4/"><h:div>Content</h:div></foo>') do
      insist { subject["xpath_field"] } == ["<h:div>Content</h:div>"]
    end
  end

  describe "parse removing namespaces" do
    config <<-CONFIG
    filter {
      cleverxml {
        source => "xmldata"
        xpath => [ "/foo/div", "xpath_field" ]
        remove_namespaces => true
      }
    }
    CONFIG

    # Single value
    sample("xmldata" => '<foo xmlns:h="http://www.w3.org/TR/html4/"><h:div>Content</h:div></foo>') do
      insist { subject["xpath_field"] } == ["<div>Content</div>"]
    end
  end

end
