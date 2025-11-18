
// Modified frontend
using Microsoft.AspNetCore.Mvc;
using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace FrontendApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FrontendController : ControllerBase
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<FrontendController> _logger;

        public FrontendController(IHttpClientFactory httpClientFactory, ILogger<FrontendController> logger)
        {
            _httpClientFactory = httpClientFactory;
            _logger = logger;
        }

        [HttpGet("info")]
        public IActionResult GetInfo()
        {
            var info = new
            {
                Service = "Frontend API",
                Version = "1.0.0",
                Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Unknown",
                Timestamp = DateTime.UtcNow,
                HostName = Environment.MachineName
            };

            return Ok(info);
        }

        [HttpGet("backend-status")]
        public async Task<IActionResult> GetBackendStatus()
        {
            try
            {
                var client = _httpClientFactory.CreateClient("BackendAPI");
                var response = await client.GetAsync("/api/backend/info");

                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    return Ok(new
                    {
                        Status = "Backend is reachable",
                        BackendResponse = content,
                        StatusCode = (int)response.StatusCode
                    });
                }
                else
                {
                    return Ok(new
                    {
                        Status = "Backend returned error",
                        StatusCode = (int)response.StatusCode
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling backend API");
                return Ok(new
                {
                    Status = "Cannot reach backend",
                    Error = ex.Message
                });
            }
        }

        [HttpGet("data")]
        public async Task<IActionResult> GetDataFromBackend()
        {
            try
            {
                var client = _httpClientFactory.CreateClient("BackendAPI");
                var response = await client.GetAsync("/api/backend/data");

                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    return Ok(new
                    {
                        Source = "Frontend API",
                        BackendData = content,
                        RetrievedAt = DateTime.UtcNow
                    });
                }
                else
                {
                    return StatusCode((int)response.StatusCode, "Backend API returned an error");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching data from backend API");
                return StatusCode(500, new { Error = "Failed to fetch data from backend", Details = ex.Message });
            }
        }
    }
}
