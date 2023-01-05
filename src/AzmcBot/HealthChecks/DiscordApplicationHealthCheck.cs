using Discord.WebSocket;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace AzmcBot.HealthChecks;

class DiscordApplicationHealthCheck : IHealthCheck
{
    private readonly DiscordSocketClient _discordSocketClient;

    public DiscordApplicationHealthCheck(DiscordSocketClient discordSocketClient)
    {
        _discordSocketClient = discordSocketClient;
    }

    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default) =>
        Task.FromResult(_discordSocketClient.LoginState == Discord.LoginState.LoggedIn 
            ? HealthCheckResult.Healthy() 
            : HealthCheckResult.Unhealthy());
}