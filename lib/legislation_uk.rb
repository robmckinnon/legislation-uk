require 'activesupport'
require 'morph'
require 'hpricot'
require 'open-uri'

module LegislationUK

  module Title
    def title
      contents_title.is_a?(String) ? contents_title.strip : contents_title.title.strip
    end
  end

  module ItemNumber
    def number
      contents_number
    end
  end

  class Legislation
    include Morph

    def self.open_uri uri
      open(uri).read
    end

    def title
      metadata.title
    end

    def parts
      contents ? contents.contents_parts : []
    end

    def opsi_url
      unless @opsi_url
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

          @opsi_url = url
        rescue Exception => e
          puts 'error retrieving: ' + search_url
          puts e.class.name
          puts e.to_s
        end
      end
      @opsi_url
    end
  end

  class ContentsPart
    include Morph
    include Title
    include ItemNumber
    def blocks
      contents_pblocks ? contents_pblocks : []
    end
  end

  class ContentsPblock
    include Morph
    include Title

    def sections
      contents_items
    end
  end

  class ContentsItem
    include Morph
    include Title
    include ItemNumber
  end
end


# See README for usage documentation.
module Legislation
  module UK
    VERSION = "0.0.2"

    def self.open_uri uri
      open(uri).read
    end

    def self.to_object xml
      xml.gsub!(' Type=',' TheType=')
      xml.gsub!('dc:type','dc:the_type')
      hash = Hash.from_xml(xml)
      namespace = LegislationUK
      Morph.from_hash(hash, namespace)
    end

    def self.find title, number=nil
      begin
        number_part = number ? "&number=#{number}" : ''
        search_url = "http://www.legislation.gov.uk/id?title=#{URI.escape(title)}#{number_part}"
        xml = Legislation::UK.open_uri(search_url)
        to_object(xml)
      rescue Exception => e
        puts 'error retrieving: ' + search_url
        puts e.class.name
        puts e.to_s
        raise e
        nil
      end
    end

    def self.find_uri title, number=nil
      legislation = find(title, number)
      if legislation
        legislation.document_uri
      else
        nil
      end
    end
  end
end
