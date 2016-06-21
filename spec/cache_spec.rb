describe Travis::States::Cache do
  let(:config) { { adapter: :memory, format: :string } }
  let(:cache)  { described_class.new(config, logger: logger) }

  # xit 'handles connection errors gracefully' do
  #   data = { id: 10, state: 'passed' }
  #   client = Dalli::Client.new('illegalserver:11211')
  #   adapter = StatesCache::MemcachedAdapter.new(client: client)
  #   adapter.jitter = 0.005
  #   subject = StatesCache.new(adapter: adapter)
  #   expect { subject.write(1, 'master', data) }.to raise_error(Travis::StatesCache::CacheError)
  #   expect { subject.fetch(1) }.to raise_error(Travis::StatesCache::CacheError)
  # end

  describe 'read' do
    describe 'with an empty cache' do
      describe 'given a branch' do
        let(:key) { 'state:1:main' }
        subject { cache.read(repo_id: 1, branch: 'main') }

        it { expect { subject }.to call(cache.adapter, :get).with(key) }
        it { expect(subject).to be nil }
      end

      describe 'given no branch' do
        let(:key) { 'state:1' }
        subject { cache.read(repo_id: 1) }

        it { expect { subject }.to call(cache.adapter, :get).with(key) }
        it { expect(subject).to be nil }
      end
    end

    describe 'with a fresh cache' do
      describe 'given a branch' do
        let(:key)   { 'state:1:main' }
        let(:value) { '2:success' }

        before  { cache.adapter.set(key, value) }
        subject { cache.read(repo_id: 1, branch: 'main') }

        it { expect { subject }.to call(cache.adapter, :get).with(key) }
        it { expect(subject).to eq :success }
      end

      describe 'given no branch' do
        let(:key)   { 'state:1' }
        let(:value) { '2:success' }

        before  { cache.adapter.set(key, value) }
        subject { cache.read(repo_id: 1) }

        it { expect { subject }.to call(cache.adapter, :get).with(key) }
        it { expect(subject).to eq :success }
      end
    end
  end

  describe 'write' do
    describe 'with an empty cache' do
      describe 'given a branch' do
        let(:key)   { 'state:1:main' }
        let(:value) { '2:success' }
        subject { cache.write(:success, repo_id: 1, branch: 'main', build_id: 2) }

        it { expect { subject }.to call(cache.adapter, :set).with(key, value) }
        it { expect { subject }.to change { cache.adapter.get(key) }.to(value) }
        it { expect { subject }.to log('Cache is missing: repo_id=1 branch=main, given build_id=2, writing state=success') }
        it { expect(subject).to eq :success }
      end

      describe 'given no branch' do
        let(:key)   { 'state:1' }
        let(:value) { '2:success' }
        subject { cache.write(:success, repo_id: 1, build_id: 2) }

        it { expect { subject }.to call(cache.adapter, :set).with(key, value) }
        it { expect { subject }.to change { cache.adapter.get(key) }.to(value) }
        it { expect { subject }.to log('Cache is missing: repo_id=1 branch=, given build_id=2, writing state=success') }
        it { expect(subject).to eq :success }
      end
    end

    describe 'with a stale cache' do
      describe 'given a branch' do
        let(:key)   { 'state:1:main' }
        let(:value) { '2:success' }

        before  { cache.adapter.set(key, '1:success') }
        subject { cache.write(:success, repo_id: 1, branch: 'main', build_id: 2) }

        it { expect { subject }.to call(cache.adapter, :set).with(key, value) }
        it { expect { subject }.to change { cache.adapter.get(key) }.to(value) }
        it { expect { subject }.to log('Cache is stale: repo_id=1 branch=main, given build_id=2, cached build_id=1, writing state=success') }
        it { expect(subject).to eq :success }
      end

      describe 'given no branch' do
        let(:key)   { 'state:1' }
        let(:value) { '2:success' }

        before  { cache.adapter.set(key, '1:success') }
        subject { cache.write(:success, repo_id: 1, build_id: 2) }

        it { expect { subject }.to call(cache.adapter, :set).with(key, value) }
        it { expect { subject }.to change { cache.adapter.get(key) }.to(value) }
        it { expect { subject }.to log('Cache is stale: repo_id=1 branch=, given build_id=2, cached build_id=1, writing state=success') }
        it { expect(subject).to eq :success }
      end
    end

    describe 'with a fresh cache' do
      before  { cache.adapter.set(key, value) }

      describe 'given a branch' do
        let(:key)   { 'state:1:main' }
        let(:value) { '2:success' }

        before  { cache.adapter.set(key, '2:success') }
        subject { cache.write(:success, repo_id: 1, branch: 'main', build_id: 2) }

        it { expect { subject }.to call(cache.adapter, :set).never }
        it { expect { subject }.to log('Cache is fresh: repo_id=1 branch=main, given build_id=2, cached build_id=2, skipping') }
        it { expect(subject).to be nil }
      end

      describe 'given no branch' do
        let(:key)   { 'state:1' }
        let(:value) { '2:success' }

        before  { cache.adapter.set(key, '2:success') }
        subject { cache.write(:success, repo_id: 1, build_id: 2) }

        it { expect { subject }.to call(cache.adapter, :set).never }
        it { expect { subject }.to log('Cache is fresh: repo_id=1 branch=, given build_id=2, cached build_id=2, skipping') }
        it { expect(subject).to be nil }
      end
    end
  end
end
