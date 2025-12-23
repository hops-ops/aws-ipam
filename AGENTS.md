# AWS IPAM Config Agent Guide

This repository publishes the namespaced `IPAM` configuration package. Follow this guide whenever you update schemas, templates, docs, automation, or release metadata.

## Repository Layout

- `apis/`: XRD (`ipams/definition.yaml`), composition, and package metadata. Treat this directory as the source of truth for what ships.
- `examples/ipams/`: Renderable IPAM specs. Keep them minimal and up to date with the schema. Use simple names without `example-` prefix (e.g., `minimal.yaml`, `multi-region.yaml`).
- `examples/test/mocks/observed-resources/`: Mock observed resources for multi-step render testing. Organized by example name with numbered steps:
  ```
  examples/test/mocks/observed-resources/
  ├── private-ipv6/steps/{1,2,3}/
  ├── with-subnet-pool/steps/{1,2,3}/
  └── with-subnet-pools/steps/{1,2,3}/
  ```
- `functions/render/`: Go-template pipeline executed by `up composition render`. Prefix files (`00-`, `05-`, `10-`, `90-`, etc.) so related logic stays grouped.
- `tests/`: Regression coverage powered by `up test` (KCL assertions).
- `.github/` & `.gitops/`: CI + GitOps automation. Keep them structurally identical—only tweak repo-specific values like image names.
- `_output/` & `.up/`: Generated artefacts. `make clean` removes them so `make build` can recreate fresh state.

## Contract Overview

`apis/ipams/definition.yaml` defines the `IPAM` XRD:

- `spec.organizationName` feeds naming/tagging and defaults to `metadata.name` when omitted.
- `spec.aws`: provider config + shared AWS defaults. `aws.config.tags` always merges with `{"hops":"true","organization":<name>}`.
- `spec.ipam.homeRegion` plus `spec.ipam.pools[]` establish the IPAM instance, scope, and pool definitions. Each pool expects `name` + `cidrBlock` and optional region/locale, allocation guard rails, labels, and tags.
- `spec.managementPolicies` defaults to `["*"]` and propagates to every AWS resource.
- Status projects observed IDs for the IPAM, scope, and pools so callers can debug quickly.

Whenever you add schema knobs, update the examples, README, and tests in the same change.

## Rendering Guidelines

### Resource Naming

**Do not add redundant type suffixes to resource names.** The `kind` already tells you what the resource is.

Bad:
```yaml
{{ $ipamResourceName := printf "%s-ipam" $organizationName }}
---
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: VPCIpam
metadata:
  name: {{ $ipamResourceName }}  # "platform-ipam" - redundant suffix
```

Good:
```yaml
---
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: VPCIpam
metadata:
  name: {{ $organizationName }}  # "platform" - clean, the Kind tells you it's an IPAM
```

Exceptions where suffixes make sense:
- Disambiguating multiple resources of the same kind: `{{ $poolName }}-cidr` when you have both a Pool and its Cidr
- Child resources that need to reference a parent: the suffix helps link them visually

This keeps names short, reduces template complexity, and avoids the extra work of formatting `printf "%s-<kind>" $name` everywhere.

### Template Structure

- Declare inputs (organization name, provider configs, deletion/management policies, tag maps, pool lists) in `functions/render/00-desired-values.yaml.gotmpl`. Default aggressively with `default` and `merge` helpers so templates never dereference nil values.
- Keep resources split per file:
  - `05-ipam`: `VpcIpam` + `VpcIpamScope`
  - `10-ipam-pools`: one `VpcIpamPool` + `VpcIpamPoolCidr` per entry
  - `90-observed-values` (if needed) + `99-status`: status projection built from observed resources
- Use `setResourceNameAnnotation` consistently so observed snapshots stay stable.
- Always set `managementPolicies` and `providerConfigRef.kind: ProviderConfig` on managed resources to align with Crossplane 2.0 expectations.
- Merge caller tags/labels with the defaults before applying them.

## Testing

`tests/test-render/main.k` exercises representative examples:

- Minimal example: verifies tags, labels, management policies, and that the IPAM only registers one operating region when the pools are single-region.
- Multi-region example: ensures the IPAM registers both regions, per-pool locales are honored, and allocation guard rails flow through.
- Usage example: seeds `observedResources` so the render pipeline believes the IPAM, pools, CIDRs, and RAM shares are Ready. This lets the protection `Usage` resources render without real cloud state.

Add new examples under `examples/ipams/` before writing assertions. Keep tests focused—assert only the fields that should never change.

When templates gate behavior on observed readiness (for example usage wiring), add synthetic entries to `observedResources` that mirror the managed resource’s `apiVersion`, `kind`, metadata, and Ready condition. Include both `gotemplating.fn.crossplane.io/composition-resource-name` and `crossplane.io/composition-resource-name` annotations so `functions/render/10-observed-values.yaml.gotmpl` can match them against the names emitted via `setResourceNameAnnotation`.

Run `make test` (or `up test run tests/test-*`) after touching templates or schema.

`tests/e2etest-ipam/main.k` provisions a throwaway `IPAM` in AWS to confirm the full composition still reconciles. Execute it with `make e2e` (or `up test run tests/e2etest* --e2e`) after dropping temporary credentials into `tests/e2etest-ipam/aws-creds`. The file stays gitignored; it must contain a `[default]` profile compatible with the AWS SDK, for example:

```
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCY...
```

## Adding or Modifying Examples

When you add, rename, or remove an example, update these files in the same commit:

1. **`Makefile`** – `EXAMPLES` list (format: `example_path::observed_resources_path`)
2. **`.github/workflows/on-pr.yaml`** – `examples` array in the `validate` job
3. **`.github/workflows/on-push-main.yaml`** – `examples` array in the `validate` job
4. **`tests/test-render/main.k`** – `xrPath` references if the example is used in tests

For examples with multi-step observed resources, add each step as a separate entry:
```makefile
examples/ipams/with-subnet-pool.yaml:: \
examples/ipams/with-subnet-pool.yaml::examples/test/mocks/observed-resources/with-subnet-pool/steps/1 \
examples/ipams/with-subnet-pool.yaml::examples/test/mocks/observed-resources/with-subnet-pool/steps/2
```

Run `make validate:all` locally before pushing to verify all paths resolve correctly.

## Tooling & Automation

- `make render` / `make render-all` render examples via `up composition render`.
- `make validate` runs `crossplane beta validate` on the XRD and examples.
- `make publish tag=<version>` builds and pushes the configuration + render function packages.
- `.github/workflows` and `.gitops/` rely on the shared `unbounded-tech/workflows-crossplane` actions (currently v2.5.0). Keep the versions in sync.
- Renovate config (`renovate.json`) matches other configs—extend it here if you need custom behavior.

## Provider Guidance

Use the `crossplane-contrib` provider repositories listed in `upbound.yaml`—avoid Upbound-hosted packages that now enforce paid-account restrictions. Copy this reminder into other repo-level `AGENTS.md` files whenever you touch them so the standard remains visible.
