
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-ipam-minimal"
        spec = {
            compositionPath: "apis/ipams/composition.yaml"
            xrPath: "examples/ipams/example-minimal.yaml"
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
            xrPath: "examples/ipams/example-multi-region.yaml"
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
            xrPath: "examples/ipams/example-multi-region.yaml"
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
            xrPath: "examples/ipams/example-with-subnet-pool.yaml"
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
                # Child pool should have sourceIpamPoolId (direct ID from observed parent)
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: {
                        name: "platform-subnet-pool"
                    }
                    spec: {
                        forProvider: {
                            sourceIpamPoolId: "ipam-pool-vpc"
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
    }
]
items = _items
