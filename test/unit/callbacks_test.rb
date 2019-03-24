require 'test_helper'

require 'active_support/core_ext/module/attribute_accessors'

describe "#{GraphQL::Client} Callbacks" do
  Client = Class.new(Artemis::Client) do
    def self.name
      'Metaphysics'
    end

    mattr_accessor :before_callback, :after_callback
    self.before_callback = nil
    self.after_callback = nil

    before_execute do |document, operation_name, variables, context|
      self.before_callback = document, operation_name, variables, context
    end

    after_execute do |data, errors, extensions|
      self.after_callback = data, errors, extensions
    end
  end

  describe ".before_execute" do
    it "gets invoked before executing" do
      Client.artist(id: 'yayoi-kusama', context: { user_id: 'yuki24' })

      document, operation_name, variables, context = Client.before_callback

      assert_equal Client::Artist.document, document
      assert_equal 'Client__Artist', operation_name
      assert_equal({ 'id' => 'yayoi-kusama' }, variables)
      assert_equal({ user_id: 'yuki24' }, context)
    end
  end

  describe ".after_execute" do
    it "gets invoked after executing" do
      Client.artwork

      data, errors, extensions = Client.after_callback

      assert_equal({ "test" => "data" }, data)
      assert_equal [], errors
      assert_equal({}, extensions)
    end
  end
end