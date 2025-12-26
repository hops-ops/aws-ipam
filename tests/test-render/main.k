
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
                            'hops.ops.com.ai/ipam-pool': "platform-shared"
                        }
                    }
                    spec: {
                        managementPolicies: ["*"]
                        forProvider: {
                            addressFamily: "ipv4"
                            ipamScopeId: "ipam-scope-private-0123456789"
                            locale: "us-west-2"
                            allocationDefaultNetmaskLength: 16
                            tags: {
                                hops: "true"
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
    # Test dual-stack IPAM with IPv4, IPv6 ULA, and IPv6 GUA pools
    metav1alpha1.CompositionTest{
        metadata.name: "test-ipam-dual-stack"
        spec = {
            compositionPath: "apis/ipams/composition.yaml"
            xrPath: "examples/ipams/standard.yaml"
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
                        conditions: [{ type: "Ready", status: "True" }]
                        atProvider: {
                            id: "ipam-dualstack"
                            arn: "arn:aws:ec2:us-east-1:123456789012:ipam/ipam-dualstack"
                            privateDefaultScopeId: "ipam-scope-private-dualstack"
                            publicDefaultScopeId: "ipam-scope-public-dualstack"
                        }
                    }
                }
            ]
            assertResources: [
                # IPv4 pool should have addressFamily: ipv4
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "platform-ipv4" }
                    spec: {
                        forProvider: {
                            addressFamily: "ipv4"
                            allocationDefaultNetmaskLength: 12
                        }
                    }
                },
                # IPv6 ULA pool should have addressFamily: ipv6, private scope
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "platform-ipv6-private" }
                    spec: {
                        forProvider: {
                            addressFamily: "ipv6"
                            ipamScopeId: "ipam-scope-private-dualstack"
                            allocationDefaultNetmaskLength: 56
                        }
                    }
                },
                # IPv6 GUA pool should have addressFamily: ipv6, public scope
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "platform-ipv6-public" }
                    spec: {
                        forProvider: {
                            addressFamily: "ipv6"
                            ipamScopeId: "ipam-scope-public-dualstack"
                            allocationDefaultNetmaskLength: 56
                            publicIpSource: "amazon"
                            awsService: "ec2"
                        }
                    }
                }
            ]
        }
    },
    # Test managementPolicies cascade: pool -> global
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
                }
            ]
            assertResources: [
                # Pool A - should have explicit ["Observe"]
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
                # Pool B - should have explicit ["*"]
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "mgmt-policy-test-pool-b" }
                    spec: { managementPolicies: ["*"] }
                },
                # Pool C - should have global default ["*"]
                {
                    apiVersion: "ec2.aws.m.upbound.io/v1beta1"
                    kind: "VPCIpamPool"
                    metadata: { name: "mgmt-policy-test-pool-c" }
                    spec: { managementPolicies: ["*"] }
                }
            ]
        }
    }
]
items = _items
