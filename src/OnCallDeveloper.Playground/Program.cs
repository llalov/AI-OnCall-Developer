using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

var config = new ConfigurationBuilder().AddUserSecrets<Program>().Build();
var apiKey = config["Anthropic:ApiKey"]
    ?? throw new InvalidOperationException("Missing Anthropic:ApiKey in user secrets");

using var http = new HttpClient();
http.DefaultRequestHeaders.Add("x-api-key", apiKey);
http.DefaultRequestHeaders.Add("anthropic-version", "2023-06-01");

var request = new
{
    model = "claude-haiku-5-5",   // cheap and fast; check docs.claude.com for current names
    max_tokens = 10,
    messages = new[]
    {
        new { role = "user", content = "In one sentence: what does an on-call engineer do?" }
    }
};

var response = await http.PostAsJsonAsync("https://api.anthropic.com/v1/messages", request);
var body = await response.Content.ReadAsStringAsync();

if (!response.IsSuccessStatusCode)
{
    Console.WriteLine($"Error {(int)response.StatusCode}: {body}");
    return;
}

using var doc = JsonDocument.Parse(body);
Console.WriteLine(doc.RootElement.GetProperty("content")[0].GetProperty("text").GetString());

var usage = doc.RootElement.GetProperty("usage");
Console.WriteLine($"Tokens in: {usage.GetProperty("input_tokens")}, out: {usage.GetProperty("output_tokens")}");
