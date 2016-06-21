shared_examples_for 'compatibility with old key format' do
  let(:adapter) { described_class.new }
  let(:new)     { 'state:1:main' }
  let(:old)     { 'state:1-main' }
  let(:value)   { '1:passed' }

  subject { adapter.get(new) }

  describe 'when the new key is set' do
    before { client.stubs(:get).with(new).returns(value) }

    it 'returns the stored value' do
      expect(subject).to eq(value)
    end

    it 'does not try to read the old key' do
      client.expects(:get).with(old).never
      subject
    end

    it 'does not write the new key' do
      client.expects(:set).with(new, value).never
      subject
    end
  end

  describe 'when the new key is not set' do
    before { client.stubs(:get).with(new).returns(nil) }

    it 'tries to read the old key' do
      client.expects(:get).with(old)
      subject
    end

    it 'does not write the new key if the old key is not set' do
      client.stubs(:get).with(old).returns(nil)
      client.expects(:set).with(new, value).never
      subject
    end

    it 'writes the new key if the old key is set' do
      client.stubs(:get).with(old).returns(value)
      client.expects(:set).with(new, value)
      subject
    end
  end
end

describe Travis::States::Cache::Adapter::Memcached, 'compat' do
  let(:client) { Dalli::Client.any_instance }
  include_examples 'compatibility with old key format'
end

describe Travis::States::Cache::Adapter::Memory, 'compat' do
  let(:client) { adapter.client }
  include_examples 'compatibility with old key format'
end
