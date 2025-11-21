# AWS IPAM Config Agent Guide

This repository publishes the namespaced `IPAM` configuration package. Follow this guide whenever you update schemas, templates, docs, automation, or release metadata.

## Repository Layout

- `apis/`: XRD (`ipams/definition.yaml`), composition, and package metadata. Treat this directory as the source of truth for what ships.
- `examples/`: Renderable IPAM specs. Keep them minimal and up to date with the schema.
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

## Tooling & Automation

- `make render` / `make render-all` render examples via `up composition render`.
- `make validate` runs `crossplane beta validate` on the XRD and examples.
- `make publish tag=<version>` builds and pushes the configuration + render function packages.
- `.github/workflows` and `.gitops/` rely on the shared `unbounded-tech/workflows-crossplane` actions (currently v0.8.0). Keep the versions in sync.
- Renovate config (`renovate.json`) matches other configs—extend it here if you need custom behavior.

## Provider Guidance

Use the `crossplane-contrib` provider repositories listed in `upbound.yaml`—avoid Upbound-hosted packages that now enforce paid-account restrictions. Copy this reminder into other repo-level `AGENTS.md` files whenever you touch them so the standard remains visible.
