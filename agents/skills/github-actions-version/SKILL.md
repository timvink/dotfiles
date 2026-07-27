---
name: github-actions-version
description: Get the latest version of a GitHub Action from the actions-latest repository. Use when working with Github Actions
license: MIT
metadata:
  author: Tim Vink
  version: "1.0.0"  
---

Github Actions are usually versioned. For example:

```
    - name: Install uv and set the python version
      uses: astral-sh/setup-uv@v7
      with:
        python-version: ${{ matrix.python-version }}
```


When you use a Github Action, you won't know what the latest version is, or if the current version is outdated. 

This file will always show you the latest versions of for commonly used Github Actions: https://raw.githubusercontent.com/timvink/actions-latest/refs/heads/main/versions.txt. Always check that.

If you're working on a github workflow and you see that a version is outdated, ask the user if they want to update to the latest version.

