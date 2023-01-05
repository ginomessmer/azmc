using Azure.Identity;
using Discord.Interactions;
using Discord.WebSocket;
using AzmcBot.Configuration;
using Microsoft.Extensions.Options;
using Azure.ResourceManager;
using Azure.Core;
using Azure.ResourceManager.Resources;
using Azure.ResourceManager.ContainerInstance;
using AzmcBot.Workers;

var builder = WebApplication.CreateBuilder(args);

AddAzureKeyVault(builder);

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
    .AddScoped(async services =>
    {
        var options = services.GetRequiredService<IOptions<BotConfiguration>>().Value;
        var client = services.GetRequiredService<ArmClient>();

        var containerResourceId = ContainerGroupResource.CreateResourceIdentifier(
                options.SubscriptionId,
                options.ResourceGroupName,
                options.ContainerGroupName);

        var container = client.GetContainerGroupResource(containerResourceId);
        
        return (await container.GetAsync()).Value;
    });

// Add hosted services
builder.Services
    .AddHostedService<DiscordBotWorker>()
    .AddHostedService<UpdateDiscordStatusWorker>();

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

static void AddAzureKeyVault(WebApplicationBuilder builder)
{
    var keyVaultName = builder.Configuration["KeyVaultName"];

    if (builder.Environment.IsProduction() || !string.IsNullOrEmpty(keyVaultName))
        builder.Configuration.AddAzureKeyVault(
            new Uri($"https://{keyVaultName}.vault.azure.net/"),
            new DefaultAzureCredential());
}