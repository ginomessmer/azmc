using AzmcBot.Configuration;
using Discord.Interactions;
using Discord.WebSocket;
using Microsoft.Extensions.Options;
using System.Reflection;

namespace AzmcBot.Workers;

public class DiscordBotWorker : IHostedService
{
    private readonly DiscordSocketClient _client;
    private readonly InteractionService _interactionService;
    private readonly ILogger<DiscordBotWorker> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly IConfiguration _config;
    private readonly BotConfiguration _options;

    public DiscordBotWorker(
        DiscordSocketClient client,
        InteractionService interactionService,
        ILogger<DiscordBotWorker> logger,
        IServiceProvider serviceProvider,
        IConfiguration config,
        IOptions<BotConfiguration> options)
    {
        _client = client;
        _interactionService = interactionService;
        _logger = logger;
        _serviceProvider = serviceProvider;
        _config = config;
        _options = options.Value;

        _client.Ready += RegisterCommands;
        _client.InteractionCreated += _client_InteractionCreated;
        _client.Log += message => Task.FromResult(() => _logger.LogDebug(message.Message));
        _interactionService.Log += message => Task.FromResult(() => _logger.LogDebug(message.Message));
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Logging into Discord...");
        await _client.LoginAsync(Discord.TokenType.Bot, _options.DiscordToken);

        _logger.LogInformation("Starting bot...");
        await _client.StartAsync();

        _logger.LogInformation("Bot is online");
    }

    public async Task StopAsync(CancellationToken cancellationToken)
    {
        _interactionService.Dispose();

        await _client.StopAsync();
        await _client.LogoutAsync();
        await _client.DisposeAsync();
    }

    private async Task RegisterCommands()
    {
        try
        {
            _logger.LogInformation("Registering interactions...");
            await _interactionService.AddModulesAsync(Assembly.GetExecutingAssembly(), _serviceProvider);
            await _interactionService.RegisterCommandsGloballyAsync();

            _logger.LogInformation("Commands successfully registered");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to register commands");
            throw;
        }
    }

    private async Task _client_InteractionCreated(SocketInteraction arg)
    {
        try
        {
            var context = new SocketInteractionContext(_client, arg);
            var result = await _interactionService.ExecuteCommandAsync(context, _serviceProvider);

            if (!result.IsSuccess)
            {
                _logger.LogError($"Failed to execute command ({result.ErrorReason})");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to execute command");
        }
    }
}