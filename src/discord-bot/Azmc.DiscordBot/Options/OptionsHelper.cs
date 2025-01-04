namespace Azmc.DiscordBot.Options;

public static class OptionsHelper
{
    public static bool CheckWebMapEnabled(this AzureOptions options)
    {
        return options.WebMapRendererContainerJobResourceId != null;
    }
}
