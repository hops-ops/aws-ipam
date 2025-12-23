# e2etest-ipam - Persistent IPAM for dual-stack VPC provisioning
# ==============================================================
# Creates IPAM with IPv4 + IPv6 pools for VPC/subnet allocation.
# Resources are orphaned via managementPolicies (no Delete) for reuse.
#
# After first run, update externalName fields with actual IDs to import.
# These same resources are used by aws-foundation and aws-network e2e tests.
#
# Pools created (persistent):
# - ipv4: 10.0.0.0/8 for VPC IPv4 CIDRs
#   - ipv4-subnets: child pool for subnet allocations (auto-created)
# - ipv6-public: Amazon-provided GUA for internet-routable workloads (no subnet pool - AWS limitation)
# - ipv6-private: ULA /48 for private IPv6 workloads
#   - ipv6-private-subnets: child pool for IPv6 subnet allocations (auto-created)
#
# Pools created (ephemeral - deleted after test):
# - aws-ipam-<timestamp>: test pool with automatic subnet pool
# - aws-ipam-<timestamp>-subnets: auto-created child pool via subnetPool.enabled
# - ipv6-ula-<timestamp>: IPv6 ULA test pool with automatic subnet pool
# - ipv6-ula-<timestamp>-subnets: auto-created IPv6 child pool

import base64
import datetime
import file
import math
import models.ai.com.ops.hops.aws.v1alpha1 as hops
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_now = str(int(math.floor(datetime.ticks())))

_creds = file.read("secrets/aws-creds")
_base64_creds = base64.encode(_creds)

# =============================================================================
# Configuration - shared with aws-foundation e2e test
# =============================================================================

_org_name = "hops"
_composite_name = "hops-e2e-ipam"
_home_region = "us-east-2"

# Orphan management policies - no Delete means resources persist
_persist = ["Create", "Observe", "Update", "LateInitialize"]

# Ephemeral test pool names - deleted after test
_test_pool_name = "aws-ipam-" + _now
_test_pool_ipv6_ula = "ipv6-ula-" + _now
_test_pool_ipv6_gua = "ipv6-gua-" + _now

# =============================================================================
# Existing resource IDs (update after first successful run)
# =============================================================================
# After running once, get IDs with:
#   aws ec2 describe-ipams --query 'Ipams[*].[IpamId,Tags]'
#   aws ec2 describe-ipam-pools --query 'IpamPools[*].[IpamPoolId,Description]'
#   aws ec2 describe-ipam-pool-cidrs --ipam-pool-id <pool-id> --query 'IpamPoolCidrs[*].IpamPoolCidrId'
#
_ipam_external_name = "ipam-0573c7815d0a36e00"

# IPv4 pool (cidrExternalName format: cidr_pool-id)
_ipv4_pool_external_name = "ipam-pool-0a82c73b97dc0dabb"
_ipv4_cidr_external_name = "10.0.0.0/8" + "_" + _ipv4_pool_external_name

# IPv6 public pool - cidrExternalName format: cidr_pool-id
_ipv6_public_pool_external_name = "ipam-pool-06b3ec78deea8bcb9"
_ipv6_public_cidr_external_name = "2600:1f26:47:c000::/52" + "_" + _ipv6_public_pool_external_name

# IPv6 private pool (ULA) - cidrExternalName format: cidr_pool-id
_ipv6_private_pool_external_name = "ipam-pool-0decd6c5216660c74"
_ipv6_private_cidr_external_name = "fdc4:f045:5323::/48" + "_" + _ipv6_private_pool_external_name

# Subnet pools (child pools created via subnetPool.enabled)
# Update after first run with: aws ec2 describe-ipam-pools --query 'IpamPools[?contains(Description, `subnet`)].IpamPoolId'
_ipv4_subnet_pool_external_name = "ipam-pool-0eac78aa2a229f757"
_ipv6_private_subnet_pool_external_name = "ipam-pool-0888a212e86abbf13"

_items = [
    metav1alpha1.E2ETest{
        metadata.name: ""
        spec = {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                hops.IPAM{
                    metadata: {
                        name: _composite_name
                        namespace: "default"
                    }
                    spec: {
                        organizationName: _org_name
                        providerConfigName: "default"
                        managementPolicies: _persist
                        managementMode: "self"
                        scope: "private"
                        homeRegion: _home_region
                        operatingRegions: [_home_region]
                        if _ipam_external_name:
                            externalName: _ipam_external_name
                        pools: [
                            # IPv4 pool for VPCs with persistent subnet pool
                            {
                                name: "ipv4"
                                addressFamily: "ipv4"
                                region: _home_region
                                cidr: "10.0.0.0/8"
                                managementPolicies: _persist
                                allocationDefaultNetmaskLength: 20
                                allocationMinNetmaskLength: 16
                                allocationMaxNetmaskLength: 24
                                description: "IPv4 pool for VPCs"
                                if _ipv4_pool_external_name:
                                    externalName: _ipv4_pool_external_name
                                if _ipv4_cidr_external_name:
                                    cidrExternalName: _ipv4_cidr_external_name
                                labels: {
                                    "address-family": "ipv4"
                                    "hops.ops.com.ai/global-pool": "ipv4"
                                }
                                tags: {
                                    purpose: "vpc-ipv4"
                                }
                                # Persistent subnet pool for network allocations
                                subnetPool: {
                                    enabled: True
                                    managementPolicies: _persist
                                    if _ipv4_subnet_pool_external_name:
                                        externalName: _ipv4_subnet_pool_external_name
                                    allocationDefaultNetmaskLength: 24
                                    allocationMinNetmaskLength: 20
                                    allocationMaxNetmaskLength: 28
                                    description: "IPv4 subnet pool for network allocations"
                                    tags: {
                                        purpose: "subnet-ipv4"
                                    }
                                }
                            },
                            # IPv6 Public Pool (Amazon-provided GUA)
                            {
                                name: "ipv6-public"
                                addressFamily: "ipv6"
                                scope: "public"
                                region: _home_region
                                locale: _home_region
                                amazonProvidedIpv6CidrBlock: True
                                publicIpSource: "amazon"
                                awsService: "ec2"
                                netmaskLength: 52  # AWS provisions /52 GUA block (16 x /56 VPC allocations)
                                managementPolicies: _persist
                                allocationDefaultNetmaskLength: 56
                                allocationMinNetmaskLength: 52
                                allocationMaxNetmaskLength: 60
                                description: "Public IPv6 pool (Amazon GUA)"
                                if _ipv6_public_pool_external_name:
                                    externalName: _ipv6_public_pool_external_name
                                if _ipv6_public_cidr_external_name:
                                    cidrExternalName: _ipv6_public_cidr_external_name
                                labels: {
                                    "address-family": "ipv6"
                                    "ipv6-type": "public"
                                }
                                tags: {
                                    purpose: "vpc-ipv6-public"
                                }
                            },
                            # IPv6 Private Pool (ULA - AWS auto-assigns from fd00::/8) with persistent subnet pool
                            {
                                name: "ipv6-private"
                                addressFamily: "ipv6"
                                scope: "private"
                                region: _home_region
                                locale: _home_region
                                netmaskLength: 48  # AWS auto-assigns ULA CIDR
                                managementPolicies: _persist
                                allocationDefaultNetmaskLength: 56
                                allocationMinNetmaskLength: 48
                                allocationMaxNetmaskLength: 64
                                description: "Private IPv6 pool (ULA)"
                                if _ipv6_private_pool_external_name:
                                    externalName: _ipv6_private_pool_external_name
                                if _ipv6_private_cidr_external_name:
                                    cidrExternalName: _ipv6_private_cidr_external_name
                                labels: {
                                    "address-family": "ipv6"
                                    "ipv6-type": "private"
                                    "hops.ops.com.ai/global-pool": "ipv6-private"
                                }
                                tags: {
                                    purpose: "vpc-ipv6-private"
                                }
                                # Persistent subnet pool for network allocations (inherits ipv6)
                                subnetPool: {
                                    enabled: True
                                    managementPolicies: _persist
                                    if _ipv6_private_subnet_pool_external_name:
                                        externalName: _ipv6_private_subnet_pool_external_name
                                    allocationDefaultNetmaskLength: 64
                                    allocationMinNetmaskLength: 56
                                    allocationMaxNetmaskLength: 64
                                    description: "IPv6 ULA subnet pool for network allocations"
                                    tags: {
                                        purpose: "subnet-ipv6-private"
                                    }
                                }
                            },
                            # Ephemeral test pool - deleted after test run
                            # Uses subnetPool.enabled to auto-create child subnet pool
                            {
                                name: _test_pool_name
                                addressFamily: "ipv4"
                                region: _home_region
                                cidr: "172.31.0.0/16"
                                # Full management - gets deleted
                                managementPolicies: ["*"]
                                allocationDefaultNetmaskLength: 24
                                allocationMinNetmaskLength: 20
                                allocationMaxNetmaskLength: 28
                                description: "Ephemeral test pool - " + _test_pool_name
                                labels: {
                                    "ephemeral": "true"
                                    "test-run": _now
                                    "hops.ops.com.ai/global-pool": _test_pool_name
                                }
                                tags: {
                                    purpose: "e2e-test"
                                    "test-run": _now
                                }
                                # Auto-create subnet pool named ${name}-subnets
                                subnetPool: {
                                    enabled: True
                                    allocationDefaultNetmaskLength: 28
                                    allocationMinNetmaskLength: 26
                                    allocationMaxNetmaskLength: 28
                                    description: "Auto-created subnet pool for " + _test_pool_name
                                    tags: {
                                        purpose: "e2e-test-subnet-pool"
                                        "test-run": _now
                                    }
                                }
                            },
                            # Ephemeral IPv6 Private Pool (ULA) with subnet pool
                            # Tests that subnetPool inherits addressFamily: ipv6 from parent
                            {
                                name: _test_pool_ipv6_ula
                                addressFamily: "ipv6"
                                scope: "private"
                                region: _home_region
                                locale: _home_region
                                netmaskLength: 56  # AWS auto-assigns ULA CIDR
                                managementPolicies: ["*"]
                                allocationDefaultNetmaskLength: 60
                                allocationMinNetmaskLength: 56
                                allocationMaxNetmaskLength: 64
                                description: "Ephemeral IPv6 ULA test pool - " + _test_pool_ipv6_ula
                                labels: {
                                    "ephemeral": "true"
                                    "test-run": _now
                                    "address-family": "ipv6"
                                    "ipv6-type": "private-ula"
                                }
                                tags: {
                                    purpose: "e2e-test-ipv6-ula"
                                    "test-run": _now
                                }
                                # Auto-create subnet pool - should inherit ipv6 addressFamily
                                subnetPool: {
                                    enabled: True
                                    allocationDefaultNetmaskLength: 64
                                    allocationMinNetmaskLength: 60
                                    allocationMaxNetmaskLength: 64
                                    description: "Auto-created IPv6 ULA subnet pool for " + _test_pool_ipv6_ula
                                    tags: {
                                        purpose: "e2e-test-ipv6-ula-subnet-pool"
                                        "test-run": _now
                                    }
                                }
                            }
                        ]
                    }
                }
            ]
            extraResources: [
                {
                    apiVersion: "v1"
                    kind: "Secret"
                    metadata: {
                        name: "aws-creds"
                        namespace: "default"
                    }
                    data: {
                        creds: _base64_creds
                    }
                },
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"
                    }
                    spec: {
                        credentials: {
                            source: "Secret"
                            secretRef: {
                                namespace: "default"
                                name: "aws-creds"
                                key: "creds"
                            }
                        }
                    }
                }
            ]
            skipDelete: True
            timeoutSeconds: 4500
        }
    }
]
items = _items
