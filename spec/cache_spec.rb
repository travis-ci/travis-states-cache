require 'stringio'
require 'logger'

describe Travis::States::Cache do
  describe 'setup' do
    before(:all) { described_class.const_set(:Test, Struct.new(:config, :logger)) }

    it 'sets an instance of States::Cache to Travis.states_cache' do
      described_class.setup(adapter: :test)
      expect(Travis.states_cache).to be_instance_of(Travis::States::Cache)
    end

    it 'uses an instance of the given adapter type' do
      described_class.setup(adapter: :test)
      expect(Travis.states_cache.adapter).to be_instance_of(Travis::States::Cache::Test)
    end
  end
end

describe Travis::States::Cache::Memcached do
  let(:stdout)   { StringIO.new }
  let(:logger)   { Logger.new(stdout) }
  let(:conn)     { stub('connection') }

  let(:cache)    { described_class.new({ connection: conn }, logger) }
  let(:repo_id)  { 1 }
  let(:build_id) { 2 }

  shared_examples_for 'reads from memcached' do |key|
    it 'reads the expected key' do
      conn.expects(:get).with(key)
      cache.read(*args)
    end

    it 'parses the cached json' do
      conn.stubs(:get).returns(JSON.dump(id: build_id, state: 'success'))
      expect(cache.read(*args)).to eq(id: build_id, state: 'success')
    end
  end

  shared_examples_for 'writes to memcached' do |key, data|
    it 'writes the serialized data to the expected key' do
      conn.expects(:set).with(key, data)
      cache.write(*args)
    end
  end

  shared_examples_for 'does not write to memcached' do
    it 'writes the serialized data to the expected key' do
      conn.expects(:set).never
      cache.write(*args)
    end
  end

  describe 'read' do
    describe 'with no branch name given' do
      let(:args) { [repo_id] }
      include_examples 'reads from memcached', 'state:1'
    end

    describe 'with a branch name given' do
      let(:args) { [repo_id, branch: 'main'] }
      include_examples 'reads from memcached', 'state:1-main'
    end
  end

  describe 'write' do
    before { conn.stubs(:get).returns(cached) }

    describe 'with a build_id given ("not-really-a-cache mode")' do
      describe 'with no branch name given' do
        let(:args) { [repo_id, :success, build_id: build_id] }

        describe 'with the cache missing' do
          let(:cached) { nil }
          include_examples 'writes to memcached', 'state:1', JSON.dump(id: 2, state: 'success')
        end

        describe 'with the cache being stale' do
          let(:cached) { JSON.dump(id: 1, state: 'failed') }
          include_examples 'writes to memcached', 'state:1', JSON.dump(id: 2, state: 'success')
        end

        describe 'with the cache being fresh' do
          let(:cached) { JSON.dump(id: 3, state: 'failed') }
          include_examples 'does not write to memcached'
        end
      end

      describe 'with a branch name given' do
        let(:args) { [repo_id, :success, build_id: build_id, branch: 'master'] }

        describe 'with the cache missing' do
          let(:cached) { nil }
          include_examples 'writes to memcached', 'state:1-master', JSON.dump(id: 2, state: 'success')
        end

        describe 'with the cache being stale' do
          let(:cached) { JSON.dump(id: 1, state: 'failed') }
          include_examples 'writes to memcached', 'state:1-master', JSON.dump(id: 2, state: 'success')
        end

        describe 'with the cache being fresh' do
          let(:cached) { JSON.dump(id: 3, state: 'failed') }
          include_examples 'does not write to memcached'
        end
      end
    end

    describe 'with no build_id given ("actually-a-cache mode")' do
      describe 'with no branch name given' do
        let(:args) { [repo_id, :success] }

        describe 'with the cache missing' do
          let(:cached) { nil }
          include_examples 'writes to memcached', 'state:1', JSON.dump(state: 'success')
        end

        describe 'with the cache present (id set)' do
          let(:cached) { JSON.dump(id: 1, state: 'failed') }
          include_examples 'writes to memcached', 'state:1', JSON.dump(state: 'success')
        end

        describe 'with the cache present (id set)' do
          let(:cached) { JSON.dump(state: 'failed') }
          include_examples 'writes to memcached', 'state:1', JSON.dump(state: 'success')
        end
      end
    end
  end
end

# describe Travis::States::Cache do
#   describe 'integration' do
#     let(:client) { Dalli::Client.new('localhost:11211') }
#     let(:adapter) { StatesCache::MemcachedAdapter.new(client: client) }
#
#     before do
#       begin
#         client.flush
#       rescue Dalli::DalliError => e
#         pending "Dalli can't run properly, skipping. Cause: #{e.message}"
#       end
#     end
#
#     it 'saves the state for given branch and globally' do
#       data = { id: 10, state: 'passed' }.stringify_keys
#       subject.write(1, 'master', data)
#       subject.fetch(1)['state'].should == 'passed'
#       subject.fetch(1, 'master')['state'].should == 'passed'
#
#       subject.fetch(2).should be_nil
#       subject.fetch(2, 'master').should be_nil
#     end
#
#     it 'updates the state only if the info is newer' do
#       data = { id: 10, state: 'passed' }.stringify_keys
#       subject.write(1, 'master', data)
#
#       subject.fetch(1, 'master')['state'].should == 'passed'
#
#       data = { id: 12, state: 'failed' }.stringify_keys
#       subject.write(1, 'development', data)
#
#       subject.fetch(1, 'master')['state'].should == 'passed'
#       subject.fetch(1, 'development')['state'].should == 'failed'
#       subject.fetch(1)['state'].should == 'failed'
#
#       data = { id: 11, state: 'errored' }.stringify_keys
#       subject.write(1, 'master', data)
#
#       subject.fetch(1, 'master')['state'].should == 'errored'
#       subject.fetch(1, 'development')['state'].should == 'failed'
#       subject.fetch(1)['state'].should == 'failed'
#     end
#
#     it 'updates the state if the id of the build is the same' do
#       data = { id: 10, state: 'failed' }.stringify_keys
#       subject.write(1, 'master', data)
#
#       subject.fetch(1, 'master')['state'].should == 'passed'
#
#       data = { id: 10, state: 'passed' }.stringify_keys
#       subject.write(1, 'master', data)
#
#       subject.fetch(1, 'master')['state'].should == 'passed'
#     end
#
#     it 'handles connection errors gracefully' do
#       data = { id: 10, state: 'passed' }.stringify_keys
#       client = Dalli::Client.new('illegalserver:11211')
#       adapter = StatesCache::MemcachedAdapter.new(client: client)
#       adapter.jitter = 0.005
#       subject = StatesCache.new(adapter: adapter)
#       expect {
#         subject.write(1, 'master', data)
#       }.to raise_error(Travis::StatesCache::CacheError)
#
#       expect {
#         subject.fetch(1)
#       }.to raise_error(Travis::StatesCache::CacheError)
#     end
#   end
# end
