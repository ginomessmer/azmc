# Code Review: AZMC (Azure Minecraft)

## Overview

AZMC is an Infrastructure-as-Code project for deploying Minecraft servers on Azure with a Discord bot for management and an optional web-based map renderer. The stack includes C#/.NET 8 (Discord bot), Azure Bicep (IaC), Docker, and GitHub Actions CI/CD.

The project is well-structured with clear separation of concerns between infrastructure, application code, and CI/CD. Below are findings organized by severity.

---

## Critical Issues

### 1. `StreamReader` not disposed in interaction endpoint
**File:** `src/discord-bot/Azmc.DiscordBot/Program.cs:67`

```csharp
var reader = new StreamReader(req.Body);
var body = await reader.ReadToEndAsync();
```

The `StreamReader` is never disposed. While disposing it would also close the underlying `req.Body` stream (which may be undesirable), the current approach leaks the reader. Consider using `leaveOpen: true`:

```csharp
using var reader = new StreamReader(req.Body, leaveOpen: true);
```

### 2. Busy-wait loop for command response
**File:** `src/discord-bot/Azmc.DiscordBot/Program.cs:97-100`

```csharp
while (!cts.IsCancellationRequested)
{
    await Task.Delay(100);
}
```

This is a polling loop that wastes CPU cycles and adds up to 100ms of latency per interaction. Replace with a `TaskCompletionSource<IResult>`:

```csharp
var tcs = new TaskCompletionSource<IResult>();
var cts = new CancellationTokenSource(TimeSpan.FromSeconds(3));
cts.Token.Register(() => tcs.TrySetResult(Results.BadRequest("Could not complete command")));

await interactionService.ExecuteCommandAsync(new RestInteractionContext(client, interaction, json =>
{
    tcs.TrySetResult(Results.Content(json, ...));
    return Task.CompletedTask;
}), services);

return await tcs.Task;
```

### 3. `ContainerGroupResource` resolved eagerly at startup via `.Get()`
**File:** `src/discord-bot/Azmc.DiscordBot/Program.cs:33-39`

```csharp
.AddSingleton<ContainerGroupResource>(services =>
{
    var client = services.GetRequiredService<ArmClient>();
    var options = services.GetRequiredService<IOptions<AzureOptions>>();
    var resource = client.GetContainerGroupResource(ResourceIdentifier.Parse(options.Value.ContainerGroupResourceId)).Get();
    return resource;
});
```

This makes an Azure ARM API call during DI container construction. If the container group doesn't exist yet or Azure is temporarily unreachable, the entire application fails to start. The `.Get()` call also captures a snapshot of the resource at startup time, meaning the `/status` command will always return the state as it was when the bot started — not the current state.

Consider using `GetContainerGroupResource()` (without `.Get()`) to get a resource handle, and calling `.Get()` on-demand in the command handlers where fresh data is needed.

### 4. `/status` returns stale data
**File:** `src/discord-bot/Azmc.DiscordBot/Modules/ServerModule.cs:22`

```csharp
var state = _containerGroupResource.Data.Containers.First().InstanceView.CurrentState;
```

Because the `ContainerGroupResource` is a singleton resolved once at startup (see issue #3), `.Data` reflects the state at injection time. After a `/start` or `/stop`, `/status` will still report the old state until the bot is restarted. This should call `.Get()` or `.GetAsync()` to fetch current data.

### 5. Docker Hub credentials always required in server.bicep
**File:** `infra/modules/server.bicep:134-139`

```bicep
imageRegistryCredentials: [
  {
    server: 'docker.io'
    username: dockerHubUsername
    password: dockerHubPassword
  }
]
```

The `itzg/minecraft-server` image is public on Docker Hub. If `dockerHubUsername` is empty, this will produce invalid credentials that could cause image pull failures. This should be conditional:

```bicep
imageRegistryCredentials: empty(dockerHubUsername) ? [] : [...]
```

---

## Medium Issues

### 6. Empty port/env objects when Bedrock is disabled
**File:** `infra/modules/server.bicep:60-64, 91-94`

```bicep
isBedrockSupportEnabled ? {
  port: 19132
  protocol: 'UDP'
} : { }
```

When Bedrock is disabled, this emits an empty object `{}` in the ports array, which may cause ARM deployment validation errors. Use Bicep's `concat()` or `union()` pattern to conditionally include array items rather than emitting empties.

### 7. `RESOURCE_PACK` env var always set
**File:** `infra/modules/server.bicep:88-90`

```bicep
{
  name: 'RESOURCE_PACK'
  value: resourcePackUrl != '' ? resourcePackUrl : ''
}
```

The ternary is redundant — it always evaluates to `resourcePackUrl`. More importantly, the `itzg/minecraft-server` image may behave differently when `RESOURCE_PACK` is set to an empty string versus not being set at all. This should be conditionally included.

### 8. `BotBackgroundService` doesn't respect `CancellationToken`
**File:** `src/discord-bot/Azmc.DiscordBot/BotBackgroundService.cs:29`

```csharp
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
```

The `stoppingToken` parameter is never passed to any of the async operations (`LoginAsync`, `AddModulesAsync`, `RegisterCommandsGloballyAsync`). If the application is shutting down during startup, these operations will not be cancelled.

### 9. Inconsistent `azure/login` action versions across workflows
- `deploy.yml`: `azure/login@a65d910e8af852a8061c627c456678983e180302` (pinned to commit hash)
- `server.yml`, `destroy.yml`: `azure/login@v1`

Mixing pinned hashes and tag-based versions is inconsistent. The `@v1` references are also potentially stale. Pin all to the same commit hash or at minimum use the same version tag consistently.

### 10. Deprecated `set-output` syntax in `destroy.yml`
**File:** `.github/workflows/destroy.yml:41`

```yaml
echo "::set-output name=container_name::$container_name"
```

This syntax has been deprecated since October 2022. The `server.yml` workflow also has a broken output format using `container_name::$container_name` (double-colon instead of `=`). Both should use the modern `$GITHUB_OUTPUT` approach.

### 11. Broken GitHub Actions output syntax in `server.yml`
**File:** `.github/workflows/server.yml:40,61`

```yaml
echo "container_name::$container_name" >> $GITHUB_OUTPUT
```

The `$GITHUB_OUTPUT` file expects `key=value` format, but this uses `key::value`. This would cause the `container_name` output to be empty, breaking the subsequent step. Should be:

```yaml
echo "container_name=$container_name" >> $GITHUB_OUTPUT
```

### 12. `InvariantGlobalization` set twice with conflicting values
**File:** `src/discord-bot/Azmc.DiscordBot/Azmc.DiscordBot.csproj:7-9`

```xml
<InvariantGlobalization>true</InvariantGlobalization>
<!-- <PublishAot>true</PublishAot> -->
<InvariantGlobalization>false</InvariantGlobalization>
```

The property is declared twice — first `true`, then `false`. The last value wins (`false`), but the first line is dead code that creates confusion. Remove line 7.

### 13. No authorization on Discord slash commands
**File:** `src/discord-bot/Azmc.DiscordBot/Modules/ServerModule.cs`

The `/start` and `/stop` commands are available to anyone in the Discord server. There are no permission checks — any user can start or stop the Minecraft server. Consider adding Discord permission requirements:

```csharp
[RequireUserPermission(GuildPermission.ManageGuild)]
```

### 14. `allowBlobPublicAccess: true` on storage accounts
**Files:** `infra/modules/storage-map.bicep:23`, `infra/modules/storage-resources.bicep:19`

Public blob access is enabled on the map and resources storage accounts. While this is intentional for serving the web map and resource packs, it's worth explicitly documenting this decision and ensuring no sensitive data can be uploaded to these containers.

---

## Low Issues / Suggestions

### 15. Dockerfile healthcheck uses `curl` but doesn't install it
**File:** `src/discord-bot/Azmc.DiscordBot/Dockerfile:30`

```dockerfile
HEALTHCHECK CMD curl --fail http://localhost:8080/health || exit
```

The final stage is based on `mcr.microsoft.com/dotnet/aspnet:8.0`, which does not include `curl` by default. This healthcheck will always fail. Either install curl in the final stage or use a .NET-based health check approach.

### 16. Auto-shutdown schedule mismatch with documentation
**File:** `infra/modules/auto-shutdown.bicep:8-17`

The main.bicep `@description` says "Automatically shut down the server at midnight," but the default schedule is 3:00 AM:

```bicep
schedule: {
  hours: [ '3' ]
  minutes: [ 0 ]
}
```

### 17. `webMapFqdn` output type inconsistency
**File:** `infra/main.bicep:209-211`

```bicep
output discordInteractionEndpoint string? = ...  // nullable
output webMapFqdn string = ...                   // non-nullable, returns empty string
```

The `discordInteractionEndpoint` correctly uses a nullable type, but `webMapFqdn` returns an empty string when the renderer isn't deployed. Use the same `string?` pattern for consistency.

### 18. Missing `FORGE`-specific handling for Geyser plugin
**File:** `infra/modules/server.bicep:92-94`

When Bedrock support is enabled, the Geyser Spigot plugin is always downloaded:

```bicep
value: 'https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot'
```

This is the Spigot variant. If `serverType` is `FORGE`, this plugin won't work — the Forge variant should be used instead.

### 19. No `.dockerignore` file
**File:** `src/discord-bot/`

There is no `.dockerignore` file, which means the entire `src/discord-bot/` context (including `.git`, `bin/`, `obj/`, etc.) is sent to the Docker daemon during builds.

### 20. `deploy.yml` redirect issue with `> whatif`
**File:** `.github/workflows/deploy.yml:39`

The `AZ_INLINE_SCRIPT_PARAMS` env var ends with `> whatif`, which redirects stdout to a file. This means the `az deployment group create` command in the deploy job also has its output redirected, which could silently swallow deployment output or errors.

### 21. No test infrastructure
The project has no unit tests or integration tests for the Discord bot application. The CI pipeline only validates that the code compiles and the Docker image builds, but there's no test step.

### 22. Missing `contents: read` permission in release workflow
**File:** `.github/workflows/release.yml`

The workflow lacks explicit `permissions` configuration. While it uses `secrets.GITHUB_TOKEN`, it relies on default permissions which may be restricted in some repository configurations. Adding explicit `packages: write` and `contents: read` would be more robust.

---

## Architecture Observations

**Strengths:**
- Clean modular Bicep structure with good separation of concerns
- Proper use of Azure Managed Identities and custom RBAC roles (least privilege)
- Resource locks on critical storage accounts to prevent accidental deletion
- Conditional deployments via parameters for all optional modules
- Good use of `@secure()` decorators for sensitive parameters
- Architecture Decision Records (ADRs) in `docs/adr/`

**Areas for improvement:**
- The Discord bot uses REST interactions (webhook-based), which is a reasonable choice for Azure Container Apps. However, the interaction response mechanism in `Program.cs` (the busy-wait callback pattern) is fragile and should be refactored.
- Consider adding Application Insights to the Discord bot for request tracing (the `ai` abbreviation exists in `const.json` but isn't used).
- The `UserSecretsId` in the `.csproj` file is committed to source control — while not a security issue itself, it could be moved to `Directory.Build.props` or excluded.
