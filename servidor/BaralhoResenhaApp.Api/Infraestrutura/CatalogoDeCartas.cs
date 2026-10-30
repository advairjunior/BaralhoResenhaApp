using System.Text.Json;
using System.Text.Json.Serialization;
using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Api.Infraestrutura;

public static class CatalogoDeCartas
{
    private static readonly JsonSerializerOptions Opcoes = new()
    {
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter() }
    };

    public static Baralho Carregar()
    {
        using var arquivo = typeof(CatalogoDeCartas).Assembly.GetManifestResourceStream("cartas.json")
            ?? throw new InvalidOperationException("O baralho cartas.json não foi incluído na compilação.");
        using var iscas = typeof(CatalogoDeCartas).Assembly.GetManifestResourceStream("iscas.json")
            ?? throw new InvalidOperationException("As iscas iscas.json não foram incluídas na compilação.");
        using var prendas = typeof(CatalogoDeCartas).Assembly.GetManifestResourceStream("prendas.json")
            ?? throw new InvalidOperationException("As prendas prendas.json não foram incluídas na compilação.");
        return new Baralho(Ler(arquivo), JsonSerializer.Deserialize<Iscas>(iscas, Opcoes),
            JsonSerializer.Deserialize<Prendas>(prendas, Opcoes));
    }

    internal static IReadOnlyList<Carta> Ler(Stream arquivo)
    {
        var cartas = JsonSerializer.Deserialize<List<Carta>>(arquivo, Opcoes) ?? [];
        var repetidas = cartas.GroupBy(c => c.Id).Where(g => g.Count() > 1).Select(g => g.Key).ToList();
        if (repetidas.Count > 0)
            throw new InvalidOperationException($"Cartas com id repetido: {string.Join(", ", repetidas)}.");
        return cartas;
    }
}
