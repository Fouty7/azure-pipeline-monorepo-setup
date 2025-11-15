using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;

namespace BackendApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BackendController : ControllerBase
    {
        private readonly ILogger<BackendController> _logger;

        public BackendController(ILogger<BackendController> logger)
        {
            _logger = logger;
        }

        [HttpGet("info")]
        public IActionResult GetInfo()
        {
            var info = new
            {
                Service = "Backend API",
                Version = "1.0.0",
                Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Unknown",
                Timestamp = DateTime.UtcNow,
                HostName = Environment.MachineName
            };

            _logger.LogInformation("Info endpoint called from {HostName}", Environment.MachineName);
            return Ok(info);
        }

        [HttpGet("data")]
        public IActionResult GetData()
        {
            var data = new
            {
                Items = new List<object>
                {
                    new { Id = 1, Name = "Item 1", Description = "First sample item", CreatedAt = DateTime.UtcNow.AddDays(-5) },
                    new { Id = 2, Name = "Item 2", Description = "Second sample item", CreatedAt = DateTime.UtcNow.AddDays(-3) },
                    new { Id = 3, Name = "Item 3", Description = "Third sample item", CreatedAt = DateTime.UtcNow.AddDays(-1) }
                },
                TotalCount = 3,
                GeneratedAt = DateTime.UtcNow,
                Source = "Backend API Database"
            };

            _logger.LogInformation("Data endpoint called, returning {Count} items", data.TotalCount);
            return Ok(data);
        }

        [HttpPost("process")]
        public IActionResult ProcessData([FromBody] ProcessRequest request)
        {
            if (request == null || string.IsNullOrEmpty(request.Data))
            {
                return BadRequest(new { Error = "Invalid request data" });
            }

            _logger.LogInformation("Processing data: {Data}", request.Data);

            var result = new
            {
                OriginalData = request.Data,
                ProcessedData = request.Data.ToUpper(),
                ProcessedAt = DateTime.UtcNow,
                ProcessingTime = "5ms",
                Status = "Success"
            };

            return Ok(result);
        }

        [HttpGet("health/detailed")]
        public IActionResult GetDetailedHealth()
        {
            var health = new
            {
                Status = "Healthy",
                Service = "Backend API",
                Uptime = TimeSpan.FromMilliseconds(Environment.TickCount64).ToString(@"dd\.hh\:mm\:ss"),
                Checks = new Dictionary<string, string>
                {
                    { "Database", "Connected" },
                    { "Cache", "Running" },
                    { "ExternalAPI", "Reachable" }
                },
                Timestamp = DateTime.UtcNow
            };

            return Ok(health);
        }
    }

    public class ProcessRequest
    {
        public string Data { get; set; } = string.Empty;
    }
}
