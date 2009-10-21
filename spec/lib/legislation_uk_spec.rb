require 'rubygems'
require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Legislation::UK do

  describe 'when act has many parts' do
    before(:all) do
      @title = 'Channel Tunnel Rail Link Act 1996'
      @number = '61'
    end

    describe "when searching for legislation and socket error occurs" do
      before(:all) do
        Legislation::UK.should_receive(:open_uri).and_raise SocketError.new
      end
      it 'should return nil' do
        Legislation::UK.find(@title).should be_nil
      end
    end

    describe "when searching for legislation and Errno::ETIMEDOUT occurs" do
      before(:all) do
        Legislation::UK.should_receive(:open_uri).and_raise Errno::ETIMEDOUT.new
      end
      it 'should return nil' do
        Legislation::UK.find(@title).should be_nil
      end
    end

    describe "when searching for legislation" do
      before(:all) do
        Legislation::UK.should_receive(:open_uri).and_return fixture('legislation_contents.xml')
        @legislation = Legislation::UK.find(@title)
        @parts = @legislation.parts
        @blocks = @parts[0].blocks
      end

      it 'should return legislation object' do
        @legislation.should_not be_nil
        @legislation.class.name.should == 'LegislationUK::Legislation'
        @parts[0].class.name.should == 'LegislationUK::ContentsPart'
        @blocks[0].class.name.should == 'LegislationUK::ContentsPblock'
      end

      describe 'and legislation object is returned' do

        it 'should have a title' do
          @legislation.title.should == 'Channel Tunnel Rail Link Act 1996'
        end

        it 'should have contents parts' do
          @parts.size.should == 3
        end

        it 'should have a number for each part' do
          @parts[0].number.should == 'Part I'
          @parts[1].number.should == 'Part II'
          @parts[2].number.should == 'Part III'
        end

        it 'should have a title for each part' do
          @parts[0].title.class.name.should == 'String'
          @parts[0].title.should == 'The Channel Tunnel Rail Link'
          @parts[1].title.should == 'The A2 and M2 Improvement Works'
          @parts[2].title.should == 'Miscellaneous and General'
        end

        it 'should have a legislation_uri for each part' do
          @parts[0].legislation_uri.should == 'http://www.legislation.gov.uk/ukpga/1996/61/part/I'
          @parts[1].legislation_uri.should == 'http://www.legislation.gov.uk/ukpga/1996/61/part/II'
          @parts[2].legislation_uri.should == 'http://www.legislation.gov.uk/ukpga/1996/61/part/III'
        end

        it 'should have blocks for each part' do
          @parts[0].blocks.size.should == 11
          @parts[1].blocks.size.should == 0
          @parts[2].blocks.size.should == 0
        end

        it 'should have each part point back to legislation object' do
          @parts[0].legislation.should == @legislation
          @parts[1].legislation.should == @legislation
          @parts[2].legislation.should == @legislation
        end

        it 'should have title for each block' do
          @blocks[0].title.should == 'Works'
          @blocks[1].title.should == 'Land'
          @blocks[2].title.should == 'Planning and heritage'
          @blocks[3].title.should == 'Operation'
          @blocks[4].title.should == 'Application of railway legislation'
          @blocks[5].title.should == 'Functions of the Rail Regulator'
          @blocks[6].title.should == 'Competition'
          @blocks[7].title.should == 'Trees'
          @blocks[8].title.should == 'Noise'
          @blocks[9].title.should == 'Financial matters'
          @blocks[10].title.should == 'Miscellaneous and general'
        end

        it 'should have legislation_uri for a block' do
          @blocks[0].legislation_uri.should == 'http://www.legislation.gov.uk/ukpga/1996/61/part/I/crossheading/works'
        end

        it 'should have legislation_uri for a section' do
          @blocks[0].sections.first.legislation_uri.should == 'http://www.legislation.gov.uk/ukpga/1996/61/section/1'
        end

        it 'should have sections for each part containing section blocks' do
          @parts[0].sections.size.should == 44
          @parts[0].sections.last.number.should == '43'
          @parts[0].sections[42].number.should == '42A'
        end

        it 'should have sections for legislation' do
          @legislation.sections.size.should == 58
        end

        it 'should have sections for each part not containing section blocks' do
          @parts[1].sections.size.should == 3
          @parts[2].sections.size.should == 11
        end

        it 'should have sections for first block' do
          @blocks[0].sections.size.should == 3
          @blocks[0].sections.first.number.should == '1'
          @blocks[0].sections.first.title.should == 'Construction and maintenance of scheduled works'
        end

        it 'should have legislation url' do
          @legislation.legislation_uri.should == 'http://www.legislation.gov.uk/ukpga/1996/61'
        end

        it 'should have statuelaw url' do
          @legislation.statutelaw_uri.should == 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61'
        end

        it 'should have part for a section' do
          @legislation.sections.first.part.should == @parts[0]
        end

        describe 'when asked for opsi url' do
          it 'should search legislation site' do
            expected_uri = 'http://search.opsi.gov.uk/search?q=Channel%20Tunnel%20Rail%20Link%20Act%201996&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection'
            LegislationUK::Legislation.should_receive(:open_uri).with(expected_uri).and_return fixture('opsi_search_result.xml')
            @legislation.opsi_uri.should == 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1'
          end
        end

        describe 'when asked for opsi uri for a section' do

          describe 'when exception retrieving opsi uri' do
            it 'should return nil' do
              expected_uri = 'http://search.opsi.gov.uk/search?q=Channel%20Tunnel%20Rail%20Link%20Act%201996&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection'
              LegislationUK::Legislation.should_receive(:open_uri).with(expected_uri).exactly(3).times.and_raise SocketError.new

              @legislation.opsi_uri_for_section(1).should be_nil
              @legislation.section(1).opsi_uri.should be_nil
              @legislation.sections.first.opsi_uri.should be_nil

            end
          end

          it 'should return section uri' do
            expected_uri = 'http://search.opsi.gov.uk/search?q=Channel%20Tunnel%20Rail%20Link%20Act%201996&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection'
            LegislationUK::Legislation.should_receive(:open_uri).with(expected_uri).and_return fixture('opsi_search_result.xml')

            expected_uri = 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1'
            LegislationUK::Legislation.should_receive(:open_uri).with(expected_uri).and_return fixture('opsi_act_contents.htm')

            @legislation.opsi_uri_for_section(1).should == 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_2#pt1-pb1-l1g1'
            @legislation.section(1).opsi_uri.should == 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_2#pt1-pb1-l1g1'
            @legislation.sections.first.opsi_uri.should == 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_2#pt1-pb1-l1g1'
          end
        end

        describe 'when asked for statutelaw uri for a part' do
          it 'should return statutelaw uri' do
            @parts.first.statutelaw_uri.should == 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI'
          end
        end

        describe 'when asked for statutelaw uri for a section' do
          it 'should return statutelaw uri' do
            @legislation.section(1).statutelaw_uri.should == 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/1'
            @legislation.sections.first.statutelaw_uri.should == 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61/PartI/1'
          end
        end
      end

      describe "using title and chapter number" do
        it 'should search legislation site' do
          expected_uri = 'http://www.legislation.gov.uk/id?title=Channel%20Tunnel%20Rail%20Link%20Act%201996&number=61'
          Legislation::UK.should_receive(:open_uri).with(expected_uri).and_return fixture('legislation_contents.xml')
          Legislation::UK.find(@title, @number).legislation_uri.should == 'http://www.legislation.gov.uk/ukpga/1996/61'
        end
      end
    end
  end

  describe 'when act has one part and one section blocks' do
    before(:all) do
      @title = 'Railways Act 2005'
      @number = '14'
    end

    describe "when searching for legislation" do
      before(:all) do
        Legislation::UK.should_receive(:open_uri).and_return fixture('legislation_with_one_part_contents.xml')
        @legislation = Legislation::UK.find(@title)
      end

      it 'should have a parts list of size one' do
        @legislation.parts.size.should == 1
      end

      it 'should have a part with one block' do
        @legislation.parts.first.blocks.size.should == 1
      end

      it 'should have a part with a part number' do
        @legislation.parts.first.number.should == 'Part 6'
      end

      it 'should have a section block with one section' do
        @legislation.parts.first.blocks.first.sections.size.should == 1
      end

      it 'should have a part with one section' do
        @legislation.parts.first.sections.size.should == 1
      end
    end
  end

  describe 'when act has no parts' do
    before(:all) do
      @title = 'Law Commissions Act 1965'
      @number = '22'
    end

    describe "when searching for legislation" do
      before(:all) do
        Legislation::UK.should_receive(:open_uri).and_return fixture('legislation_without_parts_contents.xml')
        @legislation = Legislation::UK.find(@title)
      end

      it 'should have an empty parts list' do
        @legislation.parts.size.should == 0
      end

      it 'should have sections in a sections list' do
        @legislation.sections.size.should == 7
      end

      it 'should have legislation_uri for a section' do
        @legislation.sections.first.legislation_uri.should == 'http://www.legislation.gov.uk/ukpga/1965/22/section/1'
      end

      it 'should have title for a section' do
        @legislation.sections.first.title.should == 'The Law Commission'
      end

      it 'should have number for a section' do
        @legislation.sections.first.number.should == '1'
      end
    end
  end

end