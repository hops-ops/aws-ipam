
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
            assertResources: [
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpam"
                    metadata: {
                        name: "platform-ipam"
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
                    name: "ipam"
                    resource: {
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
                            }
                        }
                    }
                },
                {
                    name: "ipam-private-scope"
                    resource: {
                        status: {
                            conditions: [
                                {
                                    type: "Ready"
                                    status: "True"
                                }
                            ]
                            atProvider: {
                                id: "ipam-scope-1234567890"
                                arn: "arn:aws:ec2:us-east-1:123456789012:ipam-scope/ipam-scope-1234567890"
                            }
                        }
                    }
                },
                {
                    name: "ipam-pool-workloads-east"
                    resource: {
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
                    }
                },
                {
                    name: "ipam-pool-cidr-workloads-east"
                    resource: {
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
                    }
                },
                {
                    name: "ipam-pool-workloads-west"
                    resource: {
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
                    }
                },
                {
                    name: "ipam-pool-cidr-workloads-west"
                    resource: {
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
                    }
                },
                {
                    name: "ram-share-workloads-east"
                    resource: {
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
                    }
                },
                {
                    name: "ram-share-workloads-west"
                    resource: {
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
                    }
                },
                {
                    name: "ram-principal-workloads-east-0"
                    resource: {
                        status: {
                            conditions: [
                                {
                                    type: "Ready"
                                    status: "True"
                                }
                            ]
                        }
                    }
                },
                {
                    name: "ram-principal-workloads-west-0"
                    resource: {
                        status: {
                            conditions: [
                                {
                                    type: "Ready"
                                    status: "True"
                                }
                            ]
                        }
                    }
                }
            ]
            assertResources: [
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "workloads-ipam-scope-usage"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamScope"
                            resourceRef: {
                                name: "workloads-ipam-private"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpam"
                            resourceRef: {
                                name: "workloads-ipam"
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "workloads-workloads-east-pool-usage"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "workloads-workloads-east"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamScope"
                            resourceRef: {
                                name: "workloads-ipam-private"
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "workloads-workloads-west-pool-usage"
                    }
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamPool"
                            resourceRef: {
                                name: "workloads-workloads-west"
                            }
                        }
                        of: {
                            apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                            kind: "VPCIpamScope"
                            resourceRef: {
                                name: "workloads-ipam-private"
                            }
                        }
                    }
                },
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "workloads-workloads-east-pool-cidr-usage"
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
                        name: "workloads-workloads-west-pool-cidr-usage"
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
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "workloads-workloads-east-share-usage"
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
                        name: "workloads-workloads-west-share-usage"
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
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata: {
                        name: "workloads-workloads-east-principal-0-usage"
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
                        name: "workloads-workloads-west-principal-0-usage"
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
    }
]
items = _items
