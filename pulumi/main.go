package main

import (
	"github.com/muhlba91/pulumi-proxmoxve/sdk/v6/go/proxmoxve/ct"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {

		vault, err := vaultContainer(ctx)
		if err != nil {
			return err
		}

		ctx.Export("vault", vault.ID())

		nomad, err := nomadContainer(ctx)
		if err != nil {
			return err
		}

		ctx.Export("nomad", nomad.ID())

		return nil
	})
}

func vaultContainer(ctx *pulumi.Context) (*ct.Container, error) {

	node, _ := ctx.GetConfig("proxmox:nodename")
	storage, _ := ctx.GetConfig("proxmox:storage")
	bridge, _ := ctx.GetConfig("proxmox:bridge")

	container, err := ct.NewContainer(ctx, "vault", &ct.ContainerArgs{
		NodeName: pulumi.String(node),
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
			DatastoreId: pulumi.String(storage),
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
				Bridge:   pulumi.String(bridge),
				Firewall: pulumi.Bool(true),
			},
		},
		MountPoints: ct.ContainerMountPointArray{
			ct.ContainerMountPointArgs{
				Volume: pulumi.String(storage),
				Path:   pulumi.String("/var/lib/vault"),
				Size:   pulumi.String("4G"),
			},
		},
		Unprivileged: pulumi.Bool(true),
	})
	if err != nil {
		return nil, err
	}

	return container, nil
}

func nomadContainer(ctx *pulumi.Context) (*ct.Container, error) {

	node, _ := ctx.GetConfig("proxmox:nodename")
	storage, _ := ctx.GetConfig("proxmox:storage")
	privateBridge, _ := ctx.GetConfig("proxmox:bridge")

	container, err := ct.NewContainer(ctx, "nomad", &ct.ContainerArgs{
		NodeName: pulumi.String(node),
		Initialization: ct.ContainerInitializationArgs{
			Hostname: pulumi.String("nomad"),
			UserAccount: ct.ContainerInitializationUserAccountArgs{
				Password: pulumi.String("nomad"),
			},
			Dns: ct.ContainerInitializationDnsArgs{
				Server: pulumi.String("10.0.0.1"),
			},
			IpConfigs: ct.ContainerInitializationIpConfigArray{
				ct.ContainerInitializationIpConfigArgs{
					Ipv4: ct.ContainerInitializationIpConfigIpv4Args{Address: pulumi.String("dhcp")},
					Ipv6: ct.ContainerInitializationIpConfigIpv6Args{Address: pulumi.String("dhcp")},
				},
			},
		},
		OperatingSystem: ct.ContainerOperatingSystemArgs{
			Type:           pulumi.String("ubuntu"),
			TemplateFileId: pulumi.String("local:vztmpl/nomad.tar.xz"),
		},
		Disk: ct.ContainerDiskArgs{
			DatastoreId: pulumi.String(storage),
			Size:        pulumi.IntPtr(20),
		},
		Cpu: ct.ContainerCpuArgs{
			Cores: pulumi.IntPtr(4),
		},
		Memory: ct.ContainerMemoryArgs{
			Dedicated: pulumi.IntPtr(4096),
			Swap:      pulumi.IntPtr(4096),
		},
		NetworkInterfaces: ct.ContainerNetworkInterfaceArray{
			ct.ContainerNetworkInterfaceArgs{
				Name:     pulumi.String("eth0"),
				Bridge:   pulumi.String(privateBridge),
				Firewall: pulumi.Bool(true),
			},
		},

		Unprivileged: pulumi.Bool(false),
		Features: ct.ContainerFeaturesArgs{
			Nesting: pulumi.Bool(true),
		},
	})
	if err != nil {
		return nil, err
	}

	return container, nil
}

func ingressContainer(ctx *pulumi.Context) (*ct.Container, error) {

	node, _ := ctx.GetConfig("proxmox:nodename")
	storage, _ := ctx.GetConfig("proxmox:storage")
	bridge, _ := ctx.GetConfig("proxmox:bridge")
	privateBridge, _ := ctx.GetConfig("proxmox:bridge")

	container, err := ct.NewContainer(ctx, "ingress", &ct.ContainerArgs{
		NodeName: pulumi.String(node),
		Initialization: ct.ContainerInitializationArgs{
			Hostname: pulumi.String("ingress"),
			UserAccount: ct.ContainerInitializationUserAccountArgs{
				Password: pulumi.String("ingress"),
			},
			Dns: ct.ContainerInitializationDnsArgs{
				Server: pulumi.String("10.0.0.1"),
			},
			IpConfigs: ct.ContainerInitializationIpConfigArray{
				ct.ContainerInitializationIpConfigArgs{
					Ipv4: ct.ContainerInitializationIpConfigIpv4Args{Address: pulumi.String("dhcp")},
					Ipv6: ct.ContainerInitializationIpConfigIpv6Args{Address: pulumi.String("dhcp")},
				},
			},
		},
		OperatingSystem: ct.ContainerOperatingSystemArgs{
			Type:           pulumi.String("ubuntu"),
			TemplateFileId: pulumi.String("local:vztmpl/ingress.tar.xz"),
		},
		Disk: ct.ContainerDiskArgs{
			DatastoreId: pulumi.String(storage),
			Size:        pulumi.IntPtr(20),
		},
		Cpu: ct.ContainerCpuArgs{
			Cores: pulumi.IntPtr(4),
		},
		Memory: ct.ContainerMemoryArgs{
			Dedicated: pulumi.IntPtr(4096),
			Swap:      pulumi.IntPtr(4096),
		},
		NetworkInterfaces: ct.ContainerNetworkInterfaceArray{
			ct.ContainerNetworkInterfaceArgs{
				Name:     pulumi.String("eth0"),
				Bridge:   pulumi.String(bridge),
				Firewall: pulumi.Bool(true),
			},
			ct.ContainerNetworkInterfaceArgs{
				Name:     pulumi.String("private0"),
				Bridge:   pulumi.String(privateBridge),
				Firewall: pulumi.Bool(true),
			},
		},

		Unprivileged: pulumi.Bool(false),
		Features: ct.ContainerFeaturesArgs{
			Nesting: pulumi.Bool(true),
		},
	})
	if err != nil {
		return nil, err
	}

	return container, nil
}
