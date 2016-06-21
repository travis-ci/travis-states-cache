# Travis States Cache

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
>> c.get('state:2717-ha-test-pr-676')
=> "{\"id\":139282218,\"state\":\"passed\"}"
```

New format (json):

```
>> c.get('state:2717')
=> "2717::139291162,failed"
>> c.get('state:2717-ha-test-pr-676')
=> "{"build_id":139291162,"state":"success"}"
=> ""
```

