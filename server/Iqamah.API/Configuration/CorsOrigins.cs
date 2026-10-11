namespace Iqamah.API.Configuration;

public static class CorsOrigins
{
    public static string[] Parse(string? configured, bool development)
    {
        if (string.IsNullOrWhiteSpace(configured))
        {
            return development
                ? ["http://localhost:5173", "http://127.0.0.1:5173"]
                : [];
        }

        return configured.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(origin =>
            {
                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri)
                    || (uri.Scheme != "http" && uri.Scheme != "https")
                    || !string.IsNullOrEmpty(uri.UserInfo)
                    || uri.AbsolutePath != "/"
                    || !string.IsNullOrEmpty(uri.Query)
                    || !string.IsNullOrEmpty(uri.Fragment))
                {
                    throw new InvalidOperationException("CLIENT_URL must contain comma-separated HTTP(S) origins without paths, credentials, queries or fragments.");
                }

                return uri.GetLeftPart(UriPartial.Authority);
            })
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }
}
