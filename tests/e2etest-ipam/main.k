# e2etest-ipam - Persistent IPAM for dual-stack VPC provisioning
# ==============================================================
# Creates IPAM with Global + Regional pools for VPC allocation.
# Pools are persistent (orphaned via managementPolicies without Delete).
#
# Architecture (per foundation-design/00-overview.md):
# - IPAM creates: Global pools + Regional pools
# - NetworkAllocation creates: VPC pool, Subnet pools, Allocations
#
# After first run, update externalName fields with actual IDs to import.
# These resources are used by aws-foundation and aws-network e2e tests.
#
# Pool hierarchy:
#   ipv4 (10.0.0.0/8) - global
#     └── ipv4-us-east-2 (10.0.0.0/12) - regional, allocates /16 VPCs
#   ipv6-private (/32 ULA) - global
#     └── (regional pools TBD)
#   ipv6-public (/52 GUA) - global, Amazon-provided

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

_composite_name = "hops-e2e-ipam"
_home_region = "us-east-2"

# Orphan management policies - no Delete means resources persist
_persist = ["Create", "Observe", "Update", "LateInitialize"]

# Ephemeral test pool names - deleted after test
_test_pool_name = "test-ipv4-" + _now
_test_pool_ipv6_ula = "test-ipv6-ula-" + _now

# =============================================================================
# Existing resource IDs (update after first successful run)
# =============================================================================
# After running once, get IDs with:
#   aws ec2 describe-ipams --query 'Ipams[*].[IpamId,Tags]'
#   aws ec2 describe-ipam-pools --query 'IpamPools[*].[IpamPoolId,Description]'
#   aws ec2 describe-ipam-pool-cidrs --ipam-pool-id <pool-id>
#
_ipam_external_name = "ipam-0573c7815d0a36e00"

# Global IPv4 pool (cidrExternalName format: cidr_pool-id)
_ipv4_global_pool_external_name = "ipam-pool-0a82c73b97dc0dabb"
_ipv4_global_cidr_external_name = "10.0.0.0/8" + "_" + _ipv4_global_pool_external_name

# Regional IPv4 pool for us-east-2 (child of global)
# Update after first run with: aws ec2 describe-ipam-pools --query 'IpamPools[?contains(Description, `regional`)].IpamPoolId'
_ipv4_regional_useast2_external_name = ""  # Update after first run
_ipv4_regional_useast2_cidr_external_name = ""  # Update after first run

# IPv6 public pool (Amazon GUA) - cidrExternalName format: cidr_pool-id
_ipv6_public_pool_external_name = "ipam-pool-06b3ec78deea8bcb9"
_ipv6_public_cidr_external_name = "2600:1f26:47:c000::/52" + "_" + _ipv6_public_pool_external_name

# IPv6 private pool (ULA /32) - will be new pool
# Note: /32 is the largest ULA block AWS allows
_ipv6_private_pool_external_name = ""  # Update after first run
_ipv6_private_cidr_external_name = ""  # Will be auto-assigned ULA /32

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
                        managementPolicies: _persist
                        region: _home_region
                        operatingRegions: [_home_region]
                        if _ipam_external_name:
                            externalName: _ipam_external_name
                        pools: [
                            # ==========================================================
                            # GLOBAL IPv4 POOL - Top of hierarchy
                            # ==========================================================
                            {
                                name: "ipv4"
                                addressFamily: "ipv4"
                                region: _home_region
                                cidr: "10.0.0.0/8"
                                managementPolicies: _persist
                                # Allocations from this pool are /12 regional pools
                                allocationDefaultNetmaskLength: 12
                                allocationMinNetmaskLength: 10
                                allocationMaxNetmaskLength: 16
                                description: "Global IPv4 pool"
                                if _ipv4_global_pool_external_name:
                                    externalName: _ipv4_global_pool_external_name
                                if _ipv4_global_cidr_external_name:
                                    cidrExternalName: _ipv4_global_cidr_external_name
                                labels: {
                                    "address-family": "ipv4"
                                    "pool-type": "global"
                                    "hops.ops.com.ai/global-pool": "ipv4"
                                }
                                tags: {
                                    "hops.ops.com.ai/e2e": "true",
                                    "hops.ops.com.ai/e2e-persistent": "true"
                                }
                            },

                            # ==========================================================
                            # REGIONAL IPv4 POOL - us-east-2
                            # Child of global ipv4 pool. NetworkAllocation uses this.
                            # ==========================================================
                            {
                                name: "ipv4-us-east-2"
                                addressFamily: "ipv4"
                                sourcePoolRef: "ipv4"  # Child of global pool
                                region: _home_region
                                locale: _home_region
                                cidr: "10.0.0.0/12"  # 10.0.0.0 - 10.15.255.255
                                managementPolicies: _persist
                                # Allocations from this pool are /16-/20 VPCs
                                allocationDefaultNetmaskLength: 16
                                allocationMinNetmaskLength: 16
                                allocationMaxNetmaskLength: 20
                                description: "Regional IPv4 pool for us-east-2"
                                if _ipv4_regional_useast2_external_name:
                                    externalName: _ipv4_regional_useast2_external_name
                                if _ipv4_regional_useast2_cidr_external_name:
                                    cidrExternalName: _ipv4_regional_useast2_cidr_external_name
                                labels: {
                                    "address-family": "ipv4"
                                    "pool-type": "regional"
                                    "region": "us-east-2"
                                }
                                tags: {
                                    "hops.ops.com.ai/e2e": "true",
                                    "hops.ops.com.ai/e2e-persistent": "true"
                                }
                            },

                            # ==========================================================
                            # GLOBAL IPv6 PUBLIC POOL - Amazon GUA
                            # For internet-routable workloads
                            # ==========================================================
                            {
                                name: "ipv6-public"
                                addressFamily: "ipv6"
                                scope: "public"
                                region: _home_region
                                locale: _home_region
                                amazonProvidedIpv6CidrBlock: True
                                publicIpSource: "amazon"
                                awsService: "ec2"
                                netmaskLength: 52  # AWS provisions /52 GUA block
                                managementPolicies: _persist
                                # Allocations are /56 per VPC
                                allocationDefaultNetmaskLength: 56
                                allocationMinNetmaskLength: 52
                                allocationMaxNetmaskLength: 60
                                description: "Global IPv6 public pool (Amazon GUA)"
                                if _ipv6_public_pool_external_name:
                                    externalName: _ipv6_public_pool_external_name
                                if _ipv6_public_cidr_external_name:
                                    cidrExternalName: _ipv6_public_cidr_external_name
                                labels: {
                                    "address-family": "ipv6"
                                    "pool-type": "global"
                                    "ipv6-type": "public"
                                }
                                tags: {
                                    "hops.ops.com.ai/e2e": "true",
                                    "hops.ops.com.ai/e2e-persistent": "true"
                                }
                            },

                            # ==========================================================
                            # GLOBAL IPv6 PRIVATE POOL - ULA /48
                            # ==========================================================
                            {
                                name: "ipv6-private"
                                addressFamily: "ipv6"
                                scope: "private"
                                region: _home_region
                                locale: _home_region
                                netmaskLength: 48  # Largest ULA block AWS allows
                                managementPolicies: _persist
                                # Allocations are /48 regional pools or /56 VPCs
                                allocationDefaultNetmaskLength: 56
                                allocationMinNetmaskLength: 56
                                allocationMaxNetmaskLength: 56
                                description: "Global IPv6 private pool (ULA /32)"
                                if _ipv6_private_pool_external_name:
                                    externalName: _ipv6_private_pool_external_name
                                if _ipv6_private_cidr_external_name:
                                    cidrExternalName: _ipv6_private_cidr_external_name
                                labels: {
                                    "address-family": "ipv6"
                                    "pool-type": "global"
                                    "ipv6-type": "private"
                                    "hops.ops.com.ai/global-pool": "ipv6-private"
                                }
                                tags: {
                                    "hops.ops.com.ai/e2e": "true",
                                    "hops.ops.com.ai/e2e-persistent": "true"
                                }
                            },

                            # ==========================================================
                            # EPHEMERAL TEST POOLS - deleted after test
                            # Tests that pool creation/deletion works correctly
                            # ==========================================================
                            {
                                name: _test_pool_name
                                addressFamily: "ipv4"
                                region: _home_region
                                cidr: "172.31.0.0/16"
                                managementPolicies: ["*"]  # Full management - gets deleted
                                allocationDefaultNetmaskLength: 24
                                allocationMinNetmaskLength: 20
                                allocationMaxNetmaskLength: 28
                                description: "Ephemeral test pool - " + _test_pool_name
                                labels: {
                                    "ephemeral": "true"
                                    "test-run": _now
                                }
                                tags: {
                                    "hops.ops.com.ai/e2e": "true",
                                    "hops.ops.com.ai/e2e-persistent": "false",
                                    "hops.ops.com.ai/e2e-last-run": _now
                                }
                            },
                            {
                                name: _test_pool_ipv6_ula
                                addressFamily: "ipv6"
                                sourcePoolRef: "ipv6-private"
                                region: _home_region
                                locale: _home_region
                                netmaskLength: 56  # Allocated from parent's /48
                                managementPolicies: ["*"]  # Full management - gets deleted
                                allocationDefaultNetmaskLength: 60
                                allocationMinNetmaskLength: 56
                                allocationMaxNetmaskLength: 64
                                description: "Ephemeral IPv6 ULA test pool - " + _test_pool_ipv6_ula
                                labels: {
                                    "ephemeral": "true"
                                    "test-run": _now
                                    "address-family": "ipv6"
                                }
                                tags: {
                                    "hops.ops.com.ai/e2e": "true",
                                    "hops.ops.com.ai/e2e-persistent": "false",
                                    "hops.ops.com.ai/e2e-last-run": _now
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
            skipDelete: False
            timeoutSeconds: 4500
        }
    }
]
items = _items
