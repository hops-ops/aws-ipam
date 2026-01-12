
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

# =============================================================================
# Unit Tests for AWS IPAM Configuration
# =============================================================================
# Philosophy: Test YOUR API behavior, not the provider's API.
# - Conditional rendering: When flag X is set, these resources render
# - Configuration mapping: When flag Y is set, provider resources configure correctly
# - Default values: When field Z is omitted, it defaults appropriately
# - Edge cases: When A and B are set, the interaction produces expected output
# =============================================================================

_items = [

    # =========================================================================
    # Test: Basic IPAM renders with correct defaults
    # =========================================================================
    # When: Minimal spec with required fields only
    # Then: IPAM renders with default managementPolicies, default providerConfig, default tags
    metav1alpha1.CompositionTest{
        metadata.name = "basic-ipam-defaults"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-defaults"
                spec = {
                    region = "us-west-2"
                    pools.ipv4 = [{name = "default-pool", cidr = "10.0.0.0/8"}]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-defaults"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-test"
                            privateDefaultScopeId = "ipam-scope-private-test"
                            publicDefaultScopeId = "ipam-scope-public-test"
                        }
                    }
                }
            ]
            assertResources = [
                # IPAM should have default managementPolicies and providerConfig
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata.name = "test-defaults"
                    spec = {
                        managementPolicies = ["*"]
                        providerConfigRef = {name = "default", kind = "ProviderConfig"}
                        forProvider.tags = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/ipam" = "test-defaults"
                        }
                    }
                }
                # Pool should inherit defaults
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-defaults-default-pool"
                    spec = {
                        managementPolicies = ["*"]
                        providerConfigRef = {name = "default", kind = "ProviderConfig"}
                        forProvider.tags = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/ipam" = "test-defaults"
                            "hops.ops.com.ai/ipam-pool" = "default-pool"
                        }
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Custom providerConfigRef with kind=ClusterProviderConfig
    # =========================================================================
    # When: providerConfigRef.kind = ClusterProviderConfig
    # Then: All resources use the specified kind
    metav1alpha1.CompositionTest{
        metadata.name = "cluster-provider-config"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-cluster-pc"
                spec = {
                    region = "us-east-1"
                    providerConfigRef = {
                        name = "my-cluster-config"
                        kind = "ClusterProviderConfig"
                    }
                    pools.ipv4 = [{name = "pool", cidr = "172.16.0.0/12"}]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-cluster-pc"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-cluster"
                            privateDefaultScopeId = "ipam-scope-private-cluster"
                            publicDefaultScopeId = "ipam-scope-public-cluster"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata.name = "test-cluster-pc"
                    spec.providerConfigRef = {
                        name = "my-cluster-config"
                        kind = "ClusterProviderConfig"
                    }
                }
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-cluster-pc-pool"
                    spec.providerConfigRef = {
                        name = "my-cluster-config"
                        kind = "ClusterProviderConfig"
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Tags merge with defaults
    # =========================================================================
    # When: Custom tags provided in pool config
    # Then: Tags merge with default managed/ipam tags
    metav1alpha1.CompositionTest{
        metadata.name = "tags-merge-with-defaults"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-tags"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [{
                        name = "tagged-pool"
                        cidr = "10.0.0.0/8"
                        tags = {
                            Environment = "production"
                            Team = "platform"
                        }
                    }]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-tags"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-tags"
                            privateDefaultScopeId = "ipam-scope-private-tags"
                            publicDefaultScopeId = "ipam-scope-public-tags"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-tags-tagged-pool"
                    spec.forProvider.tags = {
                        "hops.ops.com.ai/managed" = "true"
                        "hops.ops.com.ai/ipam" = "test-tags"
                        "hops.ops.com.ai/ipam-pool" = "tagged-pool"
                        Environment = "production"
                        Team = "platform"
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Operating regions auto-computed from pool regions
    # =========================================================================
    # When: Pools have different regions/locales
    # Then: IPAM operatingRegions includes all unique regions
    metav1alpha1.CompositionTest{
        metadata.name = "operating-regions-auto-computed"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-regions"
                spec = {
                    region = "us-east-1"
                    operatingRegions = ["eu-west-1"]
                    pools.ipv4 = [
                        {name = "global", cidr = "10.0.0.0/8"}
                        {name = "us-west", cidr = "10.1.0.0/16", locale = "us-west-2"}
                    ]
                }
            }
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata.name = "test-regions"
                    spec.forProvider.operatingRegions = [
                        {regionName = "eu-west-1"}
                        {regionName = "us-east-1"}
                        {regionName = "us-west-2"}
                    ]
                }
            ]
        }
    }

    # =========================================================================
    # Test: Pool allocation constraints
    # =========================================================================
    # When: Pool has allocation netmask constraints
    # Then: VPCIpamPool has correct allocation fields
    metav1alpha1.CompositionTest{
        metadata.name = "pool-allocation-constraints"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-alloc"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [{
                        name = "constrained"
                        cidr = "10.0.0.0/8"
                        allocations.netmaskLength = {
                            default = 16
                            min = 16
                            max = 24
                        }
                    }]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-alloc"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-alloc"
                            privateDefaultScopeId = "ipam-scope-private-alloc"
                            publicDefaultScopeId = "ipam-scope-public-alloc"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-alloc-constrained"
                    spec.forProvider = {
                        allocationDefaultNetmaskLength = 16
                        allocationMinNetmaskLength = 16
                        allocationMaxNetmaskLength = 24
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: IPv4 pool with locale creates localized pool
    # =========================================================================
    # When: IPv4 pool has locale set
    # Then: VPCIpamPool has locale field
    metav1alpha1.CompositionTest{
        metadata.name = "pool-with-locale"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-locale"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [{
                        name = "regional"
                        cidr = "10.0.0.0/16"
                        locale = "us-west-2"
                        region = "us-east-1"
                    }]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-locale"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-locale"
                            privateDefaultScopeId = "ipam-scope-private-locale"
                            publicDefaultScopeId = "ipam-scope-public-locale"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-locale-regional"
                    spec.forProvider = {
                        locale = "us-west-2"
                        region = "us-east-1"
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: IPv6 ULA pool uses private scope
    # =========================================================================
    # When: IPv6 ULA pool defined
    # Then: Pool uses privateDefaultScopeId and addressFamily=ipv6
    metav1alpha1.CompositionTest{
        metadata.name = "ipv6-ula-uses-private-scope"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-ula"
                spec = {
                    region = "us-east-1"
                    pools = {
                        ipv4 = [{name = "v4", cidr = "10.0.0.0/8"}]
                        ipv6.ula = [{
                            name = "private-v6"
                            netmaskLength = 48
                            allocations.netmaskLength.default = 56
                        }]
                    }
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-ula"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-ula"
                            privateDefaultScopeId = "ipam-scope-private-ula"
                            publicDefaultScopeId = "ipam-scope-public-ula"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-ula-private-v6"
                    spec.forProvider = {
                        addressFamily = "ipv6"
                        ipamScopeId = "ipam-scope-private-ula"
                        allocationDefaultNetmaskLength = 56
                    }
                }
                # CIDR should use netmaskLength for ULA
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPoolCidr"
                    metadata.name = "test-ula-private-v6-cidr"
                    spec.forProvider.netmaskLength = 48
                }
            ]
        }
    }

    # =========================================================================
    # Test: IPv6 GUA pool uses public scope with Amazon-provided CIDR
    # =========================================================================
    # When: IPv6 GUA pool defined
    # Then: Pool uses publicDefaultScopeId, publicIpSource=amazon, awsService=ec2
    metav1alpha1.CompositionTest{
        metadata.name = "ipv6-gua-uses-public-scope"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-gua"
                spec = {
                    region = "us-east-1"
                    pools = {
                        ipv4 = [{name = "v4", cidr = "10.0.0.0/8"}]
                        ipv6.gua = [{
                            name = "public-v6"
                            netmaskLength = 52
                            allocations.netmaskLength.default = 56
                        }]
                    }
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-gua"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-gua"
                            privateDefaultScopeId = "ipam-scope-private-gua"
                            publicDefaultScopeId = "ipam-scope-public-gua"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-gua-public-v6"
                    spec.forProvider = {
                        addressFamily = "ipv6"
                        ipamScopeId = "ipam-scope-public-gua"
                        publicIpSource = "amazon"
                        awsService = "ec2"
                        allocationDefaultNetmaskLength = 56
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Child pool waits for parent pool to be ready
    # =========================================================================
    # When: Child pool (sourcePoolRef) defined but parent not ready
    # Then: Child pool does NOT render
    metav1alpha1.CompositionTest{
        metadata.name = "child-pool-waits-for-parent"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-child-wait"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [
                        {name = "parent", cidr = "10.0.0.0/8"}
                        {name = "child", sourcePoolRef = "parent", cidr = "10.0.0.0/16"}
                    ]
                }
            }
            # IPAM ready but parent pool NOT observed - child should not render
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-child-wait"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-child-wait"
                            privateDefaultScopeId = "ipam-scope-private-child"
                            publicDefaultScopeId = "ipam-scope-public-child"
                        }
                    }
                }
            ]
            # Only parent pool should render - child is gated
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-child-wait-parent"
                    spec.forProvider.addressFamily = "ipv4"
                }
            ]
        }
    }

    # =========================================================================
    # Test: Child pool renders with parent pool ID when parent is ready
    # =========================================================================
    # When: Parent pool is observed as ready
    # Then: Child pool renders with sourceIpamPoolId and inherited ipamScopeId
    metav1alpha1.CompositionTest{
        metadata.name = "child-pool-uses-parent-ids"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-child"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [
                        {name = "parent", cidr = "10.0.0.0/8"}
                        {name = "child", sourcePoolRef = "parent", cidr = "10.0.0.0/16"}
                    ]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-child"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-child"
                            privateDefaultScopeId = "ipam-scope-private-child"
                            publicDefaultScopeId = "ipam-scope-public-child"
                        }
                    }
                }
                # Parent pool is ready
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata = {
                        name = "test-child-parent"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam-pool-parent"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-pool-parent-123"
                            arn = "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-parent-123"
                            ipamScopeId = "ipam-scope-private-child"
                        }
                    }
                }
            ]
            assertResources = [
                # Child pool should have sourceIpamPoolId and inherited scope
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-child-child"
                    spec.forProvider = {
                        sourceIpamPoolId = "ipam-pool-parent-123"
                        ipamScopeId = "ipam-scope-private-child"
                        addressFamily = "ipv4"
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: External name annotation for IPAM adoption
    # =========================================================================
    # When: spec.externalName is set
    # Then: VPCIpam has crossplane.io/external-name annotation
    metav1alpha1.CompositionTest{
        metadata.name = "ipam-external-name-adoption"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-adopt"
                spec = {
                    region = "us-east-1"
                    externalName = "ipam-0123456789abcdef0"
                    pools.ipv4 = [{name = "pool", cidr = "10.0.0.0/8"}]
                }
            }
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-adopt"
                        annotations = {"crossplane.io/external-name" = "ipam-0123456789abcdef0"}
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Pool external name annotation for adoption
    # =========================================================================
    # When: imports.pools and imports.poolCidrs are set
    # Then: VPCIpamPool and VPCIpamPoolCidr have crossplane.io/external-name annotation
    metav1alpha1.CompositionTest{
        metadata.name = "pool-external-name-adoption"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-adopt-pool"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [{
                        name = "adopted"
                        cidr = "10.0.0.0/8"
                        externalName = "ipam-pool-0123456789abcdef0"
                        cidrExternalName = "10.0.0.0/8_ipam-pool-0123456789abcdef0"
                    }]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-adopt-pool"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-adopt"
                            privateDefaultScopeId = "ipam-scope-private-adopt"
                            publicDefaultScopeId = "ipam-scope-public-adopt"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata = {
                        name = "test-adopt-pool-adopted"
                        annotations = {"crossplane.io/external-name" = "ipam-pool-0123456789abcdef0"}
                    }
                }
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPoolCidr"
                    metadata = {
                        name = "test-adopt-pool-adopted-cidr"
                        annotations = {"crossplane.io/external-name" = "10.0.0.0/8_ipam-pool-0123456789abcdef0"}
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Custom scope renders VPCIpamScope
    # =========================================================================
    # When: spec.scopes defined
    # Then: VPCIpamScope resources are created
    metav1alpha1.CompositionTest{
        metadata.name = "custom-scope-renders"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-scope"
                spec = {
                    region = "us-east-1"
                    scopes = [{
                        name = "team-a"
                        description = "Isolated scope for Team A"
                        tags = {team = "a"}
                    }]
                    pools.ipv4 = [{name = "pool", cidr = "10.0.0.0/8"}]
                }
            }
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamScope"
                    metadata = {
                        name = "test-scope-scope-team-a"
                        labels = {"hops.ops.com.ai/ipam-scope" = "team-a"}
                    }
                    spec.forProvider = {
                        description = "Isolated scope for Team A"
                        ipamIdRef.name = "test-scope"
                        tags = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/ipam" = "test-scope"
                            "hops.ops.com.ai/ipam-scope" = "team-a"
                            team = "a"
                        }
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Pool with scopeRef uses custom scope
    # =========================================================================
    # When: Pool has scopeRef pointing to a custom scope
    # Then: VPCIpamPool uses ipamScopeIdRef instead of ipamScopeId
    metav1alpha1.CompositionTest{
        metadata.name = "pool-uses-custom-scope"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-scope-ref"
                spec = {
                    region = "us-east-1"
                    scopes = [{name = "custom"}]
                    pools.ipv4 = [{
                        name = "scoped-pool"
                        cidr = "10.0.0.0/8"
                        scopeRef = "custom"
                    }]
                }
            }
            # No observed resources needed - scopeRef uses ipamScopeIdRef
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-scope-ref-scoped-pool"
                    spec.forProvider.ipamScopeIdRef.name = "test-scope-ref-scope-custom"
                }
            ]
        }
    }

    # =========================================================================
    # Test: Management policies cascade from global to pool
    # =========================================================================
    # When: Pool has no managementPolicies but global has custom
    # Then: Pool inherits global managementPolicies
    metav1alpha1.CompositionTest{
        metadata.name = "management-policies-inheritance"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-mgmt"
                spec = {
                    region = "us-east-1"
                    managementPolicies = ["Observe"]
                    pools.ipv4 = [{name = "inherits", cidr = "10.0.0.0/8"}]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-mgmt"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-mgmt"
                            privateDefaultScopeId = "ipam-scope-private-mgmt"
                            publicDefaultScopeId = "ipam-scope-public-mgmt"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata.name = "test-mgmt"
                    spec.managementPolicies = ["Observe"]
                }
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-mgmt-inherits"
                    spec.managementPolicies = ["Observe"]
                }
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPoolCidr"
                    metadata.name = "test-mgmt-inherits-cidr"
                    spec.managementPolicies = ["Observe"]
                }
            ]
        }
    }

    # =========================================================================
    # Test: Pool overrides global management policies
    # =========================================================================
    # When: Pool has explicit managementPolicies
    # Then: Pool uses its own policies, not global
    metav1alpha1.CompositionTest{
        metadata.name = "management-policies-override"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-override"
                spec = {
                    region = "us-east-1"
                    managementPolicies = ["*"]
                    pools.ipv4 = [
                        {name = "observe-only", cidr = "10.0.0.0/8", managementPolicies = ["Observe"]}
                        {name = "full-manage", cidr = "172.16.0.0/12"}
                    ]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-override"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-override"
                            privateDefaultScopeId = "ipam-scope-private-override"
                            publicDefaultScopeId = "ipam-scope-public-override"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-override-observe-only"
                    spec.managementPolicies = ["Observe"]
                }
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-override-full-manage"
                    spec.managementPolicies = ["*"]
                }
            ]
        }
    }

    # =========================================================================
    # Test: Pool labels propagate to resources
    # =========================================================================
    # When: Pool has custom labels
    # Then: VPCIpamPool has merged labels including hops.ops.com.ai/ipam-pool
    metav1alpha1.CompositionTest{
        metadata.name = "pool-labels-propagate"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-labels"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [{
                        name = "labeled"
                        cidr = "10.0.0.0/8"
                        labels = {
                            "pool-type" = "global"
                            "environment" = "prod"
                        }
                    }]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-labels"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-labels"
                            privateDefaultScopeId = "ipam-scope-private-labels"
                            publicDefaultScopeId = "ipam-scope-public-labels"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata = {
                        name = "test-labels-labeled"
                        labels = {
                            "hops.ops.com.ai/ipam-pool" = "labeled"
                            "pool-type" = "global"
                            "environment" = "prod"
                        }
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: IPv4 pool without IPAM observed doesn't render
    # =========================================================================
    # When: IPAM not observed yet
    # Then: Pool doesn't render (needs privateDefaultScopeId)
    metav1alpha1.CompositionTest{
        metadata.name = "pool-waits-for-ipam"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-wait"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [{name = "waiting", cidr = "10.0.0.0/8"}]
                }
            }
            # No observed resources - IPAM not ready
            observedResources = []
            # Only IPAM should render - pool is gated on IPAM scope
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata.name = "test-wait"
                }
            ]
        }
    }

    # =========================================================================
    # Test: forProvider pass-through for VPCIpam
    # =========================================================================
    # When: spec.forProvider has custom fields
    # Then: Those fields are merged into VPCIpam forProvider
    metav1alpha1.CompositionTest{
        metadata.name = "ipam-forprovider-passthrough"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-fp"
                spec = {
                    region = "us-east-1"
                    forProvider = {
                        tier = "advanced"
                        enablePrivateGua = True
                    }
                    pools.ipv4 = [{name = "pool", cidr = "10.0.0.0/8"}]
                }
            }
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata.name = "test-fp"
                    spec.forProvider = {
                        tier = "advanced"
                        enablePrivateGua = True
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Pool forProvider pass-through
    # =========================================================================
    # When: Pool has forProvider custom fields
    # Then: Those fields are merged into VPCIpamPool forProvider
    metav1alpha1.CompositionTest{
        metadata.name = "pool-forprovider-passthrough"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-pool-fp"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [{
                        name = "custom"
                        cidr = "10.0.0.0/8"
                        forProvider = {
                            autoImport = True
                            allocationResourceTags = {PoolName = "custom"}
                        }
                    }]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-pool-fp"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-pool-fp"
                            privateDefaultScopeId = "ipam-scope-private-fp"
                            publicDefaultScopeId = "ipam-scope-public-fp"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata.name = "test-pool-fp-custom"
                    spec.forProvider = {
                        autoImport = True
                        allocationResourceTags = {PoolName = "custom"}
                    }
                }
            ]
        }
    }

    # =========================================================================
    # Test: Pool with netmaskLength instead of cidr uses auto-assign
    # =========================================================================
    # When: IPv4 pool has netmaskLength (child pool scenario)
    # Then: VPCIpamPoolCidr uses netmaskLength instead of cidr
    metav1alpha1.CompositionTest{
        metadata.name = "pool-netmask-length-auto-assign"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-netmask"
                spec = {
                    region = "us-east-1"
                    pools.ipv4 = [
                        {name = "parent", cidr = "10.0.0.0/8"}
                        {name = "child", sourcePoolRef = "parent", netmaskLength = 16}
                    ]
                }
            }
            observedResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpam"
                    metadata = {
                        name = "test-netmask"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-netmask"
                            privateDefaultScopeId = "ipam-scope-private-netmask"
                            publicDefaultScopeId = "ipam-scope-public-netmask"
                        }
                    }
                }
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPool"
                    metadata = {
                        name = "test-netmask-parent"
                        annotations = {"crossplane.io/composition-resource-name" = "ipam-pool-parent"}
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True"}]
                        atProvider = {
                            id = "ipam-pool-parent-nm"
                            ipamScopeId = "ipam-scope-private-netmask"
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamPoolCidr"
                    metadata.name = "test-netmask-child-cidr"
                    spec.forProvider.netmaskLength = 16
                }
            ]
        }
    }

    # =========================================================================
    # Test: Scope external name for adoption
    # =========================================================================
    # When: Scope has externalName
    # Then: VPCIpamScope has crossplane.io/external-name annotation
    metav1alpha1.CompositionTest{
        metadata.name = "scope-external-name-adoption"
        spec = {
            compositionPath = "apis/ipams/composition.yaml"
            xrdPath = "apis/ipams/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "IPAM"
                metadata.name = "test-scope-adopt"
                spec = {
                    region = "us-east-1"
                    scopes = [{
                        name = "adopted"
                        externalName = "ipam-scope-0123456789abcdef0"
                    }]
                    pools.ipv4 = [{name = "pool", cidr = "10.0.0.0/8"}]
                }
            }
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "VPCIpamScope"
                    metadata = {
                        name = "test-scope-adopt-scope-adopted"
                        annotations = {"crossplane.io/external-name" = "ipam-scope-0123456789abcdef0"}
                    }
                }
            ]
        }
    }

]

items = _items
