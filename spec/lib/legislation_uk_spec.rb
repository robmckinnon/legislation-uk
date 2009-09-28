require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Legislation::UK do
  before(:all) do
    @title = 'Channel Tunnel Rail Link Act 1996'
    @number = '61'
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

      it 'should have blocks for each part' do
        @parts[0].blocks.size.should == 11
        @parts[1].blocks.size.should == 0
        @parts[2].blocks.size.should == 0
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

      it 'should have sections for first block' do
        @blocks[0].sections.size.should == 3
        @blocks[0].sections.first.number.should == '1'
        @blocks[0].sections.first.title.should == 'Construction and maintenance of scheduled works'
      end

      it 'should have legislation url' do
        @legislation.legislation_url.should == 'http://www.legislation.gov.uk/ukpga/1996/61'
      end

      it 'should have statuelaw url' do
        @legislation.statutelaw_url.should == 'http://www.statutelaw.gov.uk/documents/1996/61/ukpga/c61'
      end

      describe 'when asked for opsi url' do
        it 'should search legislation site' do
          expected_uri = 'http://search.opsi.gov.uk/search?q=Channel%20Tunnel%20Rail%20Link%20Act%201996&output=xml_no_dtd&client=opsisearch_semaphore&site=opsi_collection'
          LegislationUK::Legislation.should_receive(:open_uri).with(expected_uri).and_return fixture('opsi_search_result.xml')
          @legislation.opsi_url.should == 'http://www.opsi.gov.uk/acts/acts1996/ukpga_19960061_en_1'
        end
      end

    end

    describe "using title and chapter number" do
      it 'should search legislation site' do
        expected_uri = 'http://www.legislation.gov.uk/id?title=Channel%20Tunnel%20Rail%20Link%20Act%201996&number=61'
        Legislation::UK.should_receive(:open_uri).with(expected_uri).and_return fixture('legislation_contents.xml')
        Legislation::UK.find(@title, @number).legislation_url.should == 'http://www.legislation.gov.uk/ukpga/1996/61'
      end
    end

  end

end