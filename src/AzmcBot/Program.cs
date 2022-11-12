using Azure.Identity;
using Discord.Interactions;
using Discord.WebSocket;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Rest;
using AzmcBot.Options;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.Local.json");
builder.Services.Configure<BotOptions>(builder.Configuration.GetSection("Bot"));

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
builder.Services.AddTransient(_ =>
{
    var credential = new DefaultAzureCredential();
    var token = credential.GetToken(new Azure.Core.TokenRequestContext(new[] { "https://management.azure.com/.default" })).Token;
    var tokenCredential = new TokenCredentials(token);
    var azureCredentials = new AzureCredentials(tokenCredential, tokenCredential, null, AzureEnvironment.AzureGlobalCloud);
    return Microsoft.Azure.Management.Fluent.Azure.Configure().Authenticate(azureCredentials).WithDefaultSubscription();
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
