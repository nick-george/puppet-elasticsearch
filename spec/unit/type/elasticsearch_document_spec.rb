require_relative '../../helpers/unit/type/elasticsearch_rest_shared_examples'

describe Puppet::Type.type(:elasticsearch_document) do
  let(:resource_name) { 'a/b/c' }

  include_examples 'REST API types', 'document', :content

  describe 'document attribute validation' do
    it 'should have a source parameter' do
      expect(described_class.attrtype(:source)).to eq(:param)
    end

    describe 'content and source validation' do
      it 'should require either "content" or "source"' do
        expect do
          described_class.new(
            :name => resource_name,
            :ensure => :present
          )
        end.to raise_error(Puppet::Error, /content.*or.*source.*required/)
      end

      it 'should fail with both defined' do
        expect do
          described_class.new(
            :name => resource_name,
            :content => {},
            :source => 'puppet:///example.json'
          )
        end.to raise_error(Puppet::Error, /simultaneous/)
      end

      it 'should parse source paths into the content property' do
        file_stub = 'foo'
        [
          Puppet::FileServing::Metadata,
          Puppet::FileServing::Content
        ].each do |klass|
          allow(klass).to receive(:indirection)
            .and_return(Object)
        end
        allow(Object).to receive(:find)
          .and_return(file_stub)
        allow(file_stub).to receive(:content)
          .and_return('{"template":"foobar-*", "order": 1}')
        expect(described_class.new(
          :name => resource_name,
          :source => '/example.json'
        )[:content]).to include(
          'template' => 'foobar-*',
          'order' => 1
        )
      end
    end
  end # of describing when validing values

  describe 'insync?' do
    # Although users can pass the type a hash structure with any sort of values
    # - string, integer, or other native datatype - the Elasticsearch API
    # normalizes all values to strings. In order to verify that the type does
    # not incorrectly detect changes when values may be in string form, we take
    # an example document and force all values to strings to mimic what
    # Elasticsearch does.
    it 'is idempotent' do
      def deep_stringify(obj)
        if obj.is_a? Array
          obj.map { |element| deep_stringify(element) }
        elsif obj.is_a? Hash
          obj.merge(obj) { |_key, val| deep_stringify(val) }
        else
          obj.to_s
        end
      end
      json = JSON.parse(File.read('spec/fixtures/templates/post_6.0.json'))

      is_template = described_class.new(
        :name => resource_name,
        :ensure => 'present',
        :content => json
      ).property(:content)
      should_template = described_class.new(
        :name => resource_name,
        :ensure => 'present',
        :content => deep_stringify(json)
      ).property(:content).should

      expect(is_template.insync?(should_template)).to be_truthy
    end
  end
end # of describe Puppet::Type
