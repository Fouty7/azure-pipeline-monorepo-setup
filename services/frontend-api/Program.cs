// New test happening hope this builds the pipeline
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add HttpClient for backend communication
builder.Services.AddHttpClient("BackendAPI", client =>
{
    var backendUrl = Environment.GetEnvironmentVariable("BACKEND_API_URL") ?? "http://backend-api-svc";
    client.BaseAddress = new Uri(backendUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Add health checks
builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment() || app.Environment.EnvironmentName == "Dev")
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();

app.MapControllers();

// Health check endpoint
app.MapHealthChecks("/health");

// Simple health endpoint
app.MapGet("/health", () => Results.Ok("Healthy"));

app.Run();

