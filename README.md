# Travis States Cache [![Build Status](https://travis-ci.org/travis-ci/travis-states-cache.svg?branch=master)](https://travis-ci.org/travis-ci/travis-states-cache)

Old usage (with travis-core):

```ruby
# api reads:
cache.fetch_state(repo.id, branch)

# api writes (in event handler, will go away?)
cache.write(repo_id, branch, 'id' => build_id, 'state' => build_state)

# hub writes
cache.write(repo_id, branch, 'id' => build.id, 'state' => build.state)
```

New usage:

```ruby
# api reads:
cache.read(repo_id: repo_id, branch: branch) do
  # expensive lookup from db
end

# hub writes
cache.write(state, repo_id: repo_id, branch: branch, build_id: build_id)
```

Old format (current data, json):

```
>> c.get('state:2717')
=> "{\"id\":139291162,\"state\":\"failed\"}"
>> c.get('state:2717-ha-test-pr-676')
=> "{\"id\":139282218,\"state\":\"passed\"}"
```

New format (string, default):

```
>> c.get('state:2717')
=> "2717::139291162,failed"
>> c.get('state:2717:ha-test-pr-676')
=> "2717:ha-test-pr-676:139291162,failed"
```

New format (json):

```
>> c.get('state:2717')
=> "2717::139291162,failed"
>> c.get('state:2717:ha-test-pr-676')
=> "{\"build_id\":139291162,\"state\":\"success\"}"
=> ""
```

#### Migration strategy

* [`Serialize#deserialize`](https://github.com/travis-ci/travis-states-cache/blob/master/lib/travis/states/cache/serialize.rb#L52) auto-detects the format at read time.
* [`Serialize::Compat`](https://github.com/travis-ci/travis-states-cache/blob/master/lib/travis/states/cache/serialize/compat.rb) normalizes the key `id` to `build_id` in  at read time.
* [`Adapter::Compat`](https://github.com/travis-ci/travis-states-cache/blob/master/lib/travis/states/cache/adapter/compat.rb#L8) tries the old key format unless a value has been found for the new key format. If there's a value stored for the old format it will write it to the respective key with the new format.
