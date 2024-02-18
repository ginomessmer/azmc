# Architecture Decision Record: Switching Server Azure File Share Storage Tier

## Context

We are currently hosting a Minecraft server on Azure and utilizing an Azure file share for storing game data. The server has high transactional requirements but relatively low storage usage. We are considering switching the storage tier from hot to transaction optimized to optimize costs.

## Decision

After careful consideration, we have decided to switch the storage tier of the server Azure file share from hot to transaction optimized.

## Consequences

The decision to switch to the transaction optimized tier has the following consequences:

- Cost Optimization: The transaction optimized tier is more cost-effective for workloads with high transactional requirements and low storage usage. By switching to this tier, we can reduce our storage costs while still meeting the performance needs of the Minecraft server.
- Performance: The transaction optimized tier provides lower latency and higher throughput for transactional workloads. This will help ensure smooth gameplay and responsiveness for players on the Minecraft server.
- Storage Capacity: The transaction optimized tier offers a lower storage capacity compared to the hot tier. However, since our Minecraft server has relatively low storage usage, this reduction in capacity is not a concern for us.

## Alternatives Considered

We considered the following alternatives before making the decision:

1. Hot Tier: We could have continued using the hot tier for the Azure file share. However, this would have resulted in higher storage costs due to the server's high transactional requirements.
2. Cool Tier: Another alternative was to switch to the cool tier, which offers lower storage costs but with higher access latency. However, given the need for low latency in a real-time game like Minecraft, this option was not suitable for our requirements.

## Related ADRs

n/a

## References

- [Understand Azure Files Billing (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/storage/files/understanding-billing)