using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using BaralhoResenhaApp.Api.Dominio;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// O baralho continua de onde parou: o celular de quem cria a sala lembra as
/// cartas que já saíram nas noites anteriores, e elas vão para o fim do monte.
/// </summary>
public sealed class CartasVistasTestes(WebApplicationFactory<Program> fabrica)
    : IClassFixture<WebApplicationFactory<Program>>
{
    private static readonly IReadOnlyList<Carta> Cartas =
    [
        new("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 1"),
        new("en-2", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 2"),
        new("en-3", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 3"),
    ];

    private static (Sala Sala, Jogador Ana) Mesa()
    {
        var sala = new Sala("ABCD", new Baralho(Cartas), new Random(3));
        var ana = sala.Entrar("Ana", false);
        sala.Entrar("Bia", false);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], true));
        return (sala, ana);
    }

    [Fact]
    public void CartasDasNoitesAnterioresFicamParaODepois()
    {
        var (sala, ana) = Mesa();

        sala.Comecar(ana.Token, ["en-1", "en-3", "nao-existe"]);

        Assert.Equal("en-2", sala.Rodada!.Carta.Id);
        Assert.Equal("en-2", sala.Visao(ana.Token).Rodada!.CartaId);
    }

    [Fact]
    public void QuandoJaViuTudoOBaralhoRecomeca()
    {
        var (sala, ana) = Mesa();

        sala.Comecar(ana.Token, ["en-1", "en-2", "en-3"]);
        var vistas = new List<string> { sala.Rodada!.Carta.Id };
        for (var i = 0; i < 2; i++)
        {
            sala.Proxima(ana.Token, sala.Rodada.Numero);
            vistas.Add(sala.Rodada!.Carta.Id);
        }

        Assert.Equal(3, vistas.Distinct().Count());
    }

    [Fact]
    public void CadaCelularDaTurmaContribuiComAsCartasQueJaViu()
    {
        var (sala, ana) = Mesa();
        var bia = sala.Visao(ana.Token).Jogadores.Single(j => j.Nome == "Bia");
        var tokenDaBia = sala.Jogadores.Single(j => j.Id == bia.Id).Token;

        // A Bia jogou outras noites no celular dela; a Ana, que criou a sala, não.
        sala.LembrarVistas(tokenDaBia, ["en-1", "en-2"]);
        sala.Comecar(ana.Token);

        Assert.Equal("en-3", sala.Rodada!.Carta.Id);
    }

    [Fact]
    public void DepoisDeComecarAsVistasNaoMudamMais()
    {
        var (sala, ana) = Mesa();
        sala.Comecar(ana.Token);

        sala.LembrarVistas(ana.Token, ["en-1", "en-2", "en-3"]);

        sala.Proxima(ana.Token, sala.Rodada!.Numero);
        Assert.NotNull(sala.Rodada);
    }

    [Fact]
    public async Task ComecarAceitaAsCartasVistasESemCorpoContinuaFuncionando()
    {
        var cliente = fabrica.CreateClient();
        foreach (var vistas in new[] { new[] { "en-001" }, null })
        {
            var ana = (await (await cliente.PostAsJsonAsync("/api/salas", new { nome = "Ana" }))
                .Content.ReadFromJsonAsync<Entrada>())!;
            await cliente.PostAsJsonAsync($"/api/salas/{ana.Codigo}/jogadores", new { nome = "Bia" });

            var requisicao = new HttpRequestMessage(HttpMethod.Post, $"/api/salas/{ana.Codigo}/comecar");
            requisicao.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ana.Token);
            if (vistas is not null) requisicao.Content = JsonContent.Create(new { vistas });
            var resposta = await cliente.SendAsync(requisicao);

            Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
            var visao = await resposta.Content.ReadFromJsonAsync<JsonElement>();
            Assert.False(string.IsNullOrEmpty(visao.GetProperty("rodada").GetProperty("cartaId").GetString()));
        }
    }

    private sealed record Entrada(string Codigo, string Token);
}
