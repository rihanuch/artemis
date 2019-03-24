require 'test_helper'

describe Artemis::GraphQLEndpoint do
  after do
    Artemis::GraphQLEndpoint.const_get(:ENDPOINT_INSTANCES).delete 'github'
  end

  describe ".lookup" do
    it "raises an exception when the service is missing" do
      assert_raises Artemis::EndpointNotFound do
        Artemis::GraphQLEndpoint.lookup(:does_not_exit)
      end
    end
  end

  it "can register an endpoint" do
    endpoint = Artemis::GraphQLEndpoint.register!(:github, url: "https://api.github.com/graphql")

    assert_equal "https://api.github.com/graphql", endpoint.url
    assert_instance_of Artemis::Adapters::NetHttpAdapter, endpoint.connection # Not a fan of this test but for now
  end

  it "can look up a registered endpoint" do
    Artemis::GraphQLEndpoint.register!(:github, url: "https://api.github.com/graphql")

    endpoint = Artemis::GraphQLEndpoint.lookup(:github)

    assert_equal "https://api.github.com/graphql", endpoint.url
    assert_instance_of Artemis::Adapters::NetHttpAdapter, endpoint.connection # Not a fan of this test but for now

    # FIXME: This #schema method makes a network call.
    # expect(endpoint.schema).to eq(...)
  end

  it "can register an endpoint with options" do
    options = {
      adapter: :test,
      timeout: 10,
      # schema_path: nil,
      pool_size: 25,
    }

    endpoint = Artemis::GraphQLEndpoint.register!(:github, url: "https://api.github.com/graphql", **options)

    assert_equal "https://api.github.com/graphql", endpoint.url
    assert_equal 10, endpoint.timeout
    assert_equal 25, endpoint.pool_size
    assert_instance_of Artemis::Adapters::TestAdapter, endpoint.connection # Not a fan of this test but for now

    # FIXME: needs an example schema (and specify the :schema_path option) to test this.
    # expect(endpoint.schema).to eq(...)
  end
end