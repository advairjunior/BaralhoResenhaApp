using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

public sealed class FotoDoJogadorTestes(WebApplicationFactory<Program> fabrica)
    : IClassFixture<WebApplicationFactory<Program>>
{
    private static readonly byte[] Jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46];
    private readonly HttpClient _cliente = fabrica.CreateClient();

    private sealed record Entrada(string Codigo, string Token);

    private async Task<HttpResponseMessage> EnviarFoto(string codigo, string token, byte[] foto)
    {
        var requisicao = new HttpRequestMessage(HttpMethod.Put, $"/api/salas/{codigo}/jogadores/eu/foto")
        {
            Content = new ByteArrayContent(foto)
        };
        requisicao.Content.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        requisicao.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await _cliente.SendAsync(requisicao);
    }

    [Fact]
    public void AceitaJpegPngEWebp()
    {
        Assert.Equal("image/jpeg", FotoDoJogador.Criar(Jpeg).TipoDeConteudo);
        Assert.Equal("image/png", FotoDoJogador.Criar([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]).TipoDeConteudo);
        Assert.Equal("image/webp", FotoDoJogador.Criar("RIFF\0\0\0\0WEBPVP8 "u8.ToArray()).TipoDeConteudo);
    }

    [Fact]
    public void RecusaArquivoQueNaoEhImagemOuGrandeDemais()
    {
        Assert.Throws<AcaoNaoPermitidaException>(() => FotoDoJogador.Criar("<html>"u8.ToArray()));
        Assert.Throws<AcaoNaoPermitidaException>(() => FotoDoJogador.Criar([]));
        var enorme = new byte[FotoDoJogador.TamanhoMaximo + 1];
        Jpeg.CopyTo(enorme, 0);
        Assert.Throws<AcaoNaoPermitidaException>(() => FotoDoJogador.Criar(enorme));
    }

    [Fact]
    public void FotoNovaGanhaOutroEndereco()
    {
        var sala = new Sala("ABCD", new Baralho([]));
        var ana = sala.Entrar("Ana", false);

        sala.DefinirFoto(ana.Token, Jpeg);
        var primeira = sala.Visao(ana.Token).Jogadores.Single().Foto;
        sala.DefinirFoto(ana.Token, Jpeg);
        var segunda = sala.Visao(ana.Token).Jogadores.Single().Foto;

        Assert.StartsWith("/api/salas/ABCD/fotos/", primeira);
        Assert.NotEqual(primeira, segunda);
    }

    [Fact]
    public async Task SelfieEnviadaApareceParaATurmaEPodeSerBaixada()
    {
        var criacao = await _cliente.PostAsJsonAsync("/api/salas", new { nome = "Ana" });
        var ana = (await criacao.Content.ReadFromJsonAsync<Entrada>())!;

        var envio = await EnviarFoto(ana.Codigo, ana.Token, Jpeg);
        Assert.Equal(HttpStatusCode.OK, envio.StatusCode);
        var visao = await envio.Content.ReadFromJsonAsync<JsonElement>();
        var caminho = visao.GetProperty("jogadores")[0].GetProperty("foto").GetString()!;

        var foto = await _cliente.GetAsync(caminho);
        Assert.Equal(HttpStatusCode.OK, foto.StatusCode);
        Assert.Equal("image/jpeg", foto.Content.Headers.ContentType!.MediaType);
        Assert.Equal(Jpeg, await foto.Content.ReadAsByteArrayAsync());
        Assert.Contains("immutable", foto.Headers.CacheControl!.ToString());
    }

    [Fact]
    public async Task SemTokenNaoEnviaFotoEIdDesconhecidoDa404()
    {
        var criacao = await _cliente.PostAsJsonAsync("/api/salas", new { nome = "Ana" });
        var ana = (await criacao.Content.ReadFromJsonAsync<Entrada>())!;

        Assert.Equal(HttpStatusCode.Unauthorized, (await EnviarFoto(ana.Codigo, "token-falso", Jpeg)).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await _cliente.GetAsync($"/api/salas/{ana.Codigo}/fotos/naoexiste")).StatusCode);
    }

    [Fact]
    public async Task ArquivoQueNaoEhFotoResponde409ComMensagem()
    {
        var criacao = await _cliente.PostAsJsonAsync("/api/salas", new { nome = "Ana" });
        var ana = (await criacao.Content.ReadFromJsonAsync<Entrada>())!;

        var resposta = await EnviarFoto(ana.Codigo, ana.Token, "texto qualquer"u8.ToArray());

        Assert.Equal(HttpStatusCode.Conflict, resposta.StatusCode);
        var corpo = await resposta.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Envie a foto em JPEG, PNG ou WebP.", corpo.GetProperty("mensagem").GetString());
    }
}
