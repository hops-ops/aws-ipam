
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-ipam-minimal"
        spec = {
            compositionPath: "apis/ipams/composition.yaml"
            xrPath: "examples/ipams/minimal.yaml"
            xrdPath: "apis/ipams/definition.yaml"
            timeoutSeconds: 120
            validate: True
            observedResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "platform"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam"
                            "crossplane.io/composition-resource-name": "ipam"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-0123456789abcdef0"
                            arn: "arn:aws:ec2:us-west-2:123456789012:ipam/ipam-0123456789abcdef0"
                            privateDefaultScopeId: "ipam-scope-private-0123456789"
                            publicDefaultScopeId: "ipam-scope-public-0123456789"
                        }
                    }
                }
            ]
            assertResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "platform"
                        labels: {
                            'hops.ops.com.ai/organization': "platform"
                        }
                    }
                    spec: {
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            operatingRegions: [
                                {
                                    regionName: "us-west-2"
                                }
                            ]
                            tags: {
                                hops: "true"
                                organization: "platform"
                            }
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "platform-platform-shared"
                        labels: {
                            'aws.hops.ops.com.ai/ipam-pool': "platform-shared"
                        }
                    }
                    spec: {
                        managementPolicies: ["*"]
                        forProvider: {
                            ipamScopeId: "ipam-scope-private-0123456789"
                            locale: "us-west-2"
                            allocationDefaultNetmaskLength: 16
                            tags: {
                                owner: "platform"
                                environment: "dev"
                                hops: "true"
                                organization: "platform"
                            }
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "platform-platform-shared-cidr"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        forProvider: {
                            cidr: "10.0.0.0/8"
                        }
                    }
                }
            ]
        }
    },
    metav1alpha1.CompositionTest{
        metadata.name: "test-ipam-usages"
        spec = {
            compositionPath: "apis/ipams/composition.yaml"
            xrPath: "examples/ipams/multi-region.yaml"
            xrdPath: "apis/ipams/definition.yaml"
            timeoutSeconds: 120
            validate: True
            observedResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "workloads-ipam"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam"
                            "crossplane.io/composition-resource-name": "ipam"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-1234567890"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam/ipam-1234567890"
                            privateDefaultScopeId: "ipam-scope-private-1234567890"
                            publicDefaultScopeId: "ipam-scope-public-1234567890"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "workloads-workloads-east"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-workloads-east"
                            "crossplane.io/composition-resource-name": "ipam-pool-workloads-east"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-pool-east"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-east"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "workloads-workloads-east-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-workloads-east"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-workloads-east"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-pool-cidr-east"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "workloads-workloads-west"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-workloads-west"
                            "crossplane.io/composition-resource-name": "ipam-pool-workloads-west"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-pool-west"
                            arn: "arn:aws:ec2:us-west-2:123456789012:ipam-pool/ipam-pool-west"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "workloads-workloads-west-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-workloads-west"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-workloads-west"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-pool-cidr-west"
                        }
                    }
                },
                {
                    apiVersion: "ram.aws.m.upbound.io/v1beta1"
                    kind: "ResourceShare"
                    metadata: {
                        name: "workloads-share-workloads-east"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ram-share-workloads-east"
                            "crossplane.io/composition-resource-name": "ram-share-workloads-east"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            arn: "arn:aws:ram::123456789012:resource-share/rs-east"
                        }
                    }
                },
                {
                    apiVersion: "ram.aws.m.upbound.io/v1beta1"
                    kind: "ResourceShare"
                    metadata: {
                        name: "workloads-share-workloads-west"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ram-share-workloads-west"
                            "crossplane.io/composition-resource-name": "ram-share-workloads-west"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            arn: "arn:aws:ram::123456789012:resource-share/rs-west"
                        }
                    }
                },
                {
                    apiVersion: "ram.aws.m.upbound.io/v1beta1"
                    kind: "PrincipalAssociation"
                    metadata: {
                        name: "workloads-principal-workloads-east-0"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ram-principal-workloads-east-0"
                            "crossplane.io/composition-resource-name": "ram-principal-workloads-east-0"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                    }
                },
                {
                    apiVersion: "ram.aws.m.upbound.io/v1beta1"
                    kind: "PrincipalAssociation"
                    metadata: {
                        name: "workloads-principal-workloads-west-0"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ram-principal-workloads-west-0"
                            "crossplane.io/composition-resource-name": "ram-principal-workloads-west-0"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                    }
                }
            ]
            assertResources: [
                # Pool-to-CIDR usages (still valid - no custom scopes involved)
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-ipam-pool-workloads-workloads-east-by-pool-cidr-workloads-workloads-east-cidr"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPoolCidr"
                            resourceRef: {
                                name: "workloads-workloads-east-cidr"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "workloads-workloads-east"
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-ipam-pool-workloads-workloads-west-by-pool-cidr-workloads-workloads-west-cidr"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPoolCidr"
                            resourceRef: {
                                name: "workloads-workloads-west-cidr"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "workloads-workloads-west"
                            }
                        }
                    }
                },
                # Pool-to-RAM share usages
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-ipam-pool-workloads-workloads-east-by-ram-share-workloads-share-workloads-east"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ram.aws.m.upbound.io/v1beta1"
                            kind: "ResourceShare"
                            resourceRef: {
                                name: "workloads-share-workloads-east"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "workloads-workloads-east"
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-ipam-pool-workloads-workloads-west-by-ram-share-workloads-share-workloads-west"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ram.aws.m.upbound.io/v1beta1"
                            kind: "ResourceShare"
                            resourceRef: {
                                name: "workloads-share-workloads-west"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "workloads-workloads-west"
                            }
                        }
                    }
                },
                # RAM share-to-principal usages
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-ram-share-workloads-share-workloads-east-by-ram-principal-workloads-principal-workloads-east-0"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ram.aws.m.upbound.io/v1beta1"
                            kind: "PrincipalAssociation"
                            resourceRef: {
                                name: "workloads-principal-workloads-east-0"
                            }
                        }
                        of: {
                            apiVersion: "ram.aws.m.upbound.io/v1beta1"
                            kind: "ResourceShare"
                            resourceRef: {
                                name: "workloads-share-workloads-east"
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-ram-share-workloads-share-workloads-west-by-ram-principal-workloads-principal-workloads-west-0"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ram.aws.m.upbound.io/v1beta1"
                            kind: "PrincipalAssociation"
                            resourceRef: {
                                name: "workloads-principal-workloads-west-0"
                            }
                        }
                        of: {
                            apiVersion: "ram.aws.m.upbound.io/v1beta1"
                            kind: "ResourceShare"
                            resourceRef: {
                                name: "workloads-share-workloads-west"
                            }
                        }
                    }
                }
            ]
        }
    },
    metav1alpha1.CompositionTest{
        metadata.name: "test-ipam-multi-region"
        spec = {
            compositionPath: "apis/ipams/composition.yaml"
            xrPath: "examples/ipams/multi-region.yaml"
            xrdPath: "apis/ipams/definition.yaml"
            timeoutSeconds: 120
            validate: True
            observedResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "workloads-ipam"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam"
                            "crossplane.io/composition-resource-name": "ipam"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-1234567890"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam/ipam-1234567890"
                            privateDefaultScopeId: "ipam-scope-private-1234567890"
                            publicDefaultScopeId: "ipam-scope-public-1234567890"
                        }
                    }
                }
            ]
            assertResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "workloads-ipam"
                    }
                    spec: {
                        forProvider: {
                            operatingRegions: [
                                { regionName: "us-east-1" },
                                { regionName: "us-west-2" }
                            ]
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "workloads-workloads-east"
                    }
                    spec: {
                        forProvider: {
                            ipamScopeId: "ipam-scope-private-1234567890"
                            allocationDefaultNetmaskLength: 20
                            allocationMinNetmaskLength: 20
                            allocationMaxNetmaskLength: 26
                            locale: "us-east-1"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "workloads-workloads-east-cidr"
                    }
                    spec: {
                        forProvider: {
                            cidr: "10.4.0.0/14"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "workloads-workloads-west"
                    }
                    spec: {
                        forProvider: {
                            ipamScopeId: "ipam-scope-private-1234567890"
                            allocationDefaultNetmaskLength: 20
                            locale: "us-west-2"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "workloads-workloads-west-cidr"
                    }
                    spec: {
                        forProvider: {
                            cidr: "10.8.0.0/14"
                        }
                    }
                }
            ]
        }
    },
    metav1alpha1.CompositionTest{
        metadata.name: "test-ipam-child-pool-usage"
        spec = {
            compositionPath: "apis/ipams/composition.yaml"
            xrPath: "examples/ipams/with-subnet-pool.yaml"
            xrdPath: "apis/ipams/definition.yaml"
            timeoutSeconds: 120
            validate: True
            observedResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "platform"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam"
                            "crossplane.io/composition-resource-name": "ipam"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-childtest"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam/ipam-childtest"
                            privateDefaultScopeId: "ipam-scope-private-childtest"
                            publicDefaultScopeId: "ipam-scope-public-childtest"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "platform-vpc-pool"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-vpc-pool"
                            "crossplane.io/composition-resource-name": "ipam-pool-vpc-pool"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-pool-vpc"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-vpc"
                            ipamScopeId: "ipam-scope-private-childtest"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "platform-vpc-pool-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-vpc-pool"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-vpc-pool"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-pool-cidr-vpc"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "platform-subnet-pool"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-subnet-pool"
                            "crossplane.io/composition-resource-name": "ipam-pool-subnet-pool"
                        }
                    }
                    status: {
                        conditions: [
                            {
                                type: "Ready"
                                status: "True"
                            }
                        ]
                        atProvider: {
                            id: "ipam-pool-subnet"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-subnet"
                        }
                    }
                }
            ]
            assertResources: [
                # Child pool should have sourceIpamPoolId AND ipamScopeId from parent
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "platform-subnet-pool"
                    }
                    spec: {
                        forProvider: {
                            sourceIpamPoolId: "ipam-pool-vpc"
                            ipamScopeId: "ipam-scope-private-childtest"
                            allocationDefaultNetmaskLength: 24
                            allocationMinNetmaskLength: 20
                            allocationMaxNetmaskLength: 28
                        }
                    }
                },
                # Pool-to-CIDR usage for parent pool
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-ipam-pool-platform-vpc-pool-by-pool-cidr-platform-vpc-pool-cidr"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPoolCidr"
                            resourceRef: {
                                name: "platform-vpc-pool-cidr"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "platform-vpc-pool"
                            }
                        }
                    }
                },
                # Child-to-parent pool usage - ensures child is deleted before parent
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "of-ipam-pool-platform-vpc-pool-by-child-pool-platform-subnet-pool"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "platform-subnet-pool"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "platform-vpc-pool"
                            }
                        }
                    }
                }
            ]
        }
    },
    # Test IPv6 subnet pool inherits addressFamily from parent
    metav1alpha1.CompositionTest{
        metadata.name: "test-ipam-subnet-pool-address-family-inheritance"
        spec = {
            compositionPath: "apis/ipams/composition.yaml"
            xrPath: "examples/ipams/with-subnet-pools.yaml"
            xrdPath: "apis/ipams/definition.yaml"
            timeoutSeconds: 120
            validate: True
            observedResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "dual-stack"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam"
                            "crossplane.io/composition-resource-name": "ipam"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-dualstack"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam/ipam-dualstack"
                            privateDefaultScopeId: "ipam-scope-private-dualstack"
                            publicDefaultScopeId: "ipam-scope-public-dualstack"
                        }
                    }
                },
                # IPv4 parent pool
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "dual-stack-ipv4-vpc"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-ipv4-vpc"
                            "crossplane.io/composition-resource-name": "ipam-pool-ipv4-vpc"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-pool-ipv4"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-ipv4"
                            ipamScopeId: "ipam-scope-private-dualstack"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "dual-stack-ipv4-vpc-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-ipv4-vpc"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-ipv4-vpc"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: { id: "ipam-pool-cidr-ipv4" }
                    }
                },
                # IPv6 ULA parent pool
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "dual-stack-ipv6-ula"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-ipv6-ula"
                            "crossplane.io/composition-resource-name": "ipam-pool-ipv6-ula"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-pool-ipv6-ula"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-ipv6-ula"
                            ipamScopeId: "ipam-scope-private-dualstack"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "dual-stack-ipv6-ula-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-ipv6-ula"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-ipv6-ula"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: { id: "ipam-pool-cidr-ipv6-ula" }
                    }
                },
                # IPv6 GUA parent pool (Amazon-provided)
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "dual-stack-ipv6-gua"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-ipv6-gua"
                            "crossplane.io/composition-resource-name": "ipam-pool-ipv6-gua"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-pool-ipv6-gua"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-ipv6-gua"
                            ipamScopeId: "ipam-scope-public-dualstack"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "dual-stack-ipv6-gua-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-ipv6-gua"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-ipv6-gua"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: { id: "ipam-pool-cidr-ipv6-gua" }
                    }
                }
            ]
            assertResources: [
                # IPv4 parent pool should have addressFamily: ipv4
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "dual-stack-ipv4-vpc" }
                    spec: {
                        forProvider: {
                            addressFamily: "ipv4"
                            allocationDefaultNetmaskLength: 16
                        }
                    }
                },
                # IPv4 subnet pool should inherit addressFamily: ipv4
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "dual-stack-ipv4-vpc-subnets" }
                    spec: {
                        forProvider: {
                            addressFamily: "ipv4"
                            sourceIpamPoolId: "ipam-pool-ipv4"
                            ipamScopeId: "ipam-scope-private-dualstack"
                            allocationDefaultNetmaskLength: 24
                            allocationMinNetmaskLength: 20
                            allocationMaxNetmaskLength: 28
                            description: "IPv4 subnet pool"
                        }
                    }
                },
                # IPv6 ULA parent pool should have addressFamily: ipv6
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "dual-stack-ipv6-ula" }
                    spec: {
                        forProvider: {
                            addressFamily: "ipv6"
                            allocationDefaultNetmaskLength: 60
                        }
                    }
                },
                # IPv6 ULA subnet pool should inherit addressFamily: ipv6 (NOT ipv4!)
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "dual-stack-ipv6-ula-subnets" }
                    spec: {
                        forProvider: {
                            addressFamily: "ipv6"
                            sourceIpamPoolId: "ipam-pool-ipv6-ula"
                            ipamScopeId: "ipam-scope-private-dualstack"
                            allocationDefaultNetmaskLength: 64
                            allocationMinNetmaskLength: 60
                            allocationMaxNetmaskLength: 64
                            description: "IPv6 ULA subnet pool"
                        }
                    }
                },
                # IPv6 GUA parent pool should have addressFamily: ipv6
                # Note: No subnet pool for GUA - AWS doesn't support child pools from Amazon-provided public IPv6 pools
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "dual-stack-ipv6-gua" }
                    spec: {
                        forProvider: {
                            addressFamily: "ipv6"
                            allocationDefaultNetmaskLength: 56
                            publicIpSource: "amazon"
                            awsService: "ec2"
                        }
                    }
                }
            ]
        }
    },
    # Test managementPolicies cascade: subnetPool -> parent -> global
    metav1alpha1.CompositionTest{
        metadata.name: "test-ipam-management-policies-cascade"
        spec = {
            compositionPath: "apis/ipams/composition.yaml"
            xrPath: "examples/ipams/management-policies.yaml"
            xrdPath: "apis/ipams/definition.yaml"
            timeoutSeconds: 120
            validate: True
            observedResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "mgmt-policy-test"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam"
                            "crossplane.io/composition-resource-name": "ipam"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-mgmt-test"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam/ipam-mgmt-test"
                            privateDefaultScopeId: "ipam-scope-private-mgmt"
                            publicDefaultScopeId: "ipam-scope-public-mgmt"
                        }
                    }
                },
                # Pool A - parent with Observe policy
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "mgmt-policy-test-pool-a"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-pool-a"
                            "crossplane.io/composition-resource-name": "ipam-pool-pool-a"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-pool-a"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-a"
                            ipamScopeId: "ipam-scope-private-mgmt"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "mgmt-policy-test-pool-a-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-pool-a"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-pool-a"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: { id: "ipam-pool-cidr-a" }
                    }
                },
                # Pool B - parent with Observe policy, subnet pool will override
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "mgmt-policy-test-pool-b"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-pool-b"
                            "crossplane.io/composition-resource-name": "ipam-pool-pool-b"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-pool-b"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-b"
                            ipamScopeId: "ipam-scope-private-mgmt"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "mgmt-policy-test-pool-b-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-pool-b"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-pool-b"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: { id: "ipam-pool-cidr-b" }
                    }
                },
                # Pool C - no explicit policies (global default)
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "mgmt-policy-test-pool-c"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-pool-c"
                            "crossplane.io/composition-resource-name": "ipam-pool-pool-c"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-pool-c"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-c"
                            ipamScopeId: "ipam-scope-private-mgmt"
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: {
                        name: "mgmt-policy-test-pool-c-cidr"
                        annotations: {
                            "gotemplating.fn.crossplane.io/composition-resource-name": "ipam-pool-cidr-pool-c"
                            "crossplane.io/composition-resource-name": "ipam-pool-cidr-pool-c"
                        }
                    }
                    status: {
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: { id: "ipam-pool-cidr-c" }
                    }
                }
            ]
            assertResources: [
                # Pool A parent - should have ["Observe"]
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "mgmt-policy-test-pool-a" }
                    spec: { managementPolicies: ["Observe"] }
                },
                # Pool A CIDR - should inherit ["Observe"] from pool
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPoolCidr"
                    metadata: { name: "mgmt-policy-test-pool-a-cidr" }
                    spec: { managementPolicies: ["Observe"] }
                },
                # Pool A subnet pool - should inherit ["Observe"] from parent pool
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "mgmt-policy-test-pool-a-subnets" }
                    spec: { managementPolicies: ["Observe"] }
                },
                # Pool B parent - should have ["Observe"]
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "mgmt-policy-test-pool-b" }
                    spec: { managementPolicies: ["Observe"] }
                },
                # Pool B subnet pool - should override with ["*"]
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "mgmt-policy-test-pool-b-subnets" }
                    spec: { managementPolicies: ["*"] }
                },
                # Pool C parent - should have global default ["*"]
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "mgmt-policy-test-pool-c" }
                    spec: { managementPolicies: ["*"] }
                },
                # Pool C subnet pool - should inherit global default ["*"]
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "mgmt-policy-test-pool-c-subnets" }
                    spec: { managementPolicies: ["*"] }
                }
            ]
        }
    }
]
items = _items
