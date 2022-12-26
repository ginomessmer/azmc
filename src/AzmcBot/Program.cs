using Azure.Identity;
using Discord.Interactions;
using Discord.WebSocket;
using AzmcBot.Configuration;
using Microsoft.Extensions.Options;
using Azure.ResourceManager;
using Azure.Core;
using Azure.ResourceManager.Resources;
using Azure.ResourceManager.ContainerInstance;

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<BotConfiguration>(builder.Configuration.GetSection("Bot"));

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Discord
builder.Services.AddSingleton<DiscordSocketConfig>();
builder.Services.AddSingleton<DiscordSocketClient>();
builder.Services.AddSingleton<InteractionService>(sp => new(sp.GetRequiredService<DiscordSocketClient>()));

// Add Azure
builder.Services
    .AddSingleton(services =>
    {
        var options = services.GetRequiredService<IOptions<BotConfiguration>>().Value;
        return new DefaultAzureCredentialOptions
        {
            TenantId = options.TenantId
        };
    })
    .AddSingleton<TokenCredential, DefaultAzureCredential>(services => new DefaultAzureCredential(services.GetRequiredService<DefaultAzureCredentialOptions>()))
    .AddSingleton<ArmClient>()
    .AddSingleton(services =>
    {
        var options = services.GetRequiredService<IOptions<BotConfiguration>>().Value;
        var client = services.GetRequiredService<ArmClient>();
        return client.GetSubscriptionResource(new ResourceIdentifier($"/subscriptions/{options.SubscriptionId}"));
    })
    .AddSingleton(services =>
    {
        var options = services.GetRequiredService<IOptions<BotConfiguration>>().Value;
        var subscription = services.GetRequiredService<SubscriptionResource>();
        return subscription.GetResourceGroup(options.ResourceGroupName).Value;
    })
    .AddTransient(services =>
    {
        var options = services.GetRequiredService<IOptions<BotConfiguration>>().Value;
        var rg = services.GetRequiredService<ResourceGroupResource>();
        return rg.GetContainerGroup(options.ContainerGroupName).Value;
    });

// Add hosted services
builder.Services.AddHostedService<DiscordBotWorker>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
