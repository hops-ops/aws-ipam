# configuration-aws-ipam

`configuration-aws-ipam` publishes the namespaced `IPAM` composite. It encapsulates the AWS VPC IP Address Manager (IPAM) instance, the default private scope, and a declarative list of IPAM pools so downstream compositions (for example, `Network`) can allocate CIDRs via label selectors instead of duplicating boilerplate.

## Features

- **Crossplane 2.0 ready** – the `IPAM` XRD is namespaced, defines `managementPolicies`, and projects observed IDs back into `status.ipam` for quick debugging.
- **Global or delegated scopes** – flip `spec.forProvider.scope` between `delegated-organization` (per-customer) and `global-organization` (shared from `hops-shared-services`) without changing any downstream consumers.
- **Opinionated defaults** – `organizationName` plus a default tag map (`{"hops":"true","organization":<name>}`) keep naming/tagging consistent. Callers can layer additional tags and labels per pool.
- **Multi-region coverage** – declare pools across multiple AWS regions/locales. The composition automatically registers each region with the IPAM instance's operatingRegions list.
- **Tunable allocation guards** – optional `allocationDefaultNetmaskLength`, min, and max fields map directly to the AWS API, giving consumers predictable CIDR sizing knobs.
- **Built-in RAM sharing** – when `scope=global-organization` every pool can declare `ramShareTargets` so the composition provisions AWS RAM `ResourceShare` + `PrincipalAssociation` resources only for the pools you choose.
- **Tests + examples** – focused examples live under `examples/ipams/` and the regression suite (`tests/test-render`) ensures templates keep emitting the expected metadata, tags, and management policies.

## Prerequisites

- Crossplane v1.15+ running in your control plane.
- Crossplane packages:
  - `provider-aws-vpc` (≥ v2.2.0)
  - `provider-aws-ram` (≥ v2.2.0)
  - `function-auto-ready` (≥ v0.5.1)

Avoid the Upbound-hosted packages that require paid accounts—stick with the `crossplane-contrib` images referenced in `upbound.yaml` and `.gitops/`.

## Install

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: configuration-aws-ipam
spec:
  package: ghcr.io/hops-ops/configuration-aws-ipam:latest
  skipDependencyResolution: true
```

## Example Composite

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: platform-ipam
  namespace: example-env
spec:
  organizationName: platform
  forProvider:
    scope: delegated-organization
    delegatedAdminAccountRef:
      name: platform-root
    homeRegion: us-west-2
    operatingRegions:
      - us-west-2
    pools:
      - name: platform-shared
        cidr: 10.0.0.0/8
        allocationDefaultNetmaskLength: 16
        labels:
          function: shared
        tags:
          environment: dev
          owner: platform
```

Running `up composition render apis/ipams/composition.yaml examples/ipams/example-minimal.yaml` emits:

- `vpc.aws.m.upbound.io/v1beta1, Kind=IPAM`
- `vpc.aws.m.upbound.io/v1beta1, Kind=IPAMScope`
- one `IPAMPool` per entry in `spec.forProvider.pools`
- optional `ram.aws.m.upbound.io/v1beta1` ResourceShare + PrincipalAssociation resources for pools that declare `ramShareTargets` while `scope=global-organization`

The rendered resources include the default tag map plus any caller-supplied tags/labels so selectors downstream stay simple.

## Development

- `make clean` – remove `_output/` and `.up/` artefacts.
- `make build` – rebuild the configuration package with `up project build`.
- `make render` – render the default example (`examples/ipams/example-minimal.yaml`).
- `make render-all` – render every example under `examples/ipams/`.
- `make validate` – validate the XRD + examples via `crossplane beta validate`.
- `make test` – execute `up test run tests/test-*` suites.
- `make e2e` – run `up test run tests/e2etest* --e2e`. Requires a `[default]` AWS profile saved to `tests/e2etest-ipam/aws-creds` (gitignored).
- `make publish tag=<version>` – build and push a tagged package + render function image.

When bumping provider versions or adding new schema knobs, update:

1. `apis/ipams/definition.yaml`
2. `apis/ipams/composition.yaml`
3. `examples/ipams/*.yaml`
4. `tests/test-render/main.k`
5. Documentation (this README + `AGENTS.md`)

To execute the e2e suite locally, add disposable AWS credentials to `tests/e2etest-ipam/aws-creds` in the standard INI format:

```
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCY...
```

The file stays gitignored so you can use temporary keys without risking accidental commits.

## Support

- **Issues**: [github.com/hops-ops/configuration-aws-ipam/issues](https://github.com/hops-ops/configuration-aws-ipam/issues)
- **Discussions**: [github.com/hops-ops/configuration-aws-ipam/discussions](https://github.com/hops-ops/configuration-aws-ipam/discussions)
