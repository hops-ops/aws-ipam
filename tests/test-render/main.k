
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
                    apiVersion: "vpc.aws.m.upbound.io/v1beta1"
                    kind: "IPAM"
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
                    apiVersion: "vpc.aws.m.upbound.io/v1beta1"
                    kind: "IPAMPool"
                    metadata: {
                        name: "platform-platform-shared"
                        labels: {
                            'aws.hops.ops.com.ai/ipam-pool': "platform-shared"
                        }
                    }
                    spec: {
                        managementPolicies: ["*"]
                        forProvider: {
                            cidr: "10.0.0.0/8"
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
                    apiVersion: "vpc.aws.m.upbound.io/v1beta1"
                    kind: "IPAM"
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
                    apiVersion: "vpc.aws.m.upbound.io/v1beta1"
                    kind: "IPAMPool"
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
                    apiVersion: "vpc.aws.m.upbound.io/v1beta1"
                    kind: "IPAMPool"
                    metadata: {
                        name: "workloads-workloads-west"
                    }
                    spec: {
                        forProvider: {
                            cidr: "10.8.0.0/14"
                            allocationDefaultNetmaskLength: 20
                            locale: "us-west-2"
                        }
                    }
                }
            ]
        }
    }
]
items = _items
