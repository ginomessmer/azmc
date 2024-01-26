
/// <summary>
/// Represents the options for the bot.
/// </summary>
public class BotOptions
{
    /// <summary>
    /// Gets or sets the public key.
    /// </summary>
    public string PublicKey { get; set; } = "";

    /// <summary>
    /// Gets or sets the token.
    /// </summary>
    public string Token { get; set; } = "";

#if DEBUG
    /// <summary>
    /// Gets or sets the debug guild ID.
    /// </summary>
    public ulong DebugGuildId { get; set; }
#endif
}
