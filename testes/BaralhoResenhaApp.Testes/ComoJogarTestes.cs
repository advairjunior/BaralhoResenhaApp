using System.Net;
using System.Text.RegularExpressions;
using BaralhoResenhaApp.Api.Dominio;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// /como-jogar: o guia para mandar à turma por link. A página e as imagens
/// viajam dentro da DLL, como as cartas.
/// </summary>
public sealed class ComoJogarTestes(WebApplicationFactory<Program> fabrica)
    : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _cliente = fabrica.CreateClient();

    [Theory]
    [InlineData("/como-jogar")]
    [InlineData("/como-jogar/")]
    public async Task PaginaComoJogarAbreComoHtml(string rota)
    {
        var resposta = await _cliente.GetAsync(rota);

        Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
        Assert.Equal("text/html", resposta.Content.Headers.ContentType?.MediaType);
        var html = await resposta.Content.ReadAsStringAsync();
        Assert.Contains("<title>Como jogar", html);
        Assert.Contains("/como-jogar/mao.jpg", html);
    }

    [Fact]
    public async Task ImagensDaPaginaVemDaDll()
    {
        var resposta = await _cliente.GetAsync("/como-jogar/mao.jpg");

        Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
        Assert.Equal("image/jpeg", resposta.Content.Headers.ContentType?.MediaType);
        Assert.True((await resposta.Content.ReadAsByteArrayAsync()).Length > 1000);
    }

    [Theory]
    [InlineData("/como-jogar/nao-existe.jpg")]
    [InlineData("/como-jogar/..%2Fappsettings.json")]
    public async Task OQueNaoEhDaPaginaNaoEhServido(string rota)
    {
        var resposta = await _cliente.GetAsync(rota);

        Assert.Equal(HttpStatusCode.NotFound, resposta.StatusCode);
    }

    [Fact]
    public async Task TodaImagemQueOGuiaMostraExiste()
    {
        var html = await _cliente.GetStringAsync("/como-jogar");
        var imagens = Regex.Matches(html, @"/como-jogar/([\w-]+\.jpg)").Select(m => m.Groups[1].Value).Distinct().ToList();

        Assert.NotEmpty(imagens);
        foreach (var imagem in imagens)
            Assert.True((await _cliente.GetAsync($"/como-jogar/{imagem}")).IsSuccessStatusCode, $"{imagem} não existe");
    }

    [Fact]
    public async Task OGuiaMostraACartaDeCadaJogo()
    {
        var html = await _cliente.GetStringAsync("/como-jogar");

        foreach (var modo in Enum.GetValues<ModoDeJogo>())
            Assert.Contains($"/como-jogar/carta-{modo}.jpg", html);
    }
}
