# Architecture Decision Record: Switch from Spigot to Paper MC

## Context

We are currently using the Spigot Minecraft server for our game server infrastructure. However, we have been experiencing limitations with Spigot, and we believe that switching to Paper MC might address these concerns.

## Decision

After evaluating the features and performance improvements offered by Paper MC, we have decided to switch from Spigot to Paper MC as the default Minecraft server type.

## Consequences

- **Improved performance**: Paper MC is known for its optimizations and performance enhancements, which can result in a smoother gameplay experience for players.
- **Enhanced features**: Paper MC offers additional features and improvements over Spigot, such as improved chunk loading, entity tracking, and tick handling.
- **Compatibility**: Paper MC is designed to be compatible with existing Spigot plugins, ensuring that current plugins will continue to work without major modifications.
- **Community support**: Paper MC has a large and active community, providing ongoing support, bug fixes, and updates.

## Alternatives Considered

We considered the following alternatives before making this decision:
- Optimizing Spigot: We could have invested time and effort into optimizing our Spigot server configuration and plugins. However, this approach might not have provided the same level of performance improvements as switching to Paper MC. Additionally, it would have added development and maintenance overhead.
- Other server software: We explored other Minecraft server software options, such as Bukkit and Forge. However, after evaluating their features and community support, we determined that Paper MC was the best choice for our needs.

## Related ADRs
n/a
