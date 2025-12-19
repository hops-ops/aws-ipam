# configuration-aws-ipam

Centralized IP address management for AWS. Stop tracking CIDRs in spreadsheets - request them from pools and let IPAM handle allocation, overlap prevention, and auditing.

## Why IPAM?

**Without IPAM:**
- Manual CIDR tracking in spreadsheets or wikis
- Overlapping ranges when teams don't coordinate
- No audit trail of who allocated what
- IPv6 adoption feels impossible

**With IPAM:**
- Automatic CIDR allocation from pools
- Guaranteed non-overlapping ranges
- Full audit trail in AWS
- Dual-stack (IPv4 + IPv6) ready for modern workloads
- Share pools across accounts via RAM

## The Journey

### Stage 1: Single Account IPAM

You have one AWS account and want organized IP allocation for your VPCs.

**Why start with IPAM early?**
- When you add accounts later, VPCs won't overlap
- Dual-stack (IPv6) ready from day one
- No migration pain - just keep using the same pools

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: my-ipam
  namespace: default
spec:
  managementPolicies: ["*"]
  providerConfigName: default
  scope: private  # Single-account IPAM
  homeRegion: us-east-1
  operatingRegions: [us-east-1]

  pools:
    # IPv4 for VPCs - 10.0.0.0/8 gives you 16 million addresses
    - name: ipv4
      addressFamily: ipv4
      region: us-east-1
      cidr: 10.0.0.0/8
      allocationDefaultNetmaskLength: 20  # /20 = 4096 IPs per VPC
      allocationMinNetmaskLength: 16
      allocationMaxNetmaskLength: 24
      description: IPv4 pool for VPCs
```

### Stage 2: Add IPv6 for Modern Workloads

IPv6 eliminates IP exhaustion concerns and enables modern networking patterns.

**Why IPv6?**
- Pods get native IPv6 addresses (no NAT overhead)
- Essentially unlimited IPs - /80 prefix = 281 trillion addresses per node
- Future-proof your infrastructure

**Two types of IPv6 pools:**
- **Public (Amazon GUA)** - Internet-routable, for public-facing workloads
- **Private (ULA)** - Internal-only, for service mesh and databases

```yaml
pools:
  - name: ipv4
    addressFamily: ipv4
    region: us-east-1
    cidr: 10.0.0.0/8
    allocationDefaultNetmaskLength: 20

  # IPv6 public - Amazon provides /52, you allocate /56 per VPC
  - name: ipv6-public
    addressFamily: ipv6
    scope: public
    region: us-east-1
    locale: us-east-1
    amazonProvidedIpv6CidrBlock: true
    publicIpSource: amazon
    awsService: ec2
    netmaskLength: 52  # AWS provisions /52 block
    allocationDefaultNetmaskLength: 56  # /56 per VPC
    allocationMinNetmaskLength: 52
    allocationMaxNetmaskLength: 60
    description: Public IPv6 for internet-facing workloads

  # IPv6 private - AWS auto-assigns from fd00::/8 ULA range
  - name: ipv6-private
    addressFamily: ipv6
    scope: private
    region: us-east-1
    locale: us-east-1
    netmaskLength: 48  # AWS auto-assigns ULA CIDR
    allocationDefaultNetmaskLength: 56
    allocationMinNetmaskLength: 48
    allocationMaxNetmaskLength: 64
    description: Private IPv6 for internal services
```

### Stage 3: Multi-Region

Expanding to multiple regions? Add them to operatingRegions and create regional pools.

**Why regional pools?**
- Lower latency for regional workloads
- Compliance requirements (data residency)
- Disaster recovery across regions

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: my-ipam
  namespace: default
spec:
  providerConfigName: default
  scope: private
  homeRegion: us-east-1
  operatingRegions: [us-east-1, us-west-2, eu-west-1]

  pools:
    # US East
    - name: us-east-1-ipv4
      addressFamily: ipv4
      region: us-east-1
      cidr: 10.0.0.0/12    # 10.0.0.0 - 10.15.255.255
      allocationDefaultNetmaskLength: 20

    # US West
    - name: us-west-2-ipv4
      addressFamily: ipv4
      region: us-west-2
      cidr: 10.16.0.0/12   # 10.16.0.0 - 10.31.255.255
      allocationDefaultNetmaskLength: 20

    # EU
    - name: eu-west-1-ipv4
      addressFamily: ipv4
      region: eu-west-1
      cidr: 10.32.0.0/12   # 10.32.0.0 - 10.47.255.255
      allocationDefaultNetmaskLength: 20
```

### Stage 4: Multi-Account with RAM Sharing

Multiple AWS accounts need access to IPAM pools? Use RAM (Resource Access Manager) to share pools with accounts or entire OUs.

**Why RAM sharing?**
- Each account can allocate from shared pools
- Centralized IP management, distributed usage
- No overlapping CIDRs across accounts
- Share with OUs instead of individual accounts

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: org-ipam
  namespace: default
spec:
  providerConfigName: shared-services  # Run from shared-services account
  scope: private
  homeRegion: us-east-1
  operatingRegions: [us-east-1, us-west-2]

  pools:
    # Production pool - shared with Prod OU
    - name: prod-ipv4
      addressFamily: ipv4
      region: us-east-1
      cidr: 10.0.0.0/12
      allocationDefaultNetmaskLength: 20
      ramShareTargets:
        - ou: ou-abc1-prod  # Share with entire OU

    # Non-prod pool - shared with NonProd OU
    - name: nonprod-ipv4
      addressFamily: ipv4
      region: us-east-1
      cidr: 10.16.0.0/12
      allocationDefaultNetmaskLength: 20
      ramShareTargets:
        - ou: ou-abc1-nonprod

    # Shared services pool - specific account
    - name: shared-ipv4
      addressFamily: ipv4
      region: us-east-1
      cidr: 10.32.0.0/16
      allocationDefaultNetmaskLength: 24
      ramShareTargets:
        - account: "111111111111"
```

### Stage 5: Import Existing IPAM

Already have an IPAM? Import it along with existing pools.

**Why import?**
- Preserve existing allocations
- No disruption to running VPCs
- Gradually bring under Crossplane management

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IPAM
metadata:
  name: existing-ipam
  namespace: default
spec:
  # Import existing IPAM
  externalName: ipam-0123456789abcdef0
  managementPolicies: ["Create", "Observe", "Update", "LateInitialize"]

  providerConfigName: default
  scope: private
  homeRegion: us-east-1
  operatingRegions: [us-east-1]

  pools:
    - name: ipv4
      addressFamily: ipv4
      region: us-east-1
      cidr: 10.0.0.0/8
      # Import existing pool and its CIDR allocation
      externalName: ipam-pool-0123456789abcdef0
      cidrExternalName: 10.0.0.0/8_ipam-pool-0123456789abcdef0
      managementPolicies: ["Create", "Observe", "Update", "LateInitialize"]
      allocationDefaultNetmaskLength: 20
```

## Using IPAM Pools

Reference pool IDs from status when creating VPCs:

```yaml
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: VPC
spec:
  forProvider:
    region: us-east-1
    # IPv4 from IPAM
    ipv4IpamPoolId: ipam-pool-abc123  # From status.ipam.pools[name=ipv4].id
    ipv4NetmaskLength: 20
    # IPv6 from IPAM (for dual-stack)
    ipv6IpamPoolId: ipam-pool-xyz789  # From status.ipam.pools[name=ipv6-public].id
    ipv6NetmaskLength: 56
```

## Status

IPAM exposes pool IDs and CIDRs for downstream resources:

```yaml
status:
  ipam:
    id: ipam-0123456789abcdef0
    arn: arn:aws:ec2:us-east-1:111111111111:ipam/ipam-0123456789abcdef0
    privateDefaultScopeId: ipam-scope-abc123
    publicDefaultScopeId: ipam-scope-xyz789
    pools:
      - name: ipv4
        id: ipam-pool-abc123
        cidr: 10.0.0.0/8
        allocationDefaultNetmaskLength: 20
      - name: ipv6-public
        id: ipam-pool-xyz789
        cidr: 2600:1f26:47:c000::/52
        allocationDefaultNetmaskLength: 56
```

## IPv6 Pool Sizing Reference

| Level | Netmask | Addresses | Use |
|-------|---------|-----------|-----|
| IPAM Pool | /52 | 4,096 /64s | Regional allocation |
| VPC | /56 | 256 /64s | Per-VPC allocation |
| Subnet | /64 | 18 quintillion | Per-subnet |
| Node Prefix | /80 | ~65k addresses | EKS prefix delegation |

## Development

```bash
make render              # Render default example
make test                # Run tests
make validate            # Validate compositions
make e2e                 # E2E tests
```

## License

Apache-2.0
