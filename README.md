# aas-sign build for MSYS2 CI pipelines

This builds the [skeeto/aas-sign](https://github.com/skeeto/aas-sign) Linux
`x86_64` binary in a repeatable way. So
we can use the binary for code signing in our CI pipelines without needing to
depend on third party binaries.

Build:

```bash
docker build --output out .
```

Result:

```text
out/aas-sign
```
