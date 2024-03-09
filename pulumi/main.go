package main

import (

	// "github.com/muhlba91/pulumi-proxmoxve/sdk/v3/go/proxmoxve/ct"

	"github.com/muhlba91/pulumi-proxmoxve/sdk/v5/go/proxmoxve"
	"github.com/muhlba91/pulumi-proxmoxve/sdk/v5/go/proxmoxve/ct"
	"github.com/pulumi/pulumi-vault/sdk/v5/go/vault"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {

		pve, err := proxmoxve.NewProvider(ctx, "pve", &proxmoxve.ProviderArgs{

			Endpoint: pulumi.String("https://192.168.121.48:8006"),
			Insecure: pulumi.Bool(true),
			Username: pulumi.String("root@pam"),
			Password: pulumi.String("vagrant"),
		})
		if err != nil {
			return err
		}

		container, err := ct.NewContainer(ctx, "vault", &ct.ContainerArgs{
			NodeName: pulumi.String("pve"),
			Initialization: ct.ContainerInitializationArgs{
				Hostname: pulumi.String("vault"),
				UserAccount: ct.ContainerInitializationUserAccountArgs{
					Password: pulumi.String("vault"),
				},
			},
			OperatingSystem: ct.ContainerOperatingSystemArgs{
				Type:           pulumi.String("alpine"),
				TemplateFileId: pulumi.String("local:vztmpl/vault.tar.xz"),
			},
			Disk: ct.ContainerDiskArgs{
				DatastoreId: pulumi.String("local-lvm"),
				Size:        pulumi.IntPtr(8),
			},
			Cpu: ct.ContainerCpuArgs{
				Cores: pulumi.IntPtr(1),
			},
			Memory: ct.ContainerMemoryArgs{
				Dedicated: pulumi.IntPtr(512),
				Swap:      pulumi.IntPtr(512),
			},
			NetworkInterfaces: ct.ContainerNetworkInterfaceArray{
				ct.ContainerNetworkInterfaceArgs{
					Name:     pulumi.String("eth0"),
					Bridge:   pulumi.String("vmbr0"),
					Firewall: pulumi.Bool(true),
				},
			},
		}, pulumi.Provider(pve))
		if err != nil {
			return err
		}

		ctx.Export("container", container.ID())

		return nil
	})
}

func vaultNomad(ctx *pulumi.Context) error {
	nomadBackend, err := vault.NewNomadSecretBackend(ctx, "my-nomad-backend", &vault.NomadSecretBackendArgs{
		// Arguments for the Nomad secret backend
		Address:                pulumi.String("http://nomad-server.service.consul:4646"),
		Token:                  pulumi.StringPtr("your-nomad-token-here"),
		Local:                  pulumi.Bool(true),
		Namespace:              pulumi.StringPtr("namespace-if-required"),
		MaxTtl:                 pulumi.Int(86400), // 1 day
		DefaultLeaseTtlSeconds: pulumi.Int(3600),  // 1 hour
	})
	if err != nil {
		return err
	}

	// Define a secret role for Nomad integration
	_, err = vault.NewNomadSecretRole(ctx, "my-nomad-role", &vault.NomadSecretRoleArgs{
		Backend:   nomadBackend.ID(), // Reference to the Nomad secret backend
		Role:      pulumi.String("example-role"),
		Type:      pulumi.String("client"),
		Policies:  pulumi.StringArray{pulumi.String("default")},
		Global:    pulumi.Bool(true),
		Namespace: pulumi.StringPtr("namespace-if-required"),
	})
	if err != nil {
		return err
	}

	// Export the backend address for easy access
	ctx.Export("nomadBackendAddress", nomadBackend.Address)
	return nil
}
