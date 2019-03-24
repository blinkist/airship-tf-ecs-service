---
sidebarDepth: 2
---

# Networking

## Introduction

<mermaid/>

There are two types of networking for ECS. The ECS Task definitinion defines a network-mode, the two modes available are 'bridge' and 'awsvpc'.

## Network-mode: bridge
Bridge is only used for ECS Service which are run on top of EC2 Instances which joined the ECS Cluster. The service does not have their own Network Interface and will
inherit the Networking of their Docker Host. As different different tasks cannot allocate the same port on the docker host, ECS uses [Dynamic Port Mapping](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PortMapping.html), which allocated ports in the ephemeral port range from 49153 through 65535. The Security Group of the EC2 Instance needs to allow traffic from the Load Balancer to these ports.

<center><div class="mermaid">
graph TD 
    subgraph EC2 Instance
    A[ECS Task A]-.->D
    B[ECS Task A]-.->D
    C[ECS Task B]-.->D
    D{ENI}
    end
    D-.->E[Security Group X]
    D-.->F[Security Group Y]
    classDef green fill:#9f6,stroke:#333,stroke-width:2px;
    class D green
</div>
</center>

## Network-mode: awsvpc
awsvpc network-mode is mandatory on Fargate and optional on EC2. The ECS Task will have its own ENI and will also have its own Security Group. The `container_port` parameter will also be used to expose the port on its network interface. A security group rule would need to allow traffic to this port. Using awsvpc with EC2 ECS is limited as the amount of available network interfaces per EC2 instance is extremely limited. [This](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI) table shows the amount of ENI's available per instance type. Check out the [AWS Container Roadmap](https://github.com/aws/containers-roadmap/issues/7)!

<center>
<div class="mermaid">
graph LR
    subgraph ECS Task
    D{ENI}
    end
    D-.->E[Security Group X]
    D-.->F[Security Group Y]
    classDef green fill:#9f6,stroke:#333,stroke-width:2px;
    class D green
</div>
</center>

::: tip
For both network modes the security groups need to allow outgoing traffic to communicate with AWS, for example to pull ECR Docker images.
:::

::: warning Warning for Network Load Balancer (NLB) Users!
A NLB acts transparantly and does not have a Security Group, this implies that ECS Services which need to allow traffic from a NLB need a wide open security group rule in case it needs to be reachable from the internet. It's advised to use awsvpc network mode for this as the service will have it's own Security Group then.
:::
