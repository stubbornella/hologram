require 'spec_helper'

describe Hologram::DocParser do

  let(:doc) do
<<-eos
/*doc
---
title: Some other style
name: otherStyle
category: Foo
---
Markdown stuff
*/
eos
  end

  let(:child_doc) do
<<-eos
/*doc
---
parent: button
name: otherStyle
title: Some other style
---
Markdown stuff
*/
eos
  end

  let(:multi_category_doc) do
    <<-eos
/*doc
---
title: Some other style
name: multi
category: Foo, Bar
---
Markdown stuff
*/
    eos
  end

  let(:source_path) { 'spec/fixtures/source' }
  let(:temp_doc) { File.join(source_path, 'components', 'button', 'skin', 'testSkin.css') }

  subject(:parser) { Hologram::DocParser.new('spec/fixtures/source') }

  context '#parse' do
    let(:result) { parser.parse }
    let(:pages) { result[0] }
    let(:output_files_by_category) { result[1] }

    it 'builds and returns a hash of pages and a hash of output_files_by_category' do
      expect(pages).to be_a Hash
      expect(output_files_by_category).to be_a Hash

    end

    context 'when the component has two categories' do
      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << multi_category_doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      before do
        parser.parse
      end

      it 'adds two categories to output_files_by_category' do
        expect(output_files_by_category).to eql({'Foo'=>'foo.html', 'Base CSS'=>'base_css.html', 'Bar'=>'bar.html'})
      end
    end

    context 'when an index page is specified' do
      subject(:parser) { Hologram::DocParser.new('spec/fixtures/source', 'foo') }

      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'uses that page as the index' do
        expect(pages['index.html'][:md]).to include 'Markdown stuff'
      end
    end

    context 'when the source is a parent doc' do
      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      it 'takes the category in a collection and treats them as the page names' do
        expect(pages.keys).to include 'foo.html'
      end
    end

    context 'when a source doc is a child' do
      around do |example|
        File.open(temp_doc, 'a+'){ |io| io << child_doc }
        example.run
        FileUtils.rm(temp_doc)
      end

      before do
        parser.parse
      end

      it 'appends the child doc to the category page' do
        expect(pages['base_css.html'][:md]).to include 'Some other style'
      end

      it 'assigns the child doc a deeper header' do
        expect(pages['base_css.html'][:md]).to include '<h2 id="otherStyle">Some other style</h2>'
      end
    end
  end
end
