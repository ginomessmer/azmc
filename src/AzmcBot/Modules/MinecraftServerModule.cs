using AzmcBot.Configuration;
using Azure.ResourceManager.ContainerInstance;
using Discord;
using Discord.Interactions;
using Microsoft.Extensions.Options;

namespace AzmcBot.Modules
{
    public class MinecraftServerModule : InteractionModuleBase<SocketInteractionContext>
    {
        private readonly ContainerGroupResource _container;
        private readonly BotConfiguration _config;
        private readonly ILogger<MinecraftServerModule> _logger;

        public MinecraftServerModule(
            ContainerGroupResource container,
            IOptions<BotConfiguration> config,
            ILogger<MinecraftServerModule> logger)
	    {
            _container = container;
            _config = config.Value;
            _logger = logger;
	    }

        [SlashCommand("status", "Provides status information of the Minecraft server")]
        public async Task Status()
        {
            await DeferAsync();

            var serverName = _container.Data.Name;

            await ModifyOriginalResponseAsync(msg =>
            {
                msg.Embed = new EmbedBuilder()
                    .WithColor(Color.Blue)
                    .WithTitle(serverName)
                    .WithFields(
                        new EmbedFieldBuilder().WithName("Server Address").WithValue(_container.Data.IPAddress.Fqdn).WithIsInline(false),
                        new EmbedFieldBuilder().WithName("Server State").WithValue(_container.Data.Containers[0].InstanceView.CurrentState.State).WithIsInline(true),
                        new EmbedFieldBuilder().WithName("CPU(s)").WithValue(_container.Data.Containers[0].Resources.Requests.Cpu).WithIsInline(true),
                        new EmbedFieldBuilder().WithName("RAM").WithValue($"{_container.Data.Containers[0].Resources.Requests.MemoryInGB} GB").WithIsInline(true),
                        new EmbedFieldBuilder().WithName("Server Location").WithValue(_container.Data.Location.DisplayName).WithIsInline(true)
                     )
                    .Build();
            });
        }

        [SlashCommand("logs", "Shows the most recent Minecraft server logs")]
        public async Task Logs(int tail = 5)
        {
            await DeferAsync();

            try
            {
                var logResponse = await _container.GetContainerLogsAsync("server", tail, true);
                await ModifyOriginalResponseAsync(msg => msg.Content = $"```\n{logResponse.Value.Content}\n```");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error while getting logs");
                await ModifyOriginalResponseAsync(msg => msg.Content = $"Could not retrieve logs.");
                throw;
            }
        }

        [SlashCommand("start", "Starts the Minecraft server")]
        public async Task Start()
        {
            await DeferAsync();
            try
            {
                await ModifyOriginalResponseAsync(m => m.Embed = new EmbedBuilder()
                    .WithTitle("Server is starting")
                    .WithDescription("Please wait a short moment while we're getting things ready...")
                    .WithColor(Color.Blue)
                    .Build());

                _logger.LogInformation("Server start request sent");
                await _container.StartAsync(Azure.WaitUntil.Completed);

                _logger.LogInformation("Server started");
                await ModifyOriginalResponseAsync(m => m.Embed = new EmbedBuilder()
                    .WithTitle("Server is up and running")
                    .WithColor(Color.Green)
                    .WithFooter($"Join {_container.Data.IPAddress.Fqdn}")
                    .Build());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occured while starting the Minecraft server");
                await ModifyOriginalResponseAsync(m => m.Embed = new EmbedBuilder()
                    .WithTitle("Server start failed")
                    .WithColor(Color.Red)
                    .WithFooter($"The server couldn't be started. Please check the bot logs for more details.")
                    .Build());
                throw;
            }
        }

        [SlashCommand("stop", "Stops the Minecraft server")]
        public async Task Stop()
        {
            _logger.LogInformation("Stopping server");
            await _container.StopAsync();

            _logger.LogInformation("Server stopped");
            await RespondAsync(embed: new EmbedBuilder()
                    .WithTitle("Server stopped")
                    .WithColor(Color.Orange)
                    .Build());
        }
    }
}
