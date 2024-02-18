using Azmc.DiscordBot.Modules;
using Discord.Interactions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Azmc.DiscordBot;

/// <summary>
/// Represents a background service that handles the bot startup functionality.
/// </summary>
public class BotBackgroundService : BackgroundService
{
    private readonly InteractionService _interactionService;
    private readonly IOptions<BotOptions> _botOptions;
    private readonly IOptions<AzureOptions> _azureOptions;
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BotBackgroundService> _logger;

    public BotBackgroundService(
        InteractionService interactionService,
        IOptions<BotOptions> botOptions,
        IOptions<AzureOptions> azureOptions,
        IServiceProvider serviceProvider,
        ILogger<BotBackgroundService> logger)
    {
        _interactionService = interactionService;
        _botOptions = botOptions;
        _azureOptions = azureOptions;
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _interactionService.Log += (log) =>
        {
            var logLevel = log.Severity switch
            {
                Discord.LogSeverity.Critical => LogLevel.Critical,
                Discord.LogSeverity.Error => LogLevel.Error,
                Discord.LogSeverity.Warning => LogLevel.Warning,
                Discord.LogSeverity.Info => LogLevel.Information,
                Discord.LogSeverity.Verbose => LogLevel.Trace,
                Discord.LogSeverity.Debug => LogLevel.Debug,
                _ => throw new ArgumentOutOfRangeException(nameof(log.Severity))
            };
            _logger.Log(logLevel, log.Exception, "{source} :: {message}", log.Source, log.Message);
            return Task.CompletedTask;
        };

        using (_logger.BeginScope("Login"))
        {
            _logger.LogInformation("Logging in...");
            await _interactionService.RestClient.LoginAsync(Discord.TokenType.Bot, _botOptions.Value.Token);
            _logger.LogInformation("Logged in");
        }

        using (_logger.BeginScope("Module loader"))
        {
            _logger.LogInformation("Loading modules...");
            if (!string.IsNullOrEmpty(_azureOptions.Value.ServerContainerGroupResourceId))
            {
                _logger.LogInformation("Loading server module...");
                await _interactionService.AddModuleAsync<ServerModule>(_serviceProvider);
            }
            if (!string.IsNullOrEmpty(_azureOptions.Value.RendererContainerAppJobResourceId))
            {
                _logger.LogInformation("Loading renderer module...");
                await _interactionService.AddModuleAsync<RendererModule>(_serviceProvider);
            }
            _logger.LogInformation("Loaded modules");
        }

        using (_logger.BeginScope("Command registration"))
        {
            _logger.LogInformation("Registering commands...");
#if DEBUG
            await _interactionService.RegisterCommandsToGuildAsync(_botOptions.Value.DebugGuildId);
#else
            await _interactionService.RegisterCommandsGloballyAsync();
#endif
            _logger.LogInformation("Registered commands");
        }

        _logger.LogInformation("Ready");
    }
}