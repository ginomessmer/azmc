using System.ComponentModel.DataAnnotations;

namespace Azmc.DiscordBot;

/// <summary>
/// Represents the options for the bot.
/// </summary>
public class AzureOptions
{
    /// <summary>
    /// Gets or sets the resource ID of the Minecraft server container group.
    /// </summary>
    [Required]
    public string ServerContainerGroupResourceId { get; set; }

    /// <summary>
    /// Gets or sets the resource ID of the renderer container app job.
    public string RendererContainerAppJobResourceId { get; set; }
}