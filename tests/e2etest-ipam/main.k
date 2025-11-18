import base64
import datetime
import file
import math
import models.ai.com.ops.hops.aws.v1alpha1 as hops
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_now = str(int(math.floor(datetime.ticks())))
_org_name = "hops-e2e-ipam-org-" + _now
_composite_name = "hops-e2e-ipam-" + _now
_provider_config_name = "ipam-provider-" + _now

_creds = file.read("secrets/aws-creds")
_base64_creds = base64.encode(_creds)

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
                        providerConfigName: _provider_config_name
                        managementPolicies: ["*"]
                        managementMode: "self"
                        forProvider: {
                            delegatedAdminAccountRef: {
                                name: _org_name
                            }
                            homeRegion: "us-east-2"
                            operatingRegions: ["us-east-2"]
                            pools: [
                                {
                                    name: "shared"
                                    cidr: "10.16.0.0/16"
                                    allocationDefaultNetmaskLength: 24
                                    labels: {
                                        purpose: "e2e"
                                    }
                                    tags: {
                                        owner: "ipam-e2e"
                                    }
                                }
                            ]
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
                        name: _provider_config_name
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
