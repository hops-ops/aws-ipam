# e2etest-ipam - Persistent IPAM for dual-stack VPC provisioning
# ==============================================================
# Creates IPAM with Global + Regional pools for VPC allocation.
# Pools are persistent (orphaned via managementPolicies without Delete).
#
# Architecture (per foundation-design/00-overview.md):
# - IPAM creates: Global pools + Regional pools
# - Network creates: VPC Pool allocations from regional pools, VPC, Subnet pools, Allocations
#
# After first run, update externalName fields with actual IDs to import.
# These resources are used by aws-foundation and aws-network e2e tests.
#
# Pool hierarchy:
#   pools.ipv4:
#     ipv4 (10.0.0.0/8) - global, allocates /12 regional pools
#       └── ipv4-us-east-2 (10.0.0.0/12) - regional, allocates /16 VPCs
#   pools.ipv6.ula:
#     ipv6-private (/32 ULA) - global, allocates /48 regional pools
#       └── ipv6-private-us-east-2 (/48) - regional, allocates /56 VPCs
#   pools.ipv6.gua:
#     ipv6-public (/52 GUA) - global, Amazon-provided

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
_ipv4_regional_useast2_external_name = "ipam-pool-0607416fa3707147a"
_ipv4_regional_useast2_cidr_external_name = "10.0.0.0/12" + "_" + _ipv4_regional_useast2_external_name

# IPv6 public pool (Amazon GUA) - cidrExternalName format: cidr_pool-id
_ipv6_public_pool_external_name = "ipam-pool-06b3ec78deea8bcb9"
_ipv6_public_cidr_external_name = "2600:1f26:47:c000::/52" + "_" + _ipv6_public_pool_external_name

# IPv6 private pool (ULA /32) - will be recreated with new size
# Clear external names to recreate with correct hierarchy
_ipv6_private_pool_external_name = "ipam-pool-02261bfded584dbfb"
_ipv6_private_cidr_external_name = "fda0:daf7::/32" + "_" + _ipv6_private_pool_external_name

# Regional IPv6 private pool for us-east-2 (child of global ULA, /48)
# Clear external names to recreate with correct hierarchy
_ipv6_private_regional_useast2_external_name = "ipam-pool-0ca730678e463dbfc"
_ipv6_private_regional_useast2_cidr_external_name = "fda0:daf7:1::/48" + "_" + _ipv6_private_regional_useast2_external_name

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
                        pools: {
                            # ==========================================================
                            # IPv4 POOLS
                            # ==========================================================
                            ipv4: [
                                # Global IPv4 pool - top of hierarchy
                                {
                                    name: "ipv4"
                                    region: _home_region
                                    cidr: "10.0.0.0/8"
                                    managementPolicies: _persist
                                    # Allocations from this pool are /12 regional pools
                                    allocations: {
                                        netmaskLength: {
                                            default: 12
                                            min: 12
                                            max: 12
                                        }
                                    }
                                    description: "Global IPv4 pool (/8, allocates /12 regional pools)"
                                    if _ipv4_global_pool_external_name:
                                        externalName: _ipv4_global_pool_external_name
                                    if _ipv4_global_cidr_external_name:
                                        cidrExternalName: _ipv4_global_cidr_external_name
                                    labels: {
                                        "pool-type": "global"
                                        "hops.ops.com.ai/global-pool": "ipv4"
                                    }
                                    tags: {
                                        "hops.ops.com.ai/e2e": "true",
                                        "hops.ops.com.ai/e2e-persistent": "true"
                                    }
                                },

                                # Regional IPv4 pool - us-east-2
                                # Child of global ipv4 pool. NetworkAllocation uses this.
                                {
                                    name: "ipv4-us-east-2"
                                    sourcePoolRef: "ipv4"  # Child of global pool
                                    region: _home_region
                                    locale: _home_region
                                    cidr: "10.0.0.0/12"  # 10.0.0.0 - 10.15.255.255
                                    managementPolicies: _persist
                                    # Allocations from this pool are /16-/20 VPCs
                                    allocations: {
                                        netmaskLength: {
                                            default: 16
                                            min: 16
                                            max: 16
                                        }
                                    }
                                    description: "Regional IPv4 pool for us-east-2 (/12, allocates /16 VPCs)"
                                    if _ipv4_regional_useast2_external_name:
                                        externalName: _ipv4_regional_useast2_external_name
                                    if _ipv4_regional_useast2_cidr_external_name:
                                        cidrExternalName: _ipv4_regional_useast2_cidr_external_name
                                    labels: {
                                        "pool-type": "regional"
                                        "region": "us-east-2"
                                    }
                                    tags: {
                                        "hops.ops.com.ai/e2e": "true",
                                        "hops.ops.com.ai/e2e-persistent": "true"
                                    }
                                },

                                # Ephemeral test pool - deleted after test
                                {
                                    name: _test_pool_name
                                    region: _home_region
                                    cidr: "172.31.0.0/16"
                                    managementPolicies: ["*"]  # Full management - gets deleted
                                    allocations: {
                                        netmaskLength: {
                                            default: 24
                                            min: 20
                                            max: 28
                                        }
                                    }
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
                                }
                            ],

                            # ==========================================================
                            # IPv6 POOLS
                            # ==========================================================
                            ipv6: {
                                # ULA pools (private, fd00::/8)
                                ula: [
                                    # Global IPv6 private pool - ULA /32
                                    # Hierarchy: /32 global → /48 regional → /56 VPC → /64 subnet
                                    {
                                        name: "ipv6-private"
                                        region: _home_region
                                        locale: _home_region
                                        netmaskLength: 32
                                        managementPolicies: _persist
                                        # Allocations are /48 regional pools
                                        allocations: {
                                            netmaskLength: {
                                                default: 48
                                                min: 48
                                                max: 48
                                            }
                                        }
                                        description: "Global IPv6 private pool (ULA /32, allocates /48 regional pools)"
                                        if _ipv6_private_pool_external_name:
                                            externalName: _ipv6_private_pool_external_name
                                        if _ipv6_private_cidr_external_name:
                                            cidrExternalName: _ipv6_private_cidr_external_name
                                        labels: {
                                            "pool-type": "global"
                                            "hops.ops.com.ai/global-pool": "ipv6-private"
                                        }
                                        tags: {
                                            "hops.ops.com.ai/e2e": "true",
                                            "hops.ops.com.ai/e2e-persistent": "true"
                                        }
                                    },

                                    # Regional IPv6 private pool - us-east-2
                                    # Child of global ipv6-private pool. 
                                    {
                                        name: "ipv6-private-us-east-2"
                                        sourcePoolRef: "ipv6-private"  # Child of global ULA pool
                                        region: _home_region
                                        locale: _home_region
                                        netmaskLength: 48  # Allocated from parent's /32
                                        managementPolicies: _persist
                                        # Allocations from this pool are /56 VPCs (AWS requires /56 for VPC IPv6)
                                        allocations: {
                                            netmaskLength: {
                                                default: 56
                                                min: 56
                                                max: 56
                                            }
                                        }
                                        description: "Regional IPv6 private pool for us-east-2 (/48, allocates /56 VPCs)"
                                        if _ipv6_private_regional_useast2_external_name:
                                            externalName: _ipv6_private_regional_useast2_external_name
                                        if _ipv6_private_regional_useast2_cidr_external_name:
                                            cidrExternalName: _ipv6_private_regional_useast2_cidr_external_name
                                        labels: {
                                            "pool-type": "regional"
                                            "region": "us-east-2"
                                        }
                                        tags: {
                                            "hops.ops.com.ai/e2e": "true",
                                            "hops.ops.com.ai/e2e-persistent": "true"
                                        }
                                    },

                                    # Ephemeral IPv6 ULA test pool - deleted after test
                                    {
                                        name: _test_pool_ipv6_ula
                                        sourcePoolRef: "ipv6-private"
                                        region: _home_region
                                        locale: _home_region
                                        netmaskLength: 48  # Allocated from parent's /32
                                        managementPolicies: ["*"]  # Full management - gets deleted
                                        allocations: {
                                            netmaskLength: {
                                                default: 56
                                                min: 56
                                                max: 56
                                            }
                                        }
                                        description: "Ephemeral IPv6 ULA test pool - " + _test_pool_ipv6_ula
                                        labels: {
                                            "ephemeral": "true"
                                            "test-run": _now
                                        }
                                        tags: {
                                            "hops.ops.com.ai/e2e": "true",
                                            "hops.ops.com.ai/e2e-persistent": "false",
                                            "hops.ops.com.ai/e2e-last-run": _now
                                        }
                                    }
                                ],

                                # GUA pools (public, Amazon-provided)
                                gua: [
                                    # Global IPv6 public pool - Amazon GUA
                                    {
                                        name: "ipv6-public"
                                        region: _home_region
                                        locale: _home_region
                                        netmaskLength: 52  # AWS provisions /52 GUA block
                                        managementPolicies: _persist
                                        # Allocations are /56 per VPC
                                        allocations: {
                                            netmaskLength: {
                                                default: 56
                                                min: 52
                                                max: 60
                                            }
                                        }
                                        description: "Global IPv6 public pool (Amazon GUA)"
                                        if _ipv6_public_pool_external_name:
                                            externalName: _ipv6_public_pool_external_name
                                        if _ipv6_public_cidr_external_name:
                                            cidrExternalName: _ipv6_public_cidr_external_name
                                        labels: {
                                            "pool-type": "global"
                                        }
                                        tags: {
                                            "hops.ops.com.ai/e2e": "true",
                                            "hops.ops.com.ai/e2e-persistent": "true"
                                        }
                                    }
                                ]
                            }
                        }
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
