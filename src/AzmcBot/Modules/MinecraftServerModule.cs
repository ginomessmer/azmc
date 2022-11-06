using Discord.Interactions;

namespace AzmcBot.Modules
{
    public class MinecraftServerModule : InteractionModuleBase<SocketInteractionContext>
    {
        [SlashCommand("start", "Starts the Minecraft server")]
        public async Task StartAsync()
        {
            await RespondAsync("Starting the Minecraft server...");
        }
    }
}
