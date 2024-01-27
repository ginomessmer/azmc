using System.Net.Mime;
using Azmc.DiscordBot;
using Azure.Core;
using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.ContainerInstance;
using Discord.Interactions;
using Discord.Rest;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateSlimBuilder(args);

// Discord services
builder.Services
    .AddSingleton<DiscordRestConfig>(_ => new() {
        APIOnRestInteractionCreation = true
    })
    .AddSingleton<DiscordRestClient>();

// Interaction services
builder.Services
    .AddSingleton<InteractionServiceConfig>(_ => new()
    {
        AutoServiceScopes = true
    })
    .AddSingleton<InteractionService>();

// Container instance
builder.Services
    .AddSingleton<ArmClient>(_ => new(new DefaultAzureCredential()))
    .AddSingleton<ContainerGroupResource>(services =>
    {
        var client = services.GetRequiredService<ArmClient>();
        var options = services.GetRequiredService<IOptions<AzureOptions>>();
        var resource = client.GetContainerGroupResource(ResourceIdentifier.Parse(options.Value.ContainerGroupResourceId)).Get();
        return resource;
    });

// Configuration
builder.Services.AddOptions<BotOptions>().BindConfiguration("Bot").ValidateDataAnnotations().ValidateOnStart();
builder.Services.AddOptions<AzureOptions>().BindConfiguration("Azure").ValidateDataAnnotations().ValidateOnStart();

builder.Services.AddLogging();

builder.Services.AddHostedService<BotBackgroundService>();

builder.Services.AddHealthChecks();


// App
var app = builder.Build();

app.MapHealthChecks("/health");

app.MapPost("/interactions", async (DiscordRestClient client, InteractionService interactionService,
    IOptions<BotOptions> options, IServiceProvider services, HttpRequest req) =>
    {
        try
        {
            var signature = req.Headers["X-Signature-Ed25519"];
            var timestamp = req.Headers["X-Signature-Timestamp"];

            req.EnableBuffering();
            req.Body.Position = 0;
            var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var interaction = await client.ParseHttpInteractionAsync(
                options.Value.PublicKey, signature, timestamp, body);

            if (interaction is RestPingInteraction ping)
            {
                app.Logger.LogInformation("Ping received");
                var response = ping.AcknowledgePing();
                app.Logger.LogInformation("Ping acknowledged");
                return Results.Content(response, MediaTypeNames.Application.Json, System.Text.Encoding.UTF8, StatusCodes.Status200OK);
            }


            // Stupid hack because it seems that the interaction 
            // response callback won't be awaited when the command is executed
            CancellationTokenSource cts = new();
            cts.CancelAfter(TimeSpan.FromSeconds(3));
            Microsoft.AspNetCore.Http.IResult result = Results.BadRequest("Could not complete command");
            await interactionService.ExecuteCommandAsync(new RestInteractionContext(client, interaction, json =>
            {
                result = Results.Content(json, MediaTypeNames.Application.Json, System.Text.Encoding.UTF8, StatusCodes.Status200OK);
                cts.Cancel();
                return Task.CompletedTask;
            }), services);

            while (!cts.IsCancellationRequested)
            {
                await Task.Delay(100);
            }

            return result;
        }
        catch (BadSignatureException)
        {
            app.Logger.LogWarning("Bad signature");
            return Results.Unauthorized();
        }
        catch (Exception ex)
        {
            app.Logger.LogError(ex, "Error handling interaction");
            throw;
        }
    });

app.Run();
