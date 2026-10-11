using Iqamah.API.Configuration;

namespace Iqamah.Tests.Unit.Configuration;

public sealed class CorsOriginsTests
{
    [Fact]
    public void ProductionDoesNotAllowCrossOriginRequestsByDefault()
    {
        Assert.Empty(CorsOrigins.Parse(null, false));
    }

    [Fact]
    public void DevelopmentOnlyUsesExplicitLocalOrigins()
    {
        Assert.Equal(["http://localhost:5173", "http://127.0.0.1:5173"], CorsOrigins.Parse(null, true));
    }

    [Fact]
    public void ConfiguredOriginsPreserveSchemeAndPortWithoutGrantingHostWildcards()
    {
        Assert.Equal(["https://example.com:8443", "http://localhost:5175"],
            CorsOrigins.Parse("https://example.com:8443/, http://localhost:5175", false));
    }

    [Theory]
    [InlineData("https://example.com/path")]
    [InlineData("https://user:password@example.com")]
    [InlineData("https://example.com?query=true")]
    [InlineData("https://example.com#fragment")]
    [InlineData("file:///index.html")]
    [InlineData("*")]
    public void InvalidConfigurationIsRejected(string configured)
    {
        Assert.Throws<InvalidOperationException>(() => CorsOrigins.Parse(configured, false));
    }
}
