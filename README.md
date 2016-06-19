# Travis States Cache

New usage:

```
# api reads:
cache.read(repo_id: repo_id, branch: branch) do
  # expensive lookup from db
end

# hub writes
cache.write(state, repo_id: repo_id, branch: branch, build_id: build_id)
```

Old usage:

```
# api reads:
cache.fetch_state(repo.id, branch)

# api writes (in event handler, will go away?)
cache.write(repo_id, branch, 'id' => build_id, 'state' => build_state)

# hub writes
cache.write(repo_id, branch, 'id' => build.id, 'state' => build.state)
```
