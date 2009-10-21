require 'morph'
require 'hpricot'
require 'open-uri'

module LegislationUK

  module TitleHelper
    def title
      contents_title.is_a?(String) ? contents_title.strip : contents_title.title.strip
    end
  end

  module ItemNumberHelper
    def number
      if contents_number && contents_number.respond_to?(:strong)
        contents_number.strong
      else
        contents_number
      end
    end
  end

  module LegislationUriHelper
    def legislation_uri
      document_uri
    end
  end

  module Helper
    def return_values many
      if respond_to?(many)
        send(many) ? send(many) : []
      else
        one = many.to_s.singularize.to_sym
        if respond_to?(one)
          send(one) ? [send(one)] : []
        else
          []
        end
      end
    end
  end

  class Legislation
    include Morph
    include LegislationUriHelper

    def self.open_uri uri
      open(uri).read
    end

    def title
      metadata.title
    end

    def populate
      parts.each do |part|
        part.legislation = self
        part.sections.each do |section|
          section.part = part
        end
      end

      @sections_index = {}
      sections.each do |section|
        section.legislation = self
        @sections_index[section.number] = section
      end
    end

    def section section_number
      section_number = section_number.to_s unless section_number.is_a?(String)
      @sections_index[section_number]
    end

    def sections
      if !parts.empty?
        parts.collect(&:sections).flatten
      elsif respond_to?(:contents) && contents
        contents.sections
      else
        []
      end
    end

    def parts
      if respond_to?(:contents) && contents
        contents.parts
      else
        []
      end
    end

    def statutelaw_uri
      if legislation_uri[%r|http://www.legislation.gov.uk/(.+)/(\d\d\d\d)/(\d+)|]
        type = $1
        year = $2
        chapter = $3
        "http://www.statutelaw.gov.uk/documents/#{year}/#{chapter}/#{type}/c#{chapter}"
      else
        nil
      end
    end

    def opsi_uri
      unless @opsi_uri
        search_url = "http://search.opsi.gov.uk/search?q=#{URI.escape(title)}&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection"
        begin
          doc = Hpricot.XML Legislation.open_uri(search_url)
          url = nil

          (doc/'R/T').each do |result|
            unless url
              term = result.inner_text.gsub(/<[^>]+>/,'').strip
              url = result.at('../U/text()').to_s if(title == term || term.starts_with?(title))
            end
          end

          @opsi_uri = url
        rescue Exception => e
          puts "#{e.class.name} error retrieving: #{search_url}" if $debug
        end
      end
      @opsi_uri
    end

    def opsi_uri_for_section section_number
      if opsi_uri && !@opsi_sections
        section_number = section_number.to_s
        doc = Hpricot Legislation.open_uri(opsi_uri)

        (doc/'span[@class="LegDS LegContentsNo"]').each do |span|
          number_of_section = span.inner_text.chomp('.')
          if span.at('a')
            path = span.at('a')['href']
            base = opsi_uri[/^(.+\/)[^\/]+$/,1]
            section_title = span.next_sibling.inner_text

            @opsi_sections ||= {}
            @opsi_sections[number_of_section] = { :title => section_title, :opsi_uri => "#{base}#{path}"}
          else
            puts "cannot find opsi url for section #{number_of_section} of #{name}"
          end
        end
        @opsi_sections[section_number][:opsi_uri]
      elsif @opsi_sections
        if @opsi_sections[section_number]
          @opsi_sections[section_number][:opsi_uri]
        else
          puts "no opsi url for #{section_number}\n" + @opsi_sections.inspect + "\n\nno opsi url for #{section_number}\n"
          nil
        end
      else
        nil
      end
    end
  end

  class Contents
    include Morph
    include Helper

    def parts
      return_values :contents_parts
    end

    def sections
      return_values :contents_items
    end
  end

  class ContentsPart
    include Morph
    include Helper
    include TitleHelper
    include ItemNumberHelper
    include LegislationUriHelper

    attr_accessor :legislation

    def statutelaw_uri
      base = legislation.statutelaw_uri
      "#{base}/#{number.gsub(' ','')}"
    end

    def blocks
      return_values :contents_pblocks
    end

    def sections
      if blocks.empty?
        return_values :contents_items
      else
        blocks.collect(&:sections).flatten
      end
    end
  end

  class ContentsPblock
    include Morph
    include Helper
    include TitleHelper
    include LegislationUriHelper

    def sections
      return_values :contents_items
    end
  end

  class ContentsItem
    include Morph
    include TitleHelper
    include ItemNumberHelper
    include LegislationUriHelper

    attr_accessor :legislation, :part

    def opsi_uri
      @legislation.opsi_uri_for_section(number)
    end

    def statutelaw_uri
      if part && (base = part.statutelaw_uri)
        "#{base}/#{number}"
      else
        nil
      end
    end
  end
end


# See README for usage documentation.
module Legislation
  module UK
    VERSION = "0.0.5"

    def self.open_uri uri
      open(uri).read
    end

    def self.to_object xml
      xml.gsub!(' Type=',' TheType=')
      xml.gsub!(' type=',' thetype=')
      xml.gsub!('dc:type','dc:the_type')
      hash = Hash.from_xml(xml)
      namespace = LegislationUK
      legislation = Morph.from_hash(hash, namespace)
      legislation.populate
      legislation
    end

    def self.find title, number=nil
      number_part = number ? "&number=#{number}" : ''
      search_url = "http://www.legislation.gov.uk/id?title=#{URI.escape(title)}#{number_part}"
      begin
        xml = Legislation::UK.open_uri(search_url)
        to_object(xml)
      rescue Exception => e
        puts "#{e.class.name} error retrieving: #{search_url}" if $debug
        nil
      end
    end

  end
end
