using AzmcBot.Options;
using Azure.Identity;
using Discord.Interactions;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;
using Microsoft.Extensions.Options;
using Microsoft.Rest;
using Microsoft.Rest.Azure;
using Newtonsoft.Json.Linq;

namespace AzmcBot.Modules
{
    public class MinecraftServerModule : InteractionModuleBase<SocketInteractionContext>
    {
        private readonly IAzure _azure;
        private readonly BotOptions _options;

        public MinecraftServerModule(IAzure azure, IOptions<BotOptions> options)
	    {
            _azure = azure;
            _options = options.Value;
	    }

        [SlashCommand("start", "Starts the Minecraft server")]
        public async Task StartAsync()
        {
            await _azure.ContainerGroups.StartAsync(_options.ResourceGroupName, _options.ContainerGroupName);
            await RespondAsync("The Minecraft server is now up and running!");
        }

        [SlashCommand("stop", "Stops the Minecraft server")]
        public async Task StopAsync()
        {
            var container = _azure.ContainerGroups.GetByResourceGroup(_options.ResourceGroupName, _options.ContainerGroupName);
            await container.StopAsync();
            await RespondAsync("The Minecraft server has stopped");
        }
    }
}
