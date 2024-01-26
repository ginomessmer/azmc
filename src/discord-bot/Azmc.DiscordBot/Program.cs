using System.Text.Json.Serialization;
using Discord.Interactions;
using Discord.Rest;

var builder = WebApplication.CreateSlimBuilder(args);

// Discord services
builder.Services
    .AddSingleton<DiscordRestConfig>(_ => new() {
        APIOnRestInteractionCreation = true
    })
    .AddSingleton<DiscordRestClient>();

// Interaction services
builder.Services
    .AddSingleton<InteractionServiceConfig>()
    .AddSingleton<InteractionService>();

// Configuration
builder.Services.Configure<BotOptions>(builder.Configuration.GetSection("Bot"));

builder.Services.AddLogging();

builder.Services.AddHostedService<BotBackgroundService>();

var app = builder.Build();

app.Run();
