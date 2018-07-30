$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..'))

require 'puppet/provider/elastic_rest'

require 'puppet_x/elastic/deep_to_s'

Puppet::Type.type(:elasticsearch_document).provide(
  :ruby,
  :parent => Puppet::Provider::ElasticREST,
  #:discrete_resource_creation => true,
  :api_resource_style => :bare,
  :api_uri => :path.to_s,
  :metadata => :content,
  :metadata_pipeline => [
    lambda { |data| Puppet_X::Elastic.deep_to_s data }
  ]
) do
  desc 'A REST API based provider to manage Elasticsearch documents.'

  mk_resource_methods
end
