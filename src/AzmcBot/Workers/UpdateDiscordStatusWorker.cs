using Azure.ResourceManager.ContainerInstance;
using Discord.WebSocket;

namespace AzmcBot.Workers;

public class UpdateDiscordStatusWorker : IHostedService
{
    private readonly DiscordSocketClient _client;
    private readonly ContainerGroupResource _container;
    private readonly Timer _timer;

    public UpdateDiscordStatusWorker(DiscordSocketClient client,
        ContainerGroupResource container)
    {
        _client = client;
        _container = container;
        _timer = new Timer(Update, null, TimeSpan.FromMinutes(1), TimeSpan.FromMinutes(1));
    }

    private async void Update(object? state)
    {
        var c = await _container.GetAsync();
        var status = c.Value.Data.Containers.First().InstanceView.CurrentState.DetailStatus;

        await _client.SetGameAsync(status, type: Discord.ActivityType.CustomStatus);
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        return _timer.DisposeAsync().AsTask();
    }
}
