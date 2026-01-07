# aws-ipam

Centralized IP address management for AWS. Stop tracking CIDRs in spreadsheets - request them from pools and let IPAM handle allocation, overlap prevention, and auditing.

## Why IPAM?

AWS recommends IPAM for any multi-VPC environment. Without proper IP address management, organizations risk address conflicts, wasted address space, and complex troubleshooting that leads to outages.

**Without IPAM:**
- Manual CIDR tracking in spreadsheets or wikis that drift from reality
- Overlapping ranges when teams don't coordinate across accounts
- No audit trail of who allocated what and when
- IPv6 adoption feels impossible without a centralized plan
- VPC creation blocked waiting on network team approvals

**With IPAM:**
- Automatic CIDR allocation from hierarchical pools - guaranteed non-overlapping
- Full audit trail and compliance monitoring in AWS
- Dual-stack (IPv4 + IPv6) ready from day one
- Self-service VPC creation with guardrails (allocation rules enforce sizing)
- Share pools across accounts via RAM (configured separately)
- Compliance status tracking: Compliant, Noncompliant, or Unmanaged

## The Journey

### Stage 1: Getting Started (Single Account)

You have one AWS account and want organized IP allocation for your VPCs. Starting with IPAM early prevents painful migrations later.

**Why start with IPAM now?**
- When you add accounts later, VPCs won't overlap - the pool enforces it
- Dual-stack (IPv6) ready from day one with no retrofitting
- No migration pain - just keep using the same pools as you grow
- Size VPCs appropriately with allocation rules (no more "let's just use /16 to be safe")

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: platform
  namespace: default
spec:
  providerConfigRef:
    name: default
  region: us-east-1
  pools:
    ipv4:
      # 10.0.0.0/8 gives you 16 million addresses
      # Default /20 = 4096 IPs per VPC (enough for most workloads)
      - name: ipv4
        cidr: 10.0.0.0/8
        allocations:
          netmaskLength:
            default: 20  # 4096 IPs - right-sized for typical VPCs
            min: 16      # Largest allowed: 65,536 IPs
            max: 24      # Smallest allowed: 256 IPs
        description: IPv4 pool for VPCs
```

**Sizing guidance:** Most VPCs need far less than a /16. A /20 provides 4096 addresses - plenty for EKS clusters, RDS instances, and Lambda ENIs. Use allocation rules to prevent wasteful oversizing.

### Stage 2: Add IPv6 for Modern Workloads

IPv6 eliminates IP exhaustion concerns and enables modern networking patterns. AWS provides two types of IPv6:

| Type | Range | Use Case |
|------|-------|----------|
| **ULA (Private)** | `fd00::/8` | Internal services, databases, service mesh |
| **GUA (Public)** | Amazon-provided | Internet-facing workloads, public APIs |

**Why IPv6?**
- Pods get native IPv6 addresses (no NAT overhead in EKS)
- Essentially unlimited IPs - a /56 per VPC gives you 4.7 sextillion addresses
- Future-proof: IPv4 exhaustion is real, especially with container density
- EKS IPv6 mode solves the IP exhaustion problem in large clusters

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: platform
  namespace: default
spec:
  providerConfigRef:
    name: default
  region: us-east-1
  pools:
    ipv4:
      - name: ipv4
        cidr: 10.0.0.0/8
        allocations:
          netmaskLength:
            default: 20

    ipv6:
      # Private IPv6 (ULA) - AWS auto-assigns from fd00::/8
      # Use for internal services that don't need internet routing
      ula:
        - name: ipv6-private
          netmaskLength: 48  # AWS assigns a /48 ULA block
          allocations:
            netmaskLength:
              default: 56    # /56 per VPC = 256 subnets
              min: 48
              max: 64
          description: Private IPv6 for internal services

      # Public IPv6 (GUA) - Amazon-provided internet-routable
      # Use for public-facing workloads
      gua:
        - name: ipv6-public
          netmaskLength: 52  # AWS provisions /52 = 16 VPC allocations
          allocations:
            netmaskLength:
              default: 56    # /56 per VPC (AWS standard)
              min: 52
              max: 60
          description: Public IPv6 for internet-facing workloads
```

**Dual-stack strategy:** Create dual-stack VPCs with a mix of subnet types. You can have IPv4-only, dual-stack, and IPv6-only subnets in the same VPC, allowing gradual IPv6 adoption.

### Stage 3: Multi-Region (Enterprise Scale)

Expanding to multiple regions requires a hierarchical pool structure. Regional pools ensure:

- **Lower latency:** VPCs allocate from region-local pools
- **Data residency:** Compliance requirements (GDPR, data sovereignty) map to regional pools
- **Disaster recovery:** Clear IP boundaries between regions simplify failover

AWS recommends a four-tier hierarchy for enterprise: top-level pool → regional pools → business unit pools → environment pools.

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: platform
  namespace: default
spec:
  providerConfigRef:
    name: default
  region: us-east-1
  # IPAM auto-discovers regions from pool locales, but you can
  # pre-provision regions before defining pools there
  operatingRegions:
    - us-east-1
    - us-west-2
    - eu-west-1
  pools:
    ipv4:
      # Global pool - top of hierarchy (no locale = global)
      - name: ipv4-global
        cidr: 10.0.0.0/8
        allocations:
          netmaskLength:
            default: 12  # Carve out /12 per region = 1M IPs each

      # US East regional pool
      - name: ipv4-us-east-1
        sourcePoolRef: ipv4-global  # Child of global
        locale: us-east-1           # Only us-east-1 VPCs can allocate
        cidr: 10.0.0.0/12           # 10.0.0.0 - 10.15.255.255
        allocations:
          netmaskLength:
            default: 20

      # US West regional pool
      - name: ipv4-us-west-2
        sourcePoolRef: ipv4-global
        locale: us-west-2
        cidr: 10.16.0.0/12          # 10.16.0.0 - 10.31.255.255
        allocations:
          netmaskLength:
            default: 20

      # EU regional pool (for GDPR workloads)
      - name: ipv4-eu-west-1
        sourcePoolRef: ipv4-global
        locale: eu-west-1
        cidr: 10.32.0.0/12          # 10.32.0.0 - 10.47.255.255
        allocations:
          netmaskLength:
            default: 20

    ipv6:
      ula:
        # Global ULA pool
        - name: ipv6-private
          netmaskLength: 48
          allocations:
            netmaskLength:
              default: 56

        # Regional ULA for us-east-1
        - name: ipv6-private-us-east-1
          sourcePoolRef: ipv6-private
          locale: us-east-1
          netmaskLength: 56
          allocations:
            netmaskLength:
              default: 64
```

**Locale enforcement:** When a pool has a `locale`, only VPCs in that region can allocate from it. This prevents accidental cross-region allocations and ensures compliance boundaries.

### Stage 4: Import Existing IPAM

Already have an IPAM? Import it along with existing pools to bring them under GitOps management.

**Why import?**
- Preserve existing allocations - no disruption to running VPCs
- Gradual adoption path - import what you have, extend with new pools
- Single source of truth - manage IPAM alongside other infrastructure

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: existing-ipam
  namespace: default
spec:
  # Import existing IPAM by ID
  externalName: ipam-0123456789abcdef0
  # Observe and update, but don't delete if this resource is removed
  managementPolicies: ["Observe", "Update", "LateInitialize"]

  providerConfigRef:
    name: default
  region: us-east-1
  pools:
    ipv4:
      - name: ipv4
        cidr: 10.0.0.0/8
        # Import existing pool
        externalName: ipam-pool-0123456789abcdef0
        # Format: cidr_pool-id
        cidrExternalName: 10.0.0.0/8_ipam-pool-0123456789abcdef0
        managementPolicies: ["Observe", "Update", "LateInitialize"]
        allocations:
          netmaskLength:
            default: 20
```

## Using IPAM Pools

Reference pool IDs from status when creating VPCs. The XRD exposes all pool IDs for downstream consumption.

```yaml
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: VPC
spec:
  forProvider:
    region: us-east-1
    # IPv4 from IPAM pool
    ipv4IpamPoolId: ipam-pool-abc123  # From status.pools.ipv4[name=ipv4].id
    ipv4NetmaskLength: 20
    # IPv6 from IPAM (dual-stack)
    ipv6IpamPoolId: ipam-pool-xyz789  # From status.pools.ipv6.gua[name=ipv6-public].id
    ipv6NetmaskLength: 56
```

**Cross-account sharing:** To share pools with other AWS accounts, use AWS RAM (Resource Access Manager). RAM sharing is configured separately from this XRD - create a RAM resource share and add the IPAM pool ARN to it.

## Status

The XRD exposes pool IDs and observed CIDRs for downstream resources:

```yaml
status:
  id: ipam-0123456789abcdef0
  arn: arn:aws:ec2:us-east-1:111111111111:ipam/ipam-0123456789abcdef0
  privateDefaultScopeId: ipam-scope-abc123
  publicDefaultScopeId: ipam-scope-xyz789
  pools:
    ipv4:
      - name: ipv4
        id: ipam-pool-abc123
        arn: arn:aws:ec2:us-east-1:111111111111:ipam-pool/ipam-pool-abc123
        cidr: 10.0.0.0/8
    ipv6:
      ula:
        - name: ipv6-private
          id: ipam-pool-def456
          cidr: fd00:ec2::/48
      gua:
        - name: ipv6-public
          id: ipam-pool-xyz789
          cidr: 2600:1f26:47:c000::/52
```

## IPv6 Pool Sizing Reference

| Level | Netmask | Addresses | Typical Use |
|-------|---------|-----------|-------------|
| IPAM Pool (GUA) | /52 | 16 /56 VPCs | Regional allocation |
| VPC | /56 | 256 /64 subnets | Per-VPC allocation |
| Subnet | /64 | 18 quintillion | Standard subnet size |
| EKS Node Prefix | /80 | ~65k pod IPs | Prefix delegation per node |

**Note:** VPC IPv6 allocations support /44, /48, /52, /56, and /60 (increments of /4).

## Composed Resources

This XRD creates the following AWS resources:

| Resource | Purpose | When Created |
|----------|---------|--------------|
| `VPCIpam` | Core IPAM instance with default scopes | Always |
| `VPCIpamScope` | Custom scope for isolated address spaces | When `scopes` defined |
| `VPCIpamPool` | Address pool (IPv4 or IPv6) | For each pool in `pools` |
| `VPCIpamPoolCidr` | CIDR provisioned to a pool | For top-level pools with `cidr` or `netmaskLength` |
| `Usage` | Deletion ordering (pool → CIDR dependencies) | When dependent resources are Ready |

## Development

```bash
make render              # Render all examples
make validate            # Validate all examples
make test                # Run KCL tests
make e2e                 # E2E tests against real AWS
make render:minimal      # Render single example
make validate:standard   # Validate single example
```

## References

- [Amazon VPC IPAM Best Practices](https://aws.amazon.com/blogs/networking-and-content-delivery/amazon-vpc-ip-address-manager-best-practices/)
- [Multi-Region IPAM Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/multi-region-ipam-architecture.html)
- [IPv6 on AWS Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/ipv6-on-aws/ipv6-on-aws.html)
- [Dual-stack IPv6 Architectures](https://aws.amazon.com/blogs/networking-and-content-delivery/dual-stack-ipv6-architectures-for-aws-and-hybrid-networks/)

## License

Apache-2.0
