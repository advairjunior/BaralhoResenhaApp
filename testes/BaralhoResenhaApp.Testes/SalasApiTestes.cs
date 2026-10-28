using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BaralhoResenhaApp.Testes;

public sealed class SalasApiTestes(WebApplicationFactory<Program> fabrica)
    : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _cliente = fabrica.CreateClient();

    private sealed record Entrada(string Codigo, string Token);

    private async Task<Entrada> CriarSala(string nome)
    {
        var resposta = await _cliente.PostAsJsonAsync("/api/salas", new { nome });
        Assert.Equal(HttpStatusCode.Created, resposta.StatusCode);
        return (await resposta.Content.ReadFromJsonAsync<Entrada>())!;
    }

    private async Task<Entrada> Entrar(string codigo, string nome)
    {
        var resposta = await _cliente.PostAsJsonAsync($"/api/salas/{codigo}/jogadores", new { nome });
        Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
        return (await resposta.Content.ReadFromJsonAsync<Entrada>())!;
    }

    private async Task<HttpResponseMessage> Enviar(
        HttpMethod metodo, string rota, string token, object? corpo = null)
    {
        var requisicao = new HttpRequestMessage(metodo, rota);
        requisicao.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (corpo is not null) requisicao.Content = JsonContent.Create(corpo);
        return await _cliente.SendAsync(requisicao);
    }

    private async Task<JsonElement> Visao(string codigo, string token)
    {
        var resposta = await Enviar(HttpMethod.Get, $"/api/salas/{codigo}", token);
        Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
        return await resposta.Content.ReadFromJsonAsync<JsonElement>();
    }

    [Fact]
    public async Task PesoPorJogoVaiEVoltaNaConfiguracao()
    {
        var ana = await CriarSala("Ana");

        await Enviar(HttpMethod.Put, $"/api/salas/{ana.Codigo}/configuracao", ana.Token,
            new { nivel = "Leve", modos = new[] { "EuNunca", "BebaSe", "Tribunal" }, zonaSegura = true,
                muito = new[] { "Tribunal" }, pouco = new[] { "BebaSe" } });

        var configuracao = (await Visao(ana.Codigo, ana.Token)).GetProperty("configuracao");
        Assert.Equal(["Tribunal"], configuracao.GetProperty("muito").EnumerateArray().Select(m => m.GetString()));
        Assert.Equal(["BebaSe"], configuracao.GetProperty("pouco").EnumerateArray().Select(m => m.GetString()));
    }

    [Fact]
    public async Task SoAPessoaDaVezEscreveAsDuasVerdades()
    {
        var ana = await CriarSala("Ana");
        var turma = new[] { ana, await Entrar(ana.Codigo, "Bia"), await Entrar(ana.Codigo, "Caio") };
        var sala = $"/api/salas/{ana.Codigo}";
        await Enviar(HttpMethod.Put, $"{sala}/configuracao", ana.Token,
            new { nivel = "Leve", modos = new[] { "DuasVerdades" }, zonaSegura = true });
        await Enviar(HttpMethod.Post, $"{sala}/comecar", ana.Token);
        var rodada = (await Visao(ana.Codigo, ana.Token)).GetProperty("rodada");
        var alvo = rodada.GetProperty("alvo").GetString();
        var daVez = turma.Single(j => Visao(ana.Codigo, j.Token).Result.GetProperty("euId").GetString() == alvo);
        var outro = turma.First(j => j != daVez);
        var corpo = new { rodada = rodada.GetProperty("numero").GetInt32(), frases = new[] { "Um", "Dois", "Três" }, mentira = 2 };

        Assert.Equal(HttpStatusCode.Conflict, (await Enviar(HttpMethod.Post, $"{sala}/duas-verdades", outro.Token, corpo)).StatusCode);
        var resposta = await Enviar(HttpMethod.Post, $"{sala}/duas-verdades", daVez.Token, corpo);

        Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
        var visaoDoOutro = (await Visao(ana.Codigo, outro.Token)).GetProperty("rodada");
        Assert.Equal(["Um", "Dois", "Três"], visaoDoOutro.GetProperty("afirmacoes").EnumerateArray().Select(f => f.GetString()));
        Assert.Equal(JsonValueKind.Null, visaoDoOutro.GetProperty("minhaMentira").ValueKind);
    }

    [Fact]
    public async Task CriarEntrarEJogarUmaRodadaDeEuNunca()
    {
        var ana = await CriarSala("Ana");
        var bia = await Entrar(ana.Codigo, "Bia");
        Assert.Matches("^[A-Z]{4}$", ana.Codigo);

        var configuracao = await Enviar(HttpMethod.Put, $"/api/salas/{ana.Codigo}/configuracao", ana.Token,
            new { nivel = "Leve", modos = new[] { "EuNunca" }, zonaSegura = true });
        Assert.Equal(HttpStatusCode.OK, configuracao.StatusCode);
        var comecar = await Enviar(HttpMethod.Post, $"/api/salas/{ana.Codigo}/comecar", ana.Token);
        Assert.Equal(HttpStatusCode.OK, comecar.StatusCode);

        var visao = await Visao(ana.Codigo, bia.Token);
        Assert.Equal("Carta", visao.GetProperty("fase").GetString());
        var rodada = visao.GetProperty("rodada");
        Assert.Equal("EuNunca", rodada.GetProperty("modo").GetString());
        var numero = rodada.GetProperty("numero").GetInt32();

        await Enviar(HttpMethod.Post, $"/api/salas/{ana.Codigo}/respostas", ana.Token,
            new { rodada = numero, resposta = "ja" });
        var ultima = await Enviar(HttpMethod.Post, $"/api/salas/{ana.Codigo}/respostas", bia.Token,
            new { rodada = numero, resposta = "nunca" });
        var depois = await ultima.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal("Revelada", depois.GetProperty("fase").GetString());
        var anaNaLista = depois.GetProperty("jogadores").EnumerateArray()
            .Single(j => j.GetProperty("nome").GetString() == "Ana");
        Assert.Equal(1, anaNaLista.GetProperty("pontos").GetInt32());
    }

    [Fact]
    public async Task CodigoInexistenteResponde404ComMensagem()
    {
        var resposta = await _cliente.PostAsJsonAsync("/api/salas/ZZZZ/jogadores", new { nome = "Ana" });

        Assert.Equal(HttpStatusCode.NotFound, resposta.StatusCode);
        var corpo = await resposta.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Sala não encontrada.", corpo.GetProperty("mensagem").GetString());
    }

    [Fact]
    public async Task TokenDeOutraSalaNaoEnxergaASala()
    {
        var ana = await CriarSala("Ana");
        var outra = await CriarSala("Outra");

        var resposta = await Enviar(HttpMethod.Get, $"/api/salas/{ana.Codigo}", outra.Token);

        Assert.Equal(HttpStatusCode.Unauthorized, resposta.StatusCode);
    }

    [Fact]
    public async Task ConvidadoNaoPodeComecar()
    {
        var ana = await CriarSala("Ana");
        var bia = await Entrar(ana.Codigo, "Bia");

        var resposta = await Enviar(HttpMethod.Post, $"/api/salas/{ana.Codigo}/comecar", bia.Token);

        Assert.Equal(HttpStatusCode.Conflict, resposta.StatusCode);
    }

    [Fact]
    public async Task QuemEstaNoComandoPassaOComandoParaOutro()
    {
        var ana = await CriarSala("Ana");
        var bia = await Entrar(ana.Codigo, "Bia");
        var biaId = (await Visao(ana.Codigo, bia.Token)).GetProperty("euId").GetString();

        var resposta = await Enviar(HttpMethod.Post, $"/api/salas/{ana.Codigo}/comando", ana.Token,
            new { jogadorId = biaId });

        Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
        Assert.False((await resposta.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("souAnfitriao").GetBoolean());
        Assert.True((await Visao(ana.Codigo, bia.Token)).GetProperty("souAnfitriao").GetBoolean());
    }

    [Fact]
    public async Task ReacaoNaCartaApareceParaATurma()
    {
        var ana = await CriarSala("Ana");
        var bia = await Entrar(ana.Codigo, "Bia");
        await Enviar(HttpMethod.Post, $"/api/salas/{ana.Codigo}/comecar", ana.Token);
        var numero = (await Visao(ana.Codigo, bia.Token)).GetProperty("rodada").GetProperty("numero").GetInt32();

        var resposta = await Enviar(HttpMethod.Post, $"/api/salas/{ana.Codigo}/reacao", bia.Token,
            new { rodada = numero, emoji = "😂" });

        Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
        var rodada = (await Visao(ana.Codigo, ana.Token)).GetProperty("rodada");
        Assert.Equal(1, rodada.GetProperty("reacoes").GetProperty("😂").GetInt32());
    }

    [Fact]
    public async Task UltimoASairFechaASala()
    {
        var ana = await CriarSala("Ana");

        var saida = await Enviar(HttpMethod.Delete, $"/api/salas/{ana.Codigo}/jogadores/eu", ana.Token);
        Assert.Equal(HttpStatusCode.NoContent, saida.StatusCode);

        var entrada = await _cliente.PostAsJsonAsync($"/api/salas/{ana.Codigo}/jogadores", new { nome = "Bia" });
        Assert.Equal(HttpStatusCode.NotFound, entrada.StatusCode);
    }

    [Fact]
    public async Task CasalJogaJulgaRegistraOMomentoEANoiteTerminaComPremios()
    {
        var ana = await CriarSala("Ana");
        var beto = await Entrar(ana.Codigo, "Beto");
        var sala = $"/api/salas/{ana.Codigo}";
        var betoId = (await Visao(ana.Codigo, beto.Token)).GetProperty("euId").GetString();

        Assert.Equal(HttpStatusCode.OK,
            (await Enviar(HttpMethod.Put, $"{sala}/jogadores/eu/par", ana.Token, new { parId = betoId })).StatusCode);
        await Enviar(HttpMethod.Put, $"{sala}/configuracao", ana.Token,
            new { nivel = "Leve", modos = new[] { "CasaisEmJogo" }, zonaSegura = true });
        await Enviar(HttpMethod.Post, $"{sala}/comecar", ana.Token);

        var rodada = (await Visao(ana.Codigo, ana.Token)).GetProperty("rodada");
        var numero = rodada.GetProperty("numero").GetInt32();
        var alvoEhBeto = rodada.GetProperty("alvo").GetString() == betoId;
        var (alvo, palpiteiro) = alvoEhBeto ? (beto, ana) : (ana, beto);
        await Enviar(HttpMethod.Post, $"{sala}/respostas", alvo.Token, new { rodada = numero, resposta = "Jiló" });
        await Enviar(HttpMethod.Post, $"{sala}/respostas", palpiteiro.Token, new { rodada = numero, resposta = "Jiló" });
        var julgado = await Enviar(HttpMethod.Post, $"{sala}/julgar", alvo.Token, new { rodada = numero, acertou = true });
        Assert.True((await julgado.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("rodada").GetProperty("acertou").GetBoolean());

        var foto = new HttpRequestMessage(HttpMethod.Put, $"{sala}/momentos?rodada={numero}")
        {
            Content = new ByteArrayContent([0xFF, 0xD8, 0xFF, 0xE0])
        };
        foto.Headers.Authorization = new AuthenticationHeaderValue("Bearer", palpiteiro.Token);
        Assert.Equal(HttpStatusCode.OK, (await _cliente.SendAsync(foto)).StatusCode);

        var fim = await Enviar(HttpMethod.Post, $"{sala}/encerrar", ana.Token);
        var visao = await fim.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Fim", visao.GetProperty("fase").GetString());
        Assert.Equal("Casal em sintonia", visao.GetProperty("premios")[0].GetProperty("titulo").GetString());
        Assert.Equal(1, visao.GetProperty("momentos").GetArrayLength());
    }

    [Fact]
    public async Task SaudeRespondeOk()
    {
        var resposta = await _cliente.GetFromJsonAsync<JsonElement>("/api/saude");

        Assert.Equal("ok", resposta.GetProperty("status").GetString());
    }

    [Fact]
    public async Task AVisaoMostraQuemEstaConectado()
    {
        var ana = await CriarSala("Ana");
        await Entrar(ana.Codigo, "Bia");

        var jogadores = (await Visao(ana.Codigo, ana.Token)).GetProperty("jogadores").EnumerateArray();

        Assert.All(jogadores, j => Assert.True(j.GetProperty("conectado").GetBoolean()));
    }

    [Fact]
    public async Task SoQuemCriouASalaTiraAlguemESoQuemCaiu()
    {
        var ana = await CriarSala("Ana");
        var bia = await Entrar(ana.Codigo, "Bia");
        var caio = await Entrar(ana.Codigo, "Caio");
        var idDoCaio = (await Visao(ana.Codigo, caio.Token)).GetProperty("euId").GetString();

        var pelaBia = await Enviar(HttpMethod.Delete, $"/api/salas/{ana.Codigo}/jogadores/{idDoCaio}", bia.Token);
        Assert.Equal(HttpStatusCode.Conflict, pelaBia.StatusCode);

        var pelaAna = await Enviar(HttpMethod.Delete, $"/api/salas/{ana.Codigo}/jogadores/{idDoCaio}", ana.Token);
        Assert.Equal(HttpStatusCode.Conflict, pelaAna.StatusCode);
        Assert.Contains("ainda está conectado", await pelaAna.Content.ReadAsStringAsync());

        var semToken = await _cliente.DeleteAsync($"/api/salas/{ana.Codigo}/jogadores/{idDoCaio}");
        Assert.Equal(HttpStatusCode.Unauthorized, semToken.StatusCode);
    }
}
