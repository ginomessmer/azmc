using Discord.Interactions;
using Microsoft.Extensions.Options;

/// <summary>
/// Represents a background service that handles the bot startup functionality.
/// </summary>
public class BotBackgroundService : BackgroundService
{
    private readonly InteractionService _interactionService;
    private readonly IOptions<BotOptions> _options;
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BotBackgroundService> _logger;

    public BotBackgroundService(
        InteractionService interactionService,
        IOptions<BotOptions> options,
        IServiceProvider serviceProvider,
        ILogger<BotBackgroundService> logger)
    {
        _interactionService = interactionService;
        _options = options;
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using (_logger.BeginScope("Login"))
        {
            _logger.LogInformation("Logging in...");
            await _interactionService.RestClient.LoginAsync(Discord.TokenType.Bot, _options.Value.Token);
            _logger.LogInformation("Logged in");
        }

        using (_logger.BeginScope("Module loader"))
        {
            _logger.LogInformation("Loading modules...");
            await _interactionService.AddModulesAsync(typeof(BotBackgroundService).Assembly, _serviceProvider);
            _logger.LogInformation("Loaded modules");
        }

        using (_logger.BeginScope("Command registration"))
        {
            _logger.LogInformation("Registering commands...");
#if DEBUG
            await _interactionService.RegisterCommandsToGuildAsync(575985821744627734);
#else
            await _interactionService.RegisterCommandsGloballyAsync();
#endif
            _logger.LogInformation("Registered commands");
        }
    }
}