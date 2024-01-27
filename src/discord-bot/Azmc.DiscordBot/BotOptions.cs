using System.ComponentModel.DataAnnotations;

namespace Azmc.DiscordBot;

/// <summary>
/// Represents the options for the bot.
/// </summary>
public class BotOptions
{
    /// <summary>
    /// Gets or sets the public key.
    /// </summary>
    [Required]
    public string PublicKey { get; set; } = "";

    /// <summary>
    /// Gets or sets the token.
    /// </summary>
    [Required]
    public string Token { get; set; } = "";

#if DEBUG
    /// <summary>
    /// Gets or sets the debug guild ID.
    /// </summary>
    [Required]
    public ulong DebugGuildId { get; set; }
#endif
}
